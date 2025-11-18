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

    notification_channels = [google_monitoring_notification_channel.main_email.id]
}

resource "google_monitoring_alert_policy" "high_memory" {
    display_name = "High memory usage on VM instances"
    combiner = "OR"
    enabled = true

    conditions {
        display_name = "RAM > 47% for 2 minutes"

        condition_threshold {
            filter = "metric.type=\"agent.googleapis.com/memory/percent_used\" AND resource.type=\"gce_instance\""
            comparison = "COMPARISON_GT"
            threshold_value = 47
            duration = "120s"

            trigger {
                count = 1
            }
        }
    }
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

    notification_channels = [google_monitoring_notification_channel.main_email.id]
}


resource "google_monitoring_alert_policy" "syslog_error_spike"{
  display_name = "Syslog Error Spike"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "More than 1 syslog error within 1 minute"

    condition_threshold {
      filter = "metric.type=\"logging.googleapis.com/user/syslog_error_count\" AND resource.type=\"gce_instance\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1        
      duration        = "60s"    

      trigger {
        count = 1
      }
    }
  }

    notification_channels = [google_monitoring_notification_channel.main_email.id]
}