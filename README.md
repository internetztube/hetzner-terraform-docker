# Hetzner Terraform Docker

## Example
[Full Example](./example)

```terraform
module "main" {
  source       = "github.com/internetztube/hetzner-terraform-docker"
  name         = "main"
  server_type  = "cx22"
  location     = var.location
  floating_ip  = hcloud_floating_ip.main
  volume       = hcloud_volume.main
  firewall_ids = [hcloud_firewall.http.id]

  containers_folder        = abspath("./containers")
  docker_compose_file_path = abspath("./docker-compose.yml")

  ssh_key_id      = hcloud_ssh_key.default.id
  ssh_private_key = var.ssh_private_key
}
```