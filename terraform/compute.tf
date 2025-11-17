

resource "google_compute_instance" "vm1" {
    count = 3
    name = "vm-${count.index + 1}"
    machine_type = var.machine_type
    zone = var.zone
    tags = ["http-server"]

    service_account {
        email  = "${var.project_number}-compute@developer.gserviceaccount.com"
        scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    }

    boot_disk{
        initialize_params{
            image = "debian-cloud/debian-12"
            size = 12
        }
    }

    network_interface {
        subnetwork = google_compute_subnetwork.subnet.id
        access_config{}
    }

        metadata_startup_script = file("${path.module}/scripts/startup.sh")
}