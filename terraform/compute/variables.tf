variable "compartment_ocid" {}
variable "cloudflare_api_token" {}
variable "cloudflare_zone_id" {}
variable "subnet_id" {}
variable "ubuntu_image_id" {
  default = "ocid1.image.oc1.eu-stockholm-1.aaaaaaaam6t7hfwppnu4ki6eej4kfytqfapcsrtuyu5r2rqybidhtr6k54ja"
}
variable "vm_shape" {
  default = "VM.Standard.E2.1.Micro"
}

variable "environments" {
  type = map(object({
    display_name       = string
    frontend_subdomain = string
    api_subdomain      = string
    domain             = string
  }))

  default = {
    prod = {
      display_name     = "sample-app"
      frontend_subdomain = "sample-app"
      api_subdomain    = "api.sample-app"
      domain           = "sammosios.com"
    }
  }
}
