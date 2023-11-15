#!/bin/bash
total_runners=${1:-13}
image_version=$(cat $(dirname $0)/../local.tf|grep image_version|grep -v previous|cut -d '"' -f2)
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

function do_copy() {
    ssh $dst sudo -E -H rsync -cha rsync://$RUNNER_IMAGE_STORAGE_HOST/build/$(basename $file_name) $file_name
    echo "+ Finished $dst"
}

for i in $(seq 1 $total_runners); do
    dst="${prefix}runner-$i"
    echo "- Copying $dst"
    do_copy $src $dst &
done

echo "- Wait for copying to finish"
wait
