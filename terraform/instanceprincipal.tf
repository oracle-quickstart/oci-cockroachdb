data "oci_identity_compartment" "compartment1" {
  id = "${var.compartment_ocid}"
}

resource "oci_identity_dynamic_group" "dynamic-group1" {
  compartment_id = "${var.tenancy_ocid}"
  name           = "${var.instance["name"]}DynamicGroup"
  description    = "Dynamic Group for executing CLI with Instance Principal authentication"
  matching_rule  = "ANY {instance.compartment.id = '${var.compartment_ocid}'}"
}

resource "oci_identity_policy" "instance-principal-policy1" {
  compartment_id = "${var.compartment_ocid}"
  name           = "${var.instance["name"]}Policy"
  description    = "Policy to allow Instance Principal CLI execution"
  statements     = ["ALLOW dynamic-group ${oci_identity_dynamic_group.dynamic-group1.name} to manage all-resources IN compartment ${data.oci_identity_compartment.compartment1.name}"]
}
