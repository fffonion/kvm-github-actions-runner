resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  user_data = data.cloudinit_config.main.rendered
}


data "cloudinit_config" "main" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/cloud-init.yml", {})
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile(
      "${path.module}/cloud-init.sh.tmpl",
      {
        REPO       = var.repo
        TOKEN      = var.token
        NAME       = var.name
        RUNNER_VER = var.runner_version
      }
    )
  }
}

