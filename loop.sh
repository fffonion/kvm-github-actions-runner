#!/bin/bash -ex

if [[ -z $GITHUB_TOKEN ]]; then
	echo '$GITHUB_TOKEN is required'
	exit 1
fi

if [[ ! -z $ORG ]]; then
	url=https://api.github.com/orgs/${ORG}/actions/runners/registration-token
elif [[ ! -z $REPO ]]; then
	url=https://api.github.com/repos/${REPO}/actions/runners/registration-token
else
	echo 'Neither $ORG nor $REPO is defined'
	exit 1
fi

token_start=$(date +%s)
token_expire=$((token_start + 3500))
reg_token_ret=$(curl \
  -s \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN"\
  -H "X-GitHub-Api-Version: 2022-11-28" \
  $url)

reg_token=$(echo "$reg_token_ret" | jq -r .token)
if [[ -z $reg_token || $reg_token == "null" ]]; then
	echo "Unable to get registration token, error was $reg_token_ret"
	exit 1
fi

echo "Reg token is obtained: $reg_token"

repovar=""
if [[ ! -z $REPO ]]; then
	repovar=https://github.com/$REPO
fi
namevar="$NAME"
if [[ ! -z $namevar ]]; then
	namevar="$namevar-"
fi
namevar="$namevar$(echo $RANDOM | md5sum | head -c 8)"

workdir=/tmp/self-hosted-kvm-tf-$NAME
statedir=/tmp/self-hosted-kvm-tf-$NAME.state
mkdir -p $statedir
if [[ -e $workdir/terraform.tfstate ]]; then
	cp $workdir/terraform.tfstate* $statedir
fi
rm -rf $workdir
cp -r $(dirname $(readlink -f $0)) $workdir
pushd $workdir

rm terraform.tfstate* -f
if [[ -e $statedir/terraform.tfstate ]]; then
	cp $statedir/terraform.tfstate* $workdir
fi

terraform init -upgrade

# avoid token change result in an re-apply; we only re-apply when instance exists/job finishes
old_token=$reg_token
while [[ $(date +%s) -lt $token_expire ]]; do
	while [[ ! -z $(terraform state list) ]]; do
		terraform plan -var repo=$repovar -var runner_version=2.301.1 -var token=$old_token -var name=$namevar -detailed-exitcode || (terraform taint libvirt_volume.master; break)
		sleep 5
	done	

	terraform apply -auto-approve -var repo=$repovar -var runner_version=2.301.1 -var token=$reg_token -var name=$namevar
	old_token=reg_token
 done
