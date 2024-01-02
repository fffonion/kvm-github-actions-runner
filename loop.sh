#!/bin/bash -e

function echoerr() {
    printf '%s %s\n' "ERROR" "$@" 1>&2;
}

function checkdrain() {
	if [[ -e /tmp/self-hosted-kvm-draining ]]; then
		echo "Draining, not starting new VMs"
		sleep 30
		exit 0
	fi
}

dd_host="10.1.0.1"

function send_metrics() {
	metrics="github.actions.$1:${2:-1}|${3:-c}|#runner_group:${RUNNERGROUP}"
	if [[ ! -z "$4" ]]; then metrics="$metrics,$4"; fi
	echo "Send metrics $metrics to $dd_host"
	echo -n "$metrics" > /dev/udp/$dd_host/8125
}

source /root/self-hosted-kvm.env && echo "Reloaded env vars" || true
export

if [[ -n $REG_TOKEN_LAMBDA_URL && -n $REG_TOKEN_LAMBDA_APIKEY ]]; then
	echo "Using lambda to get reg token"
elif [[ -n $GITHUB_TOKEN ]]; then
	echo "Using PAT to get reg token"
else
	echoerr '$GITHUB_TOKEN, or $REG_TOKEN_LAMBDA_URL and $REG_TOKEN_LAMBDA_APIKEY is required'
	exit 1
fi

if [[ -z $NAME ]]; then
	echoerr '$NAME is required'
	exit 1
fi

urlvar=""
if [[ ! -z $REPO ]]; then
	urlvar=https://github.com/$REPO
else
	urlvar=https://github.com/$ORG
fi
namevar="$(hostname)-$NAME"


mkdir -p /root/vms
workdir=/root/vms/self-hosted-kvm-tf-$NAME
statedir=/root/vms/self-hosted-kvm-tf-$NAME.state
mkdir -p $statedir
if [[ -e $workdir/terraform.tfstate ]]; then
	cp $workdir/terraform.tfstate* $statedir
fi

reload_file=/tmp/self-hosted-kvm@${namevar}.reload

tf_args="-var url=$urlvar -var docker_user=$DOCKER_USER -var docker_pass=$DOCKER_PASS -var name=$namevar -var labels=$LABELS -var runnergroup=$RUNNERGROUP"

if [[ $(arch) == "aarch64" ]]; then
	tf_args="$tf_args -var arm64=true"
fi

if [[ ! -z $CPU ]]; then
	tf_args="$tf_args -var cpu=$CPU"
fi

if [[ ! -z $MEMORY ]]; then
	tf_args="$tf_args -var memory=$MEMORY"
fi

function do_cleanup() {
       set -x
       if [[ $(arch) == "aarch64" ]]; then
           undefine_args="--nvram"
       fi

       virsh -c qemu:///system destroy ${namevar}-runner
       virsh -c qemu:///system undefine $undefine_args ${namevar}-runner

       virsh vol-delete ${namevar}-commoninit.iso kong
       virsh vol-delete ${namevar}-master.iso kong

       terraform destroy -lock-timeout=30s -auto-approve $tf_args -var token=x
       set +x
}

if [[ "$1" == "stop" ]]; then
	pushd $workdir
	echo "Stopping the VM..."
        set +e
	do_cleanup
	exit 0
fi

rm $workdir/*.* || true
mkdir -p $workdir
cp -r $(dirname $(readlink -f $0))/* $workdir/
pushd $workdir

rm terraform.tfstate* -f
if [[ -e $statedir/terraform.tfstate ]]; then
	cp $statedir/terraform.tfstate* $workdir/
fi

terraform init -upgrade

if [[ "$1" == "reload" ]]; then
        touch $reload_file
	exit 0
fi

checkdrain

if [[ ! -z $ORG ]]; then
	url=https://api.github.com/orgs/${ORG}/actions/runners/registration-token
elif [[ ! -z $REPO ]]; then
	url=https://api.github.com/repos/${REPO}/actions/runners/registration-token
else
	echoerr 'Neither $ORG nor $REPO is defined'
	exit 1
fi

# remove the -e flag, in case we hit a bug, we don't want to just kill the vm
set +e

while true; do
	token_start=$(date +%s)
	token_expire=$((token_start + 1700))
	token_method=""
	if [[ -n "$REG_TOKEN_LAMBDA_URL" && -n "$REG_TOKEN_LAMBDA_APIKEY" ]]; then
		reg_token_ret=$(curl \
		  -s \
		  $REG_TOKEN_LAMBDA_URL \
		  -H "apikey: $REG_TOKEN_LAMBDA_APIKEY"
		)

		reg_token=$(echo "$reg_token_ret" | jq -r .join_token)
		token_method="lambda"

	elif [[ -n "$GITHUB_TOKEN" ]]; then
		reg_token_ret=$(curl \
		  -s \
		  -X POST \
		  -H "Accept: application/vnd.github+json" \
		  -H "Authorization: Bearer $GITHUB_TOKEN"\
		  -H "X-GitHub-Api-Version: 2022-11-28" \
		  $url)

		reg_token=$(echo "$reg_token_ret" | jq -r .token)
		token_method="PAT"

	else
		echoerr "Unable to use either lambda or PAT to get token?"
		exit 1
	fi


	if [[ -z $reg_token || $reg_token == "null" ]]; then
		echoerr "Unable to get registration token using $token_method, error was $reg_token_ret"
                send_metrics runners.anomaly "1" "c" "#runner_name:${namevar},#type:get_token_failed" 
		exit 1
	fi

	echo "Reg token is obtained using $token_method: $reg_token"

        watch_dog_check=0
        need_respawn=0
	while [[ $(date +%s) -lt $token_expire ]]; do
                # check reload flag
                if [[ -e $reload_file ]]; then
                    rm -f $reload_file
                    # respawn
                    echo "Reloading loop.sh"
                    exec $0
                fi


                # check terraform state
		if [[ ! -z $(terraform state list) ]]; then
			plan=$(timeout 10 terraform plan $tf_args -var token=$reg_token -detailed-exitcode)
			# we only re-apply when instance exists/job finishes
			# also ignore timeouts
			# mark as respawn if 1) we change from stopped to running, or 2) first time
			if [[ $? -ne 0 && (
					! -z $(echo "$plan" | grep "running" | grep "false") ||
					! -z $(echo "$plan" | grep "libvirt_domain.test" |grep "will be created") ||
					! -z $(echo "$plan" | grep "Error: error while retrieving remote ISO")
				) ]]; then

				need_respawn=1
			fi
                else # not created
                    need_respawn=1
                fi

                # check health
                if [[ $(arch) == "x86_64" ]]; then
                    # note a \x0d exist before the number, use grep to strip it
                    irq=$(virsh qemu-monitor-command ${namevar}-runner --hmp info irq|cut -d: -f2|sort -nr|head -n1|grep -oP "\d+")
                    if [[ ! -z $irq && $irq -lt 20 ]]; then
                        let watch_dog_check=watch_dog_check+1
                        if [[ $watch_dog_check -gt 120 ]]; then
                            echo "IRQ is less than 10 for 10 minutes, recreating VM"
                            echo "Not recreating for testing"
                            send_metrics runners.anomaly "1" "c" "#runner_name:${namevar},#type:vm_force_recreate" 
                            do_cleanup
                            # reset counter
                            watch_dog_check=0
                            need_respawn=1
                        fi
                    else
                        watch_dog_check=0
                    fi
                fi

                if [[ $need_respawn -eq 1 ]]; then
		    # check drain flag
		    checkdrain

                    echo "Reprovisioning the VM..."
                    terraform taint libvirt_volume.master || true
                    
                    # prepare new nvram overlay for uefi used by aarch64
                    if [[ -e /usr/share/AAVMF/AAVMF_CODE.fd ]]; then
                            sudo cp /usr/share/AAVMF/AAVMF_CODE.fd flash1.img
                    fi

                    set -x
                    terraform apply -auto-approve $tf_args -var token=$reg_token || (
                        send_metrics runners.anomaly "1" "c" "#runner_name:${namevar},#type:vm_tfstate_broken";
                        do_cleanup;
                        terraform apply -auto-approve $tf_args -var token=$reg_token
                    )
                    set +x
                    need_respawn=0

                    sleep 5
                fi

                sleep 5
	done

	sleep 30
done

echoerr "Should not reach here"
