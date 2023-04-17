resource "libvirt_volume" "master" {
  name = "${var.name}-master.qcow2"
  #base_volume_id = libvirt_volume.base_volume.id
  base_volume_name = "runner-ubuntu-22.04-${local.image_version}.qcow2"
  # size             = 85899345920 # 80G
  pool = "kong"
}


# Define KVM domain to create
resource "libvirt_domain" "test" {
  name   = "${var.name}-runner"
  memory = "7168"
  vcpu   = 2

  cpu {
    mode = "host-passthrough"
  }

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  disk {
    volume_id = libvirt_volume.master.id
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
