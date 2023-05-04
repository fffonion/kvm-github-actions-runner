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

# the previous version of the image to keep during migration
resource "libvirt_volume" "base_volume-20230409-2" {
  name   = "runner-ubuntu-22.04-20230409.2.qcow2"
  source = "/root/ubuntu-22.04-20230409.2"
  format = "qcow2"
  pool   = libvirt_pool.kong.name
}

resource "libvirt_volume" "base_volume-20230426-1" {
  name   = "runner-ubuntu-22.04-${local.image_version}.qcow2"
  source = "/root/ubuntu-22.04-${local.image_version}"
  format = "qcow2"
  pool   = libvirt_pool.kong.name
}

resource "libvirt_pool" "kong" {
  name = "kong"
  type = "dir"
  path = "/var/lib/libvirt/images"
}

resource "libvirt_network" "kong" {
  name   = "kong"
  mode   = "nat"
  domain = "ci.konghq.com.internal"

  addresses = ["10.1.0.0/24", "${var.ipv6_prefix}:1001::/96"]

  autostart = true
}

