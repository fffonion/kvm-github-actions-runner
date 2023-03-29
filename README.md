# Readme

## Install

```shell
sudo apt install cpu-checker qemu-kvm \
	libvirt-daemon-system libvirt-clients \
	bridge-utils virtinst virt-manager \
	unzip qemu-utils dnsmasq jq git
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

sudo systemctl restart libvirtd

TF_VER=1.4.2
wget https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_amd64.zip
unzip terraform_${TF_VER}_linux_amd64.zip
mv terraform /usr/local/bin/terraform
rm terraform_${TF_VER}_linux_amd64.zip

``` 

## The base image

```shell
git clone https://github.com/fffonion/runner-images-kvm
cd runner-images-kvm/images/linux
packer build ./ubuntu-2204.pkr.hcl
# creates  output-custom_image/ubuntu-22.04
``` 

## The repo

```shell
git clone <THIS_REPO> /root/self-hosted-kvm -b kvm
cd /root/self-hosted-kvm

# uplaod the base image into volume
pushd base-volume
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

sudo systemctl start self-hosted-kvm@runner-1
sudo systemctl start self-hosted-kvm@runner-2
sudo systemctl start self-hosted-kvm@runner-abaaba
```

Each VM has 2 vCPU and 4G RAM.
