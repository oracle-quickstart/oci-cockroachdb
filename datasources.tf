# Get a list of Availability Domains
#data "oci_identity_availability_domains" "ad" {
#  compartment_id = var.tenancy_ocid
#}

#data "template_file" "ad_names" {
#  count = length(
#    data.oci_identity_availability_domains.ad.availability_domains,
#  )
#  template = data.oci_identity_availability_domains.ad.availability_domains[count.index]["name"]
#}

data "oci_core_vnic_attachments" "CockroachDBInstance_vnics" {
  compartment_id      = var.compartment_ocid
#  availability_domain = data.oci_identity_availability_domains.ad.availability_domains[0]["name"]
  availability_domain = var.availablity_domain_name
  instance_id         = oci_core_instance.CockroachDBInstance[0].id
}

data "oci_core_vnic" "CockroachDBInstance_vnic" {
  vnic_id = data.oci_core_vnic_attachments.CockroachDBInstance_vnics.vnic_attachments[0]["vnic_id"]
}

# Get the latest Oracle Linux image
data "oci_core_images" "InstanceImageOCID" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.instance_os
  operating_system_version = var.linux_os_version

  filter {
    name   = "display_name"
    values = ["^.*Oracle[^G]*$"]
    regex  = true
  }
}



