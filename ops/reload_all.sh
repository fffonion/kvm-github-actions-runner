#!/bin/bash

for i in $(seq 1 13); do
    ssh runner$i "sudo -E -H bash -c 'cd /root/self-hosted-kvm/ && git pull origin master --rebase && systemctl reload self-hosted-kvm@worker-*'"
done
