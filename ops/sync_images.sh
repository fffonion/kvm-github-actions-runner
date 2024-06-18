#!/bin/bash
total_runners=${1:-15}
image_version=$(cat $(dirname $0)/../local.tf|grep image_version|grep -v previous|cut -d '"' -f2)
image_arch=${2:-amd64}
image_version=${3:-$image_version}
rel=${4:-22}
file_name=/root/ubuntu-${rel}.04-$image_version

if [[ -z "$RUNNER_IMAGE_STORAGE_HOST" ]]; then
    echo '$RUNNER_IMAGE_STORAGE_HOST must be set'
    exit 1
fi

echo "* Image to copy: $file_name"
echo "* Architecture: $image_arch"
echo "* Total runners: $total_runners"

function do_copy() {
    dst=$1
    if [[ $image_arch == "arm64" ]]; then
        path=arm64
    else
        path=amd64
    fi
    ssh $dst sudo -E -H rsync -cha rsync://$RUNNER_IMAGE_STORAGE_HOST/build/$path/$(basename $file_name) $file_name
    echo "+ Finished $dst"
}

for i in $(seq 1 $total_runners); do
    if [[ $image_arch == "arm64" ]]; then
        dst="runner-arm64-$i"
    else
        dst="runner-$i"
    fi
    echo "- Copying $dst"
    do_copy $dst &
done

echo "- Wait for copying to finish"
wait
