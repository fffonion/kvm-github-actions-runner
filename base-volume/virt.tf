resource "libvirt_volume" "base_volume" {
  name = "runner-ubuntu-22.04.qcow2"
  source = "/home/wangchong/runner-images-kvm/images/linux/output-custom_image/ubuntu-22.04"
  #source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img"
  format = "qcow2"
}


