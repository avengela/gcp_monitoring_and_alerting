resource "google_monitoring_notification_channel" "main_email" {
    display_name = "Main email"
    type = "email"

    labels = {
        email_address =var.email_name
    }
}

resource "google_monitoring_alert_policy" "high_cpu" {
    display_name = "High CPU on VM instances"
    combiner = "OR"
    enabled = true

    conditions {
        display_name = "CPU > 80% for 5 minutes"

        condition_threshold{
            filter = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\""
            comparison = "COMPARISON_GT"
            threshold_value = 0.8
            duration = "300s"
            
            trigger {
                count = 1
            }
        }
    }
    severity = "WARNING"
    notification_channels = [google_monitoring_notification_channel.main_email.id]
}

resource "google_monitoring_alert_policy" "high_memory" {
    display_name = "High memory usage on VM instances"
    combiner = "OR"
    enabled = true

    conditions {
        display_name = "RAM > 70% for 2 minutes"

        condition_threshold {
            filter = "metric.type=\"agent.googleapis.com/memory/percent_used\" AND resource.type=\"gce_instance\""
            comparison = "COMPARISON_GT"
            threshold_value = 70
            duration = "120s"

            trigger {
                count = 1
            }
        }
    }
    severity = "WARNING"
    notification_channels = [google_monitoring_notification_channel.main_email.id]
}

resource "google_monitoring_alert_policy" "uptime_failed" {
    display_name = "Uptime check failed"
    combiner = "OR"
    enabled = true
    

    conditions {
        display_name = "Uptime check failed for 3 minutes"

        condition_threshold {
            filter ="metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"gce_instance\""
            comparison = "COMPARISON_LT"
            threshold_value = 1
            duration = "180s"
        
            trigger {
                count = 1
            }
        }
    }
    severity = "ERROR"
    notification_channels = [google_monitoring_notification_channel.main_email.id]
}


resource "google_monitoring_alert_policy" "disk_full" {
  display_name = "High Disk Usage"
  combiner     = "OR"
  enabled = true

  conditions {
    display_name = "Disk > 80%"
    condition_threshold {
      filter          = "metric.type=\"agent.googleapis.com/disk/percent_used\" AND resource.type=\"gce_instance\" AND metric.label.state = \"used\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 80
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.main_email.id]
}