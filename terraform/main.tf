terraform {
    required_version = ">= 1.5.0"

    required_providers {
        google = {
            source = "hashicorp/google"
            version = "~> 6.0"
        }
    }
}

provider "google"{
    project = var.project_id 
    region = var.region
    zone = var.zone
}

resource "google_service_account" "vm_service_account" {
    account_id = "vm-service-account"
    display_name = "VM Service Account"
    project = var.project_id
}