resource "libvirt_volume" "base_volume" {
  name = "base.qcow2"
  # pool = "default" # List storage pools using virsh pool-list
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img"
  format = "qcow2"
}

resource "libvirt_volume" "master" {
  name           = "master.qcow2"
  base_volume_id = libvirt_volume.base_volume.id
}


# Define KVM domain to create
resource "libvirt_domain" "test" {
  name   = "test"
  memory = "2048"
  vcpu   = 2

  network_interface {
    network_name = "default" # List networks with virsh net-list
  }

  disk {
    volume_id = libvirt_volume.master.id
  }

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}
