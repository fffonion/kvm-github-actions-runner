resource "libvirt_volume" "base_volume" {
  name = "runner-ubuntu-22.04.qcow2"
  source = "/home/wangchong/runner-images-kvm/images/linux/output-custom_image.old/ubuntu-22.04"
  format = "qcow2"
}


