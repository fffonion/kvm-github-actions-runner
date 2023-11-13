#!/bin/bash
total_runners=${1:-13}
image_version=$(cat $(dirname $0)/../local.tf|grep image_version|cut -d '"' -f2)
image_version=${2:-$image_version}
file_name=/root/ubuntu-22.04-$image_version

if [[ -z "$RUNNER_IMAGE_STORAGE_HOST" ]]; then
    echo '$RUNNER_IMAGE_STORAGE_HOST must be set'
    exit 1
fi

if [[ $from == *a ]]; then
    prefix="arm64-"
fi

echo "* Image to copy: $file_name"
echo "* Bootstrap node: $from"
echo "* Total runners: $total_runners"

for i in $(seq 1 $total_runners); do
    pending_hosts+=("${prefix}runner-$i")
done

function do_copy() {
    ssh $dst sudo -E -H rsync -cha rsync://$RUNNER_IMAGE_STORAGE_HOST/build/$(basename $file_name) $file_name
    echo "+ Finished $dst"
}

offset=0
let group_count=0
for i in $(seq 0 $offset); do
    dst=${pending_hosts[$i]}
    echo "- Copying $dst"
    do_copy $src $dst &
done

echo "- Wait for copying to finish"
wait
