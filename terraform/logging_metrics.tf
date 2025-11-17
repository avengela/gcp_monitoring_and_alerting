resource "google_logging_metric" "vm_error_count" {
    name = "vm_error_count" 
    description = "Count of ERROR logs from GCE VM instances"
    filter = "resource.type=\"gce_instance\" AND severity>=ERROR"

    metric_descriptor {
        metric_kind = "DELTA"
        value_type = "INT64"
    }
}