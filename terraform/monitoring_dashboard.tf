resource "google_monitoring_dashboard" "vm_full_dashboard" {
  dashboard_json = jsonencode({
    displayName = "VM Full Monitoring Dashboard"

    gridLayout = {
      columns = 2
      widgets = [

        # ---- CPU Utilization per instance ----
        {
          title = "CPU Utilization per instance"
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
          }
        },

        # ---- Used Memory % per instance ----
        {
          title = "Used Memory % per instance"
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
          }
        },

        # ---- VM Uptime Check Status ----
        {
          title = "VM Uptime Check Status"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_FRACTION_TRUE"
                      groupByFields      = ["metric.labels.check_id"]
                    }
                  }
                }
              }
            ]
          }
        },

        # ---- Syslog Warning Count per VM ----
        {
          title = "Syslog Warning Count per VM"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"logging.googleapis.com/user/vm_warning_count\" AND resource.type=\"gce_instance\""
                    aggregation = {
                      alignmentPeriod   = "300s"
                      perSeriesAligner  = "ALIGN_SUM"
                      groupByFields     = ["metadata.system_labels.name"]
                    }
                  }
                }
                plotType = "LINE"
              }
            ]
            yAxis = {
              label = "Warnings"
              scale = "LINEAR"
            }
          }
        },

        # ---- Syslog Error Count per VM ----
        {
          title = "Syslog Error Count per VM"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"logging.googleapis.com/user/vm_error_count\" AND resource.type=\"gce_instance\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["metadata.system_labels.name"]
                    }
                  }
                }
                plotType = "LINE"
              }
            ]
            yAxis = {
              label = "Errors"
              scale = "LINEAR"
            }
          }
        }

      ]
    }
  })
}
