#!/bin/bash -e

set -o pipefail

REPO_PATH=$(dirname $(realpath $0))/../

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

TF_VER=1.4.2
wget https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_amd64.zip
unzip terraform_${TF_VER}_linux_amd64.zip
mv terraform /usr/local/bin/terraform
rm terraform_${TF_VER}_linux_amd64.zip

sudo rm -rf /var/lib/libvirt/images/*

$REPO_PATH/provision/apply-changes.sh

# currently not sure about the right approach to make it work under apparmor
echo 'security_driver ="none"' |sudo tee -a /etc/libvirt/qemu.conf

sudo systemctl restart libvirtd

###### systemd ######
sudo cp $REPO_PATH/self-hosted-kvm@.service /etc/systemd/system/self-hosted-kvm@.service
sudo systemctl daemon-reload

sudo mkdir -p /root/vms