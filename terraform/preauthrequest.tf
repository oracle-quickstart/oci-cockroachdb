resource "oci_objectstorage_preauthrequest" "bucket_par" {
  namespace    = "${data.oci_objectstorage_namespace.ns.namespace}"
  bucket       = "${oci_objectstorage_bucket.bucket1.name}"
  name         = "parOnBucket"
  access_type  = "AnyObjectWrite"
  time_expires = "${timeadd(local.timestamp, "1h")}"
}

output "par_request_url" {
  value = "https://objectstorage.${var.region}.oraclecloud.com${oci_objectstorage_preauthrequest.bucket_par.access_uri}"
}
