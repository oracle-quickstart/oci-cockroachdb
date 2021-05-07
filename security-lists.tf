## Copyright © 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

locals {
  tcp_protocol  = "6"
  all_protocols = "all"
  anywhere      = "0.0.0.0/0"
}

resource "oci_core_security_list" "SecurityList" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.VCN.id
  display_name   = "${var.instance_name}SecurityList"

  egress_security_rules {
    protocol    = local.tcp_protocol
    destination = local.anywhere
  }

  ingress_security_rules {
    protocol = local.tcp_protocol
    source   = local.anywhere

    tcp_options {
      max = "22"
      min = "22"
    }
  }

  ingress_security_rules {
    protocol = local.tcp_protocol
    source   = local.anywhere

    tcp_options {
      max = "8080"
      min = "8080"
    }
  }

  ingress_security_rules {
    protocol = local.tcp_protocol
    source   = local.anywhere

    tcp_options {
      max = "26257"
      min = "26257"
    }
  }
  defined_tags = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

