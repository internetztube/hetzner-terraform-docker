resource "hcloud_server" "default" {
  name         = var.name
  server_type  = var.server_type
  image        = "ubuntu-24.04"
  location     = var.location
  user_data    = file("${path.module}/cloud-init.yml")
  firewall_ids = concat(var.firewall_ids, [hcloud_firewall.ssh.id])
  keep_disk = true

  # ipv4 needs to be enabled in order to make ipv4 floating ip work.
  public_net {
    ipv6_enabled = true
    ipv4_enabled = true
  }

  labels = {
    "tf_create_final_snapshot" = var.create_final_snapshot
  }

  ssh_keys = [var.ssh_key_id]

  # Wait until `cloud-init` is finished.
  provisioner "remote-exec" {
    inline = [
      <<EOF
        tail -f /var/log/cloud-init-output.log & TAIL_PID=$!
        cloud-init status --wait > /dev/null
        kill $TAIL_PID
      EOF
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = var.ssh_private_key
      host        = hcloud_server.default.ipv4_address
      timeout     = "5m"
    }
  }

  # Final Snapshot
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    environment = {
      SERVER_ID             = self.id
      SERVER_NAME           = self.name
      SERVER_LOCATION       = self.location
      CREATE_FINAL_SNAPSHOT = lookup(self.labels, "tf_create_final_snapshot", "false")
    }
    command = "sh ${path.module}/scripts/server-final-snapshot.sh"
  }
}
