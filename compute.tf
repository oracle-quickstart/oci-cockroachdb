data "template_file" "user_data" {
  template = file("scripts/script.sh")

  vars = {
    count = var.instance_count
    name  = var.instance_name
  }
}

resource "oci_core_instance" "CockroachDBInstance" {
  count               = var.instance_count
  availability_domain = var.availablity_domain_name
#  availability_domain = element(data.template_file.ad_names.*.rendered, count.index)
  fault_domain        = "FAULT-DOMAIN-${count.index + 1}"
  compartment_id      = var.compartment_ocid
  display_name        = "${var.instance_name}${count.index}"
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id        = oci_core_subnet.Subnet.id
    display_name     = "primaryvnic"
    assign_public_ip = true
    hostname_label   = "${var.instance_name}${count.index}"
  }

  source_details {
    source_type = "image"
 #   source_id   = var.images[var.region]
    source_id   = data.oci_core_images.InstanceImageOCID.images[0].id
  }

  metadata = {
    ssh_authorized_keys = tls_private_key.public_private_key_pair.public_key_openssh
    user_data           = base64encode(data.template_file.user_data.rendered)
  }
}

