#!/bin/bash
from=runner2
total_runners=13
file_name=/root/ubuntu-22.04-20230426.1

function get_ip() {
    ssh $1 curl -s cidr.me/ip
}

function get_user() {
    ssh $1 id -nu
}

pending_hosts=("$from")
for i in $(seq 1 $total_runners); do
    if [[ "runner$i" == "$from" ]]; then
        continue
    fi
    pending_hosts+=("runner$i")
done

function do_copy() {
    src=$1
    dst=$2
    usrc=$(get_user $src)
    isrc=$(get_ip $src)
    ssh $dst sudo -E -H rsync -cha -e \"ssh -oStrictHostKeyChecking=no\" --rsync-path=\"sudo rsync\" $usrc@$isrc:$file_name $file_name
    echo "+ Finished $src -> $dst"
}

offset=0
while [[ $(($offset+1)) -lt $total_runners ]]; do
    let group_count=0
    for i in $(seq 0 $offset); do
        let j=i+offset+1
        if [[ $j -ge ${#pending_hosts[@]} ]]; then break; fi
        let group_count=group_count+1
        src=${pending_hosts[$i]}
        dst=${pending_hosts[$j]}
        echo "- Copying $src -> $dst"
        do_copy $src $dst &
    done

    let offset=offset+group_count
    echo "- Wait for copying to finish"
    wait
done
