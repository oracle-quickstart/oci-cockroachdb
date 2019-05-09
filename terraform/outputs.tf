output "VM public IP" {
  value = "${data.oci_core_vnic.TFInstance_vnic.public_ip_address}"
}
