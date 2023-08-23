#!/bin/bash

name=$1

if [[ -z $name ]]; then
    echo "Usage: $0 <name>"
fi

s=$(virsh -c qemu:///system domstate $(hostname)-worker-${name}-runner)
echo "Domain is $s"

systemctl stop self-hosted-kvm@worker-$name

if [[ $(arch) == "aarch64" ]]; then
    undefine_args="--nvram"
fi

virsh -c qemu:///system destroy $(hostname)-worker-${name}-runner
virsh -c qemu:///system undefine $undefine_args $(hostname)-worker-${name}-runner 

virsh vol-delete $(hostname)-worker-${name}-commoninit.iso kong
virsh vol-delete $(hostname)-worker-${name}-master.iso kong

systemctl start self-hosted-kvm@worker-$name

s=$(virsh -c qemu:///system domstate $(hostname)-worker-${name}-runner)
echo "Domain is $s"
