locals {
    vm_instances = {
        for idx, vm in google_compute_instance.vm1 : 
        vm.name => {
            instance_id = vm.instance_id
            zone = vm.zone
        }
    }
}

resource "google_monitoring_uptime_check_config" "http_check" {
    for_each = local.vm_instances

    display_name = "HTTP check - ${each.key}"
    timeout = "10s"
    period = "60s"

    http_check {
        path ="/"
        port = 80
    }

    monitored_resource  { 
        type = "gce_instance"
        labels = {
            project_id = var.project_id
            instance_id=each.value.instance_id
            zone = each.value.zone
        }
    }
}