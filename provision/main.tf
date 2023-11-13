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

# TODO: clean up next apply, graceful rollout
resource "libvirt_volume" "base_volume-20231016-1" {
  name   = "runner-ubuntu-22.04-20231016.1.qcow2"
  source = "/root/ubuntu-22.04-20231016.1"
  format = "qcow2"
  pool   = libvirt_pool.kong.name
}

resource "libvirt_volume" "base_volumes" {
  for_each = toset([local.image_version, local.previous_image_version])
  name     = "runner-ubuntu-22.04-${each.key}.qcow2"
  source   = "/root/ubuntu-22.04-${each.key}"
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

  addresses = ["10.1.0.0/24", "${var.ipv6_prefix}:1001::/96"]

  autostart = true

  xml {
    # patch to use disallow networking between guests
    xslt = file("patch-network-isolated.xsl")
  }
}

