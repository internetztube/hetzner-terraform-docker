terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.48.1"
    }
  }
  backend "s3" {
    bucket                      = "bucket-name"
    region                      = "fsn1"
    key                         = "file-name.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    use_path_style              = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
    endpoints = {
      s3 = "https://nbg1.your-objectstorage.com"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}
