resource "random_string" "bucket_name" {
  length  = 6
  special = false
}

resource "oci_objectstorage_bucket" "bucket1" {
  compartment_id = "${var.compartment_ocid}"
  namespace      = "${data.oci_objectstorage_namespace.ns.namespace}"
  name           = "cockroach-${random_string.bucket_name.result}"
  access_type    = "ObjectRead"
}

data "oci_objectstorage_bucket_summaries" "buckets1" {
  compartment_id = "${var.compartment_ocid}"
  namespace      = "${data.oci_objectstorage_namespace.ns.namespace}"

  filter {
    name   = "name"
    values = ["${oci_objectstorage_bucket.bucket1.name}"]
  }
}
