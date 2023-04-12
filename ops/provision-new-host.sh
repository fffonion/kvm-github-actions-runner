#!/bin/bash -e

set -o pipefail

REPO_PATH=$(dirname $(realpath $0))/../
IMAGE_PATH=/root/ubuntu-22.04

###### packages ######
sudo apt install -y cpu-checker qemu-kvm \
	libvirt-daemon-system libvirt-clients \
	bridge-utils virtinst virt-manager \
	unzip qemu-utils dnsmasq mkisofs jq git
sudo kvm-ok
sudo systemctl stop dnsmasq
sudo systemctl disable dnsmasq

sudo modprobe vhost_net
lsmod | grep vhost
echo vhost_net | sudo tee -a /etc/modules

sudo systemctl start libvirtd
sudo systemctl enable libvirtd

sudo usermod -aG libvirt $USER
sudo usermod -aG libvirt $USER

###### terraform ######
ipv6_prefix=$(ifconfig enp41s0|grep inet6|head -n1|awk '{print $2}'|cut -d: -f1-4)
if test -z "$ipv6_prefix"; then
    echo "No IPv6 prefix found?"
    exit 1
fi

TF_VER=1.4.2
wget https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_amd64.zip
unzip terraform_${TF_VER}_linux_amd64.zip
mv terraform /usr/local/bin/terraform
rm terraform_${TF_VER}_linux_amd64.zip

pushd $REPO_PATH/provision

sudo rm -rf /var/lib/libvirt/images/*

terraform init
terraform apply -auto-approve -var image_path=${IMAGE_PATH} -var ipv6_prefix=${ipv6_prefix}

popd

# currently not sure about the right approach to make it work under apparmor
echo 'security_driver ="none"' |sudo tee -a /etc/libvirt/qemu.conf

sudo systemctl restart libvirtd

###### systemd ######
sudo cp $REPO_PATH/self-hosted-kvm@.service /etc/systemd/system/self-hosted-kvm@.service
sudo systemctl daemon-reload

sudo mkdir -p /root/vms