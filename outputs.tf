output "loadbalancer_public_url" {
  value = "http://${oci_load_balancer_load_balancer.lb1.ip_addresses[0]}:8080"
}

output "generated_ssh_private_key" {
  value = tls_private_key.public_private_key_pair.private_key_pem
}