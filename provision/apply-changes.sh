#!/bin/bash

# TEMP ROLLOUT STARTS
ARCH=$(arch)
if [[ $ARCH == "x86_64" ]]; then ARCH=amd64
elif [[ $ARCH == "aarch64" ]]; then ARCH=arm64
fi

if [[ $ARCH == "arm64" ]]; then
	sudo apt install qemu-efi-aarch64
fi

sudo apt install -y xsltproc

# TEMP ROLLOUT ENDS

ens=$(ip -o -4 route show to default|awk '{print $5}')
ipv6_prefix=$(ifconfig $ens|grep inet6|grep -v fe80::|awk '{print $2}'|cut -d: -f1-4)
if test -z "$ipv6_prefix"; then
    echo "No IPv6 prefix found?"
    exit 1
fi

terraform init
terraform apply -var ipv6_prefix=${ipv6_prefix}
