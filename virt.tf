resource "libvirt_volume" "master" {
  name = "${var.name}-master.qcow2"
  #base_volume_id = libvirt_volume.base_volume.id
  base_volume_name = "runner-ubuntu-22.04-${local.image_version}.qcow2"
  pool             = "kong"
}


# Define KVM domain to create
resource "libvirt_domain" "test" {
  name   = "${var.name}-runner"
  memory = var.memory
  vcpu   = var.cpu

  cpu {
    mode = "host-passthrough"
  }

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  disk {
    volume_id = libvirt_volume.master.id
  }

  xml {
    # patch to use sata controller to compat in arm64
    # https://github.com/dmacvicar/terraform-provider-libvirt/issues/885
    xslt = var.arm64 ? file("patch-cdrom-sata.xsl") : ""
  }

  machine = var.arm64 ? "virt" : "pc"
  nvram {
    file     = var.arm64 ? "/usr/share/AAVMF/AAVMF_CODE.fd" : ""
    template = var.arm64 ? "flash1.img" : ""
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }


  network_interface {
    network_name = "kong" # List networks with virsh net-list
    hostname     = "${var.name}-runner"
  }
}
