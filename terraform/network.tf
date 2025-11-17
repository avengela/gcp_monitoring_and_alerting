resource "google_compute_network" "vpc"{
    name = "vpc-observability-2"
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
    name = "subnet1"
    region = var.region
    network = google_compute_network.vpc.id
    ip_cidr_range = "10.10.0.0/24"
}

resource "google_compute_firewall" "allow_http"{
    name = "allow-http"
    network =google_compute_network.vpc.name

    allow {
        protocol = "tcp"
        ports = ["80"]
    }

    source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_ssh" {
    name = "allow-ssh"
    network = google_compute_network.vpc.name

    allow {
        protocol = "tcp"
        ports = ["22"]
    }
    source_ranges = ["0.0.0.0/0"]
}
