resource "google_kms_key_ring" "vm_key_ring" {
    name = "vm-key-ring-1"
    location = var.region

    depends_on = [google_project_service.kms_api]
}

resource "google_kms_crypto_key" "vm_disk_key" {
    name = "vm-disk-key"
    key_ring = google_kms_key_ring.vm_key_ring.id
    rotation_period = "2592000s"
}

resource "google_kms_crypto_key_iam_member" "vm_sa_kms_user" {
    crypto_key_id = google_kms_crypto_key.vm_disk_key.id
    role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    member = "serviceAccount:service-${var.project_number}@compute-system.iam.gserviceaccount.com"
}