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

resource "libvirt_pool" "default" {
  name = "kong"
  type = "dir"
  path = "/var/lib/libvirt/images/"
}

resource "libvirt_network" "default" {
  name   = "kong"
  mode   = "nat"
  domain = "ci.konghq.com.internal"

  addresses = ["10.1.0.0/24", "${var.ipv6_prefix}:1001::1/96"]

  autostart = true
}

