output "CockroachDBLoadBalancerPublicIP" {
  value = ["${oci_load_balancer_load_balancer.lb1.ip_addresses[0]}"]
}

output "CockroachDB Username" {
  value = "cockroach"
}

output "Cockroach Password" {
  value     = "${random_string.password.result}"
  sensitive = false
}
