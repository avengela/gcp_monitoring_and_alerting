resource "google_project_iam_member" "logging_writer" {
    project = var.project_id
    member = "serviceAccount:${google_service_account.vm_service_account.email}"
    role = "roles/logging.logWriter"
}