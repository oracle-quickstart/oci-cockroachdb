## Copyright © 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "template_file" "user_data" {
  template = file("scripts/script.sh")

  vars = {
    count = var.instance_count
    name  = var.instance_name
    ssh_public_key = tls_private_key.public_private_key_pair.public_key_openssh
  }
}

data "template_cloudinit_config" "cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "ainit.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.user_data.rendered
  }
}

resource "oci_core_instance" "CockroachDBInstance" {
  count               = var.instance_count
  availability_domain = var.availablity_domain_name
  fault_domain        = "FAULT-DOMAIN-${count.index + 1}"
  compartment_id      = var.compartment_ocid
  display_name        = "${var.instance_name}${count.index}"
  shape               = var.instance_shape

  dynamic "shape_config" {
    for_each = local.is_flexible_node_shape ? [1] : []
    content {
      memory_in_gbs = var.instance_flex_shape_memory
      ocpus = var.instance_flex_shape_ocpus
    }
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.Subnet.id
    display_name     = "primaryvnic"
    assign_public_ip = true
    hostname_label   = "${var.instance_name}${count.index}"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.InstanceImageOCID.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = data.template_cloudinit_config.cloud_init.rendered
  }

  defined_tags = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

