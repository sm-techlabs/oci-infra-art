output "private_key_pem" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

output "vm_public_ips" {
  value = { for k, v in oci_core_instance.vm : k => v.public_ip }
}