resource "oci_core_virtual_network" "VCN" {
  cidr_block     = "10.1.0.0/16"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.instance["name"]}VCN"
  dns_label      = "${lower(var.instance["name"])}vcn"
}

resource "oci_core_subnet" "Subnet" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ad.availability_domains[var.availability_domain - 1],"name")}"
  cidr_block          = "10.1.20.0/24"
  display_name        = "${var.instance["name"]}Subnet"
  dns_label           = "${lower(substr(var.instance["name"], 0, 9))}subnet"
  security_list_ids   = ["${oci_core_security_list.SecurityList.id}"]
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.VCN.id}"
  route_table_id      = "${oci_core_route_table.RT.id}"
  dhcp_options_id     = "${oci_core_virtual_network.VCN.default_dhcp_options_id}"
}

resource "oci_core_internet_gateway" "IG" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.instance["name"]}IG"
  vcn_id         = "${oci_core_virtual_network.VCN.id}"
}

resource "oci_core_route_table" "RT" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.VCN.id}"
  display_name   = "${var.instance["name"]}RouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = "${oci_core_internet_gateway.IG.id}"
  }
}
