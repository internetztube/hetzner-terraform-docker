module "main" {
  source                   = "github.com/internetztube/hetzner-terraform-docker"
  name                     = "main"
  server_type              = "cx22"
  location                 = var.location
  floating_ip              = hcloud_floating_ip.main
  volume                   = hcloud_volume.main
  firewall_ids             = [hcloud_firewall.http.id]
  create_final_snapshot    = true
  containers_folder        = abspath("./containers")
  docker_compose_file_path = abspath("./docker-compose.yml")
  ssh_key_id               = hcloud_ssh_key.default.id
  ssh_private_key          = var.ssh_private_key
}

resource "hcloud_firewall" "http" {
  name = "server"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_firewall" "main" {
  name = "main"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_volume" "main" {
  name              = "main"
  size              = 10
  format            = "ext4"
  location          = var.location
  delete_protection = true
}

resource "hcloud_floating_ip" "main" {
  name              = "main"
  type              = "ipv4"
  home_location     = var.location
  delete_protection = true
}

resource "hcloud_ssh_key" "default" {
  name       = "main"
  public_key = var.ssh_public_key
}
