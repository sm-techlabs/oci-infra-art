data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "oci_core_instance" "vm" {
  for_each = var.environments

  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = each.value.display_name
  shape               = var.vm_shape

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = true
  }

  source_details {
    source_id   = var.ubuntu_image_id
    source_type = "image"
  }

  metadata = {
    ssh_authorized_keys = tls_private_key.ssh_key.public_key_openssh
    jwt_secret         = random_password.jwt_secret.result
    user_data           = base64encode(templatefile("${path.module}/../scripts/cloud-init.yaml.tpl", {
      git_branch      = "main"
      frontend_subdomain = each.value.frontend_subdomain
      api_subdomain      = each.value.api_subdomain
      domain          = each.value.domain
      jwt_secret   = random_password.jwt_secret.result
    }))
  }
}

resource "random_password" "jwt_secret" {
  length  = 48
  special = true
}

resource "cloudflare_dns_record" "frontend_dns" {
  for_each = var.environments

  zone_id = var.cloudflare_zone_id
  name    = each.value.frontend_subdomain
  content   = oci_core_instance.vm[each.key].public_ip
  type    = "A"
  ttl     = 300
  comment = "Managed by Terraform"
}

resource "cloudflare_dns_record" "api_dns" {
  for_each = var.environments

  zone_id = var.cloudflare_zone_id
  name    = each.value.api_subdomain
  content   = oci_core_instance.vm[each.key].public_ip
  type    = "A"
  ttl     = 300
  comment = "Managed by Terraform"
}


