data "terraform_remote_state" "networking" {
  backend = "local"
  config = {
    path = "../networking/terraform.tfstate"
  }
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

resource "oci_core_instance" "budgeteer" {
  for_each = var.environments

  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = each.value.display_name
  shape               = var.vm_shape

  create_vnic_details {
    subnet_id        = data.terraform_remote_state.networking.outputs.subnet_id
    assign_public_ip = true
  }

  source_details {
    source_id   = var.ubuntu_image_id
    source_type = "image"
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
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

output "budgeteer_public_ips" {
  value = { for k, v in oci_core_instance.budgeteer : k => v.public_ip }
}

resource "random_password" "jwt_secret" {
  length  = 48
  special = true
}

resource "cloudflare_dns_record" "frontend_dns" {
  for_each = var.environments

  zone_id = var.cloudflare_zone_id
  name    = each.value.frontend_subdomain
  content   = oci_core_instance.budgeteer[each.key].public_ip
  type    = "A"
  ttl     = 300
  comment = "Managed by Terraform"
}

resource "cloudflare_dns_record" "api_dns" {
  for_each = var.environments

  zone_id = var.cloudflare_zone_id
  name    = each.value.api_subdomain
  content   = oci_core_instance.budgeteer[each.key].public_ip
  type    = "A"
  ttl     = 300
  comment = "Managed by Terraform"
}


