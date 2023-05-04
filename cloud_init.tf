resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "${var.name}-commoninit.iso"
  user_data = data.cloudinit_config.main.rendered

  pool = "kong"
}


data "cloudinit_config" "main" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init.yml",
    { NAME = var.name })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile(
      "${path.module}/cloud-init.sh.tmpl",
      {
        URL         = var.url
        TOKEN       = var.token
        NAME        = var.name
        LABELS      = var.labels
        RUNNERGROUP = var.runnergroup
        DOCKER_USER = var.docker_user
        DOCKER_PASS = var.docker_pass
        RUNNER_VER  = local.runner_version
      }
    )
  }
}

