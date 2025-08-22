data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "oci_core_instance" "vm" {
  for_each = var.instances

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
    jwt_secret          = random_password.jwt_secret.result
    user_data = base64encode(templatefile("${path.module}/../scripts/${each.key}-cloud-init.yaml.tpl", {
      domain                           = each.value.domain
      api_subdomain                    = each.value.api_subdomain
      frontend_subdomain               = each.value.frontend_subdomain
      custom_string                    = var.custom_string != "" ? var.custom_string : each.value.custom_string
      jwt_secret                       = random_password.jwt_secret.result
      doodlebox_github_app_private_key = var.doodlebox_github_app_private_key
    }))
  }
}

resource "random_password" "jwt_secret" {
  length  = 48
  special = true
}

resource "oci_core_volume" "block_volume" {
  for_each = var.instances

  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = "${each.key}-caddy-volume"
  size_in_gbs         = var.block_volume_size_in_gbs
  vpus_per_gb         = var.block_volume_vpus_per_gb
}

resource "oci_core_volume_attachment" "volume_attachment" {
  for_each = var.instances

  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.vm[each.key].id
  volume_id       = oci_core_volume.block_volume[each.key].id
}

resource "cloudflare_dns_record" "frontend_dns" {
  for_each = var.instances

  zone_id = var.cloudflare_zone_id
  name    = each.value.frontend_subdomain
  content = oci_core_instance.vm[each.key].public_ip
  type    = "A"
  ttl     = 300
  comment = "Managed by Terraform"
}

resource "cloudflare_dns_record" "api_dns" {
  for_each = var.instances

  zone_id = var.cloudflare_zone_id
  name    = each.value.api_subdomain
  content = oci_core_instance.vm[each.key].public_ip
  type    = "A"
  ttl     = 300
  comment = "Managed by Terraform"
}


