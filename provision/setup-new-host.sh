#!/bin/bash -e

set -o pipefail

REPO_PATH=$(dirname $(realpath $0))/../

ARCH=$(arch)
if [[ $ARCH == "x86_64" ]]; then ARCH=amd64
elif [[ $ARCH == "aarch64" ]]; then ARCH=arm64
fi

###### packages ######
# xsltproc is required for xsl patching in libvirt provider
sudo apt install -y cpu-checker qemu-kvm \
	libvirt-daemon-system libvirt-clients \
	bridge-utils virtinst virt-manager \
	unzip qemu-utils dnsmasq mkisofs jq git xsltproc
sudo kvm-ok
sudo systemctl stop dnsmasq
sudo systemctl disable dnsmasq

if [[ $ARCH == "arm64" ]]; then
	sudo apt install qemu-efi-aarch64
fi

sudo modprobe vhost_net
lsmod | grep vhost
echo vhost_net | sudo tee -a /etc/modules

sudo systemctl start libvirtd
sudo systemctl enable libvirtd

sudo usermod -aG libvirt $USER
sudo usermod -aG libvirt $USER

###### terraform ######

TF_VER=1.4.2
wget https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_${ARCH}.zip
unzip terraform_${TF_VER}_linux_${ARCH}.zip
mv terraform /usr/local/bin/terraform
rm terraform_${TF_VER}_linux_${ARCH}.zip

sudo rm -rf /var/lib/libvirt/images/*

pushd $REPO_PATH/provision
$REPO_PATH/provision/apply-changes.sh
popd

# currently not sure about the right approach to make it work under apparmor
echo 'security_driver ="none"' |sudo tee -a /etc/libvirt/qemu.conf

sudo systemctl restart libvirtd

###### systemd ######
sudo cp $REPO_PATH/self-hosted-kvm@.service /etc/systemd/system/self-hosted-kvm@.service
sudo systemctl daemon-reload

sudo mkdir -p /root/vms


