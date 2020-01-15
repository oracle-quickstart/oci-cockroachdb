data "template_file" "user_data" {
  template = file("../scripts/script.sh")

  vars = {
    count = var.instance["instance_count"]
    name  = var.instance["name"]
  }
}

resource "oci_core_instance" "TFInstance" {
  count               = var.instance["instance_count"]
  availability_domain = element(data.template_file.ad_names.*.rendered, count.index)
  fault_domain        = "FAULT-DOMAIN-{count.index + 1}"
  compartment_id      = var.compartment_ocid
  display_name        = "${var.instance["name"]}${count.index}"
  shape               = var.instance["shape"]

  create_vnic_details {
    subnet_id        = oci_core_subnet.Subnet.id
    display_name     = "primaryvnic"
    assign_public_ip = true
    hostname_label   = "${var.instance["name"]}${count.index}"
  }

  source_details {
    source_type = "image"
    source_id   = var.images[var.region]
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(data.template_file.user_data.rendered)
  }
}

