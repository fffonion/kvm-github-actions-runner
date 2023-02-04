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

mkdir -p $HOME/.local/share/libvirt/images
sudo virsh pool-define-as --name default --type dir --target $HOME/.local/share/libvirt/images/
sudo virsh pool-autostart default

sudo virsh net-autostart default

sudo systemctl restart libvirtd

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
git clone <THIS_REPO> /tmp/self-hosted-kvm
cd /tmp/self-hosted-kvm

# uplaod the base image into volume
pushd base-volume
terraform apply -auto-approve -var image_path=/path/to/runner-images-kvm/output-custom_image/ubuntu-22.04
popd

cat << EOF > /tmp/self-hosted-kvm.env
GITHUB_TOKEN=<token with repo scope for repo runner, or admin:org for org runner>
REPO=<owner/repo; leave empty for org>
EOF

sudo cp self-hosted-kvm@.service /etc/systemd/system/self-hosted-kvm@.service
sudo systemctl daemon-reload

sudo systemctl start self-hosted-kvm@runner-1
sudo systemctl start self-hosted-kvm@runner-2
sudo systemctl start self-hosted-kvm@runner-abaaba
```

Each VM has 2 vCPU and 4G RAM.
