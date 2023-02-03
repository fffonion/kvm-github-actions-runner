#!/bin/bash -e

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
rm -rf $workdir
cp -r $(dirname $(readlink -f $0)) $workdir
pushd $workdir

while [[ $(date +%s) -lt $token_expire ]]; do
	while true; do
		terraform plan -var repo=$repovar -var runner_version=2.301.1 -var token=$reg_token -var name=$namevar -detailed-exitcode || break
		sleep 5
	done	

	terraform taint libvirt_volume.master
	terraform apply -auto-approve -var repo=$repovar -var runner_version=2.301.1 -var token=$reg_token -var name=$namevar
 done
