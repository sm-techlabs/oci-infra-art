terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }

  backend "oci" {
    bucket          = "terraform-state"
    namespace       = "axtuta2rk2uc"
    region          = "eu-stockholm-1"
    key             = "compute.tfstate"
  }
}

provider "oci" {
  config_file_profile = "DEFAULT"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}