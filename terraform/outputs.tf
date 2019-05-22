output "CockroachDB load balancer public IP" {
  value = ["${oci_load_balancer_load_balancer.lb1.ip_addresses}"]
}
