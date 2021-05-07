## Copyright © 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_load_balancer_load_balancer" "lb1" {
  shape          = var.lb_shape

  dynamic "shape_details" {
    for_each = local.is_flexible_lb_shape ? [1] : []
    content {
      minimum_bandwidth_in_mbps = var.flex_lb_min_shape
      maximum_bandwidth_in_mbps = var.flex_lb_max_shape
    }
  }
  compartment_id = var.compartment_ocid
  display_name   = "${var.instance_name}-lb1"

  subnet_ids = [
    oci_core_subnet.Subnet.id,
  ]
  defined_tags = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_load_balancer_listener" "lb-listener1" {
  load_balancer_id         = oci_load_balancer_load_balancer.lb1.id
  name                     = "tcp26257"
  default_backend_set_name = oci_load_balancer_backend_set.lb-bes1.name
  port                     = 26257
  protocol                 = "TCP"

  connection_configuration {
    idle_timeout_in_seconds = "2"
  }
}

resource "oci_load_balancer_backend_set" "lb-bes1" {
  name             = "lb-bes1"
  load_balancer_id = oci_load_balancer_load_balancer.lb1.id
  policy           = "ROUND_ROBIN"

  health_checker {
    port                = "8080"
    protocol            = "HTTP"
    response_body_regex = ".*"
    url_path            = "/health?ready=1"
  }
}

resource "oci_load_balancer_backend" "lb-be1" {
  load_balancer_id = oci_load_balancer_load_balancer.lb1.id
  backendset_name  = oci_load_balancer_backend_set.lb-bes1.name
  count            = var.instance_count
  ip_address       = oci_core_instance.CockroachDBInstance[count.index].private_ip
  port             = 26257
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "oci_load_balancer_listener" "lb-listener2" {
  load_balancer_id         = oci_load_balancer_load_balancer.lb1.id
  name                     = "http8080"
  default_backend_set_name = oci_load_balancer_backend_set.lb-bes2.name
  port                     = 8080
  protocol                 = "HTTP"

  connection_configuration {
    idle_timeout_in_seconds = "2"
  }
}

resource "oci_load_balancer_backend_set" "lb-bes2" {
  name             = "lb-bes2"
  load_balancer_id = oci_load_balancer_load_balancer.lb1.id
  policy           = "ROUND_ROBIN"

  health_checker {
    port                = "8080"
    protocol            = "HTTP"
    response_body_regex = ".*"
    url_path            = "/health?ready=1"
  }
}

resource "oci_load_balancer_backend" "lb-be2" {
  load_balancer_id = oci_load_balancer_load_balancer.lb1.id
  backendset_name  = oci_load_balancer_backend_set.lb-bes2.name
  count            = var.instance_count
  ip_address       = oci_core_instance.CockroachDBInstance[count.index].private_ip
  port             = 8080
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

