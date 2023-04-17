#!/bin/bash

ens=$(ip -o -4 route show to default|awk '{print $5}')
ipv6_prefix=$(ifconfig $ens|grep inet6|grep -v fe80::|awk '{print $2}'|cut -d: -f1-4)
if test -z "$ipv6_prefix"; then
    echo "No IPv6 prefix found?"
    exit 1
fi

pushd $REPO_PATH/provision

terraform init
terraform apply -var ipv6_prefix=${ipv6_prefix}

popd