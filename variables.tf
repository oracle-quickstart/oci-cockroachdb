## Copyright © 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}
variable "availablity_domain_name" {}

variable "release" {
  description = "Reference Architecture Release (OCI Architecture Center)"
  default     = "1.0"
}

variable "VCN-CIDR" {
  default = "10.0.0.0/16"
}

variable "Subnet-CIDR" {
  default = "10.0.1.0/24"
}

variable "instance_name" {
  default = "cockroach"
}

variable "instance_shape" {
   default = "VM.Standard.E3.Flex"
}

variable "instance_flex_shape_ocpus" {
    default = 1
}

variable "instance_flex_shape_memory" {
    default = 10
}

variable "ssh_public_key" {
  default = ""
}

variable "lb_shape" {
  default = "flexible"
}

variable "flex_lb_min_shape" {
  default = "10"
}

variable "flex_lb_max_shape" {
  default = "100"
}

variable "instance_count" {
  default = 3
}

locals {
  fault_domains_per_ad = 3
}

# OS Images
variable "instance_os" {
  description = "Operating system for compute instances"
  default     = "Oracle Linux"
}

variable "linux_os_version" {
  description = "Operating system version for all Linux instances"
  default     = "7.9"
}

# Dictionary Locals
locals {
  compute_flexible_shapes = [
    "VM.Standard.E3.Flex",
    "VM.Standard.E4.Flex"
  ]
}

# Checks if is using Flexible Compute Shapes
locals {
  is_flexible_lb_shape = var.lb_shape == "flexible" ? true : false
  is_flexible_node_shape = contains(local.compute_flexible_shapes, var.instance_shape)
}
