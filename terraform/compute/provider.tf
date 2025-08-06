terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "7.9.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

provider "oci" {
  config_file_profile = "DEFAULT"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}