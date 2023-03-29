# Readme

## Install

```shell
sudo apt install cpu-checker qemu-kvm \
	libvirt-daemon-system libvirt-clients \
	bridge-utils virtinst virt-manager \
	unzip qemu-utils dnsmasq mkisofs jq git
sudo kvm-ok

sudo modprobe vhost_net
lsmod | grep vhost
echo vhost_net | sudo tee -a /etc/modules

sudo systemctl start libvirtd
sudo systemctl enable libvirtd


sudo usermod -aG libvirt $USER
sudo usermod -aG libvirt $USER

sudo virsh pool-define-as --name default --type dir --target /var/lib/libvirt/images/
sudo virsh pool-autostart default

sudo virsh net-destroy default
sudo virsh net-edit default
# add  <ip family='ipv6' address='</64-prefix>:1001::2' prefix='96'>
    <dhcp>
      <range start='</64-prefix>:1001::1001' end='</64-prefix>:1001::1fff'/>
    </dhcp>
  </ip>
#
sudo virsh net-start default

sudo virsh net-autostart default

# currently not sure about the right approach to make it work under apparmor
echo 'security_driver ="none"' |sudo tee -a /etc/libvirt/qemu.conf

sudo systemctl restart libvirtd

TF_VER=1.4.2
wget https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_amd64.zip
unzip terraform_${TF_VER}_linux_amd64.zip
mv terraform /usr/local/bin/terraform
rm terraform_${TF_VER}_linux_amd64.zip

``` 

## The base image

```shell
git clone https://github.com/fffonion/runner-images-kvm -b kvm
cd runner-images-kvm/images/linux
packer build ./ubuntu-2204.pkr.hcl
# creates  output-custom_image/ubuntu-22.04
``` 

## The repo

```shell
git clone https://github.com/fffonion/kvm-github-actions-runner /root/self-hosted-kvm
cd /root/self-hosted-kvm

# uplaod the base image into volume
pushd base-volume
terraform init
terraform apply -auto-approve -var image_path=/path/to/runner-images-kvm/output-custom_image/ubuntu-22.04
popd

cat << EOF > /root/self-hosted-kvm.env
GITHUB_TOKEN=<token with repo scope for repo runner, or admin:org for org runner>
REPO=<owner/repo; leave empty for org>
LABELS=kvm,awesome-runner
RUNNER_VERSION=2.301.1
DOCKER_USER=<docker user that access to public registry, to increase pull rate limit only>
DOCKER_PASSWORD=<the password>
EOF

sudo cp self-hosted-kvm@.service /etc/systemd/system/self-hosted-kvm@.service
sudo systemctl daemon-reload

sudo mkdir /root/vms

sudo systemctl start self-hosted-kvm@test1
sudo systemctl start self-hosted-kvm@test2
sudo systemctl start self-hosted-kvm@tiny1
```

Each VM has 2 vCPU and 4G RAM.

## Useful debugging commands

```
# show running VMs
virsh -c qemu:///system list

# show all VMs
virsh -c qemu:///system list --all

# destroy (stop the qemu process)
virsh -c qemu:///system destroy $(hostname)-test1-runner

# undefine (remove from libvirt)
virsh -c qemu:///system undefine $(hostname)-test1-runner

# use the serial console; username and password both `ubuntu`
# might need to type Enter to show new shell prompt
virsh -c qemu:///system console $(hostname)-test1-runner

# display dhcp leases
virsh -c qemu:///system net-dhcp-leases default
```
