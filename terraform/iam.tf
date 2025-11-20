resource "google_project_iam_member" "logging_writer" {
    project = var.project_id
    member = "serviceAccount:${google_service_account.vm_service_account.email}"
    role = "roles/logging.logWriter"
}

resource "google_project_iam_member" "monitoring_metric_writer" {
    project = var.project_id
    member = "serviceAccount:${google_service_account.vm_service_account.email}"
    role = "roles/monitoring.metricWriter"
}

resource "google_project_iam_member" "oslogin_user" {
    project = var.project_id
    member = "user:${var.oslogin_user_email}"
    role = "roles/compute.osLogin"
}

resource "google_project_iam_member" "oslogin_admin" {
    project = var.project_id
    member = "user:${var.oslogin_user_email}"
    role = "roles/compute.osAdminLogin"
}
