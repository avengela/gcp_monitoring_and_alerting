resource "google_monitoring_dashboard" "vm_full_dashboard" {
  dashboard_json = jsonencode({
    displayName = "VM Monitoring Dashboard"

    gridLayout = {
      columns = 2
      widgets = [

        # ---- CPU Utilization per VM ----
        {
          title = "CPU Utilization per VM"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"agent.googleapis.com/cpu/utilization\" AND resource.type=\"gce_instance\" AND metric.label.cpu_state != \"idle\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["metadata.system_labels.name"]
                    }
                  }
                }
              }
            ]
            thresholds = [
              {
                label = "80% High CPU"
                value = 80
              }
            ]
            yAxis = {
              label = "CPU Usage (%)"
              scale = "LINEAR"
            }
          }
        },

        # ---- RAM Usage per VM ----
        {
          title = "RAM Usage per VM"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"agent.googleapis.com/memory/percent_used\" AND resource.type=\"gce_instance\" AND metric.label.state = \"used\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["metadata.system_labels.name"]
                    }
                  }
                }
              }
            ]
            thresholds = [
              {
                label = "70% High RAM"
                value = 70
              }
            ]
            yAxis = {
              label = "RAM Usage (%)"
              scale = "LINEAR"
            }
          }
        },

        # ---- Uptime Check Status per VM ----
        {
          title = "Uptime Check Status per VM"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\""
                    aggregation = {
                      alignmentPeriod  = "300s"
                      perSeriesAligner = "ALIGN_FRACTION_TRUE"
                      groupByFields    = ["metric.labels.check_id"]
                    }
                  }
                }
              }
            ]
            thresholds = [
              {
                label = "Fail Threshold"
                value = 0
              }
            ]
            yAxis = {
              label = "Check Passed (1=OK, 0=Fail)"
              scale = "LINEAR"
            }
          }
        },

        # ---- Disk Usage (/dev/sda1) per VM ----
        {
          title = "Disk Usage (/dev/sda1) per VM"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"agent.googleapis.com/disk/percent_used\" AND resource.type=\"gce_instance\" AND metric.label.state = \"used\" AND metric.label.device = \"/dev/sda1\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }
            ]
            thresholds = [
              {
                label = "80% Full"
                value = 80
              }
            ]
            yAxis = {
              label = "Disk Usage (%)"
              scale = "LINEAR"
            }
          }
        }

      ]
    }
  })
}