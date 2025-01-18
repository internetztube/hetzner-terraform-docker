resource "null_resource" "docker-build" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      CONTAINERS_FOLDER_PATH = var.containers_folder
      CONTAINERS_ARTIFACTS_FOLDER_PATH = local.container_artifacts_folder_path
    }
    command = "sh ${path.module}/scripts/docker-build.sh"
  }
}

resource "local_file" "env_file" {
  filename = "${path.module}/.env"
  content = join("\n", [
    for env in var.env_variables : "${env.name}=${env.value}"
  ])
}

resource "null_resource" "docker-upload" {
  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [
    null_resource.docker-build,
    hcloud_server.default,
    hcloud_volume_attachment.default
  ]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = var.ssh_private_key
    host        = hcloud_server.default.ipv4_address
    timeout     = "5m"
  }

  provisioner "file" {
    source      = var.docker_compose_file_path
    destination = "/root/docker-compose.yml"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/docker-load.sh"
    destination = "/root/docker-load.sh"
  }

  provisioner "file" {
    source      = "${path.module}/.env"
    destination = "/root/.env"
  }

  provisioner "file" {
    source      = "${path.module}/docker-compose.service"
    destination = "/etc/systemd/system/docker-compose.service"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/container-artifacts"
    ]
  }

  # Upload Docker Containers
  provisioner "file" {
    source      = "${local.container_artifacts_folder_path}/"
    destination = "/root/container-artifacts"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 644 /etc/systemd/system/docker-compose.service",
      "systemctl daemon-reload",
      "systemctl enable docker-compose",
      "mkdir -p /root/container-artifacts"
    ]
  }

  # Load Docker Containers
  provisioner "remote-exec" {
    inline = [
      "sh /root/docker-load.sh"
    ]
  }
}
