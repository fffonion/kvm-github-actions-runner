terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "base_volume" {
  name   = "runner-ubuntu-22.04.qcow2"
  source = var.image_path
  format = "qcow2"
}


