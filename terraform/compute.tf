resource "google_compute_instance" "vm1" {
    count = 3
    name = "vm-${count.index + 1}"
    machine_type = var.machine_type
    zone = var.zone
    tags = ["http-server"]

    boot_disk{
        initialize_params{
            image = "debian-cloud/debian-12"
            size = 12
        }
        kms_key_self_link = google_kms_crypto_key.vm_disk_key.id
    }

    network_interface {
        subnetwork = google_compute_subnetwork.subnet.id
        access_config{}
    }

    service_account {
        email = google_service_account.vm_service_account.email
        scopes = [
            "https://www.googleapis.com/auth/logging.write",
            "https://www.googleapis.com/auth/monitoring.write"
        ]
    }

    metadata_startup_script = file("${path.module}/scripts/startup.sh")
}