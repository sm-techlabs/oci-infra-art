variable "compartment_ocid" {}
variable "cloudflare_api_token" {}
variable "cloudflare_zone_id" {}
variable "subnet_id" {}
variable "doodlebox_github_app_private_key" {
  description = "Private key for the Doodlebox GitHub App, used for API access."
  type        = string
  default     = ""
}
variable "custom_string" {
  description = "A string set by the user used to customize the deployment."
  type        = string
  default     = ""
}
variable "ubuntu_image_id" {
  default = "ocid1.image.oc1.eu-stockholm-1.aaaaaaaam6t7hfwppnu4ki6eej4kfytqfapcsrtuyu5r2rqybidhtr6k54ja"
}
variable "vm_shape" {
  default = "VM.Standard.E2.1.Micro"
}

variable "block_volume_size_in_gbs" {
  description = "Size of the block volume in GBs."
  default     = 50
}

variable "block_volume_vpus_per_gb" {
  description = "VPUs per GB for the block volume."
  default     = 10
}

variable "instances" {
  type = map(object({
    display_name       = string
    domain             = optional(string, "sammosios.com")
    api_subdomain      = string
    frontend_subdomain = optional(string, "frontend")
    custom_string      = optional(string, "instance-level-custom-string")
  }))

  default = {
    doodlebox = {
      display_name       = "doodlebox"
      frontend_subdomain = "doodlebox"
      api_subdomain      = "api.doodlebox"
    }
    ephemeral = {
      display_name       = "ephemeral"
      frontend_subdomain = "ephemeral"
      api_subdomain      = "api.ephemeral"
      custom_string      = "ephemeral-custom-string"
    }
  }
}
