terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = ">= 0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# TODO: migration shim
resource "libvirt_volume" "base_volumes" {
  for_each = toset([local.previous_image_version])
  name     = "runner-ubuntu-22.04-${each.key}.qcow2"
  source   = "/root/ubuntu-22.04-${each.key}"
  format   = "qcow2"
  pool     = libvirt_pool.kong.name
}

resource "libvirt_volume" "ubuntu_2404_base_volumes" {
  # for_each = toset([local.image_version, local.previous_image_version])
  # TODO: migration shim
  for_each = toset([local.image_version])
  name     = "runner-ubuntu-24.04-${each.key}.qcow2"
  source   = "/root/ubuntu-24.04-${each.key}"
  format   = "qcow2"
  pool     = libvirt_pool.kong.name
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

  dns {
    enabled = true
  }

  addresses = ["10.1.0.0/24", "${var.ipv6_prefix}:1001::/96"]

  autostart = true

  xml {
    # patch to use disallow networking between guests
    xslt = file("patch-network-isolated.xsl")
  }
}

