terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.9"  # Use a compatible version range instead of a fixed patch version
    }
  }

  backend "oci" {
    bucket          = "terraform-state"
    namespace       = "axtuta2rk2uc"
    region          = "eu-stockholm-1"
    key             = "networking.tfstate"
  }
}

provider "oci" {
  config_file_profile = "DEFAULT"
}
