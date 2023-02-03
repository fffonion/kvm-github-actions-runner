# Readme

## Install

```shell
sudo apt install cpu-checker qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager unzip qemu-utils dnsmasq jq git
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

## The repo

```shell
git clone <THIS_REPO> /tmp/self-hosted-kvm
cd /tmp/self-hosted-kvm
cat << EOF > /tmp/self-hosted-kvm.env
GITHUB_TOKEN=<token with repo scope for repo runner, or admin:org for org runner>
REPO=<owner/repo; leave empty for org>
EOF

sudo cp self-hosted-kvm@.service /etc/systemd/system/self-hosted-kvm@.service
sudo systemctl daemon-reload

sudo systemctl start self-hosted-kvm@1
sudo systemctl start self-hosted-kvm@2
sudo systemctl start self-hosted-kvm@abaaba
```
