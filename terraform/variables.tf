variable "project_id" {
    description = "Google Cloud project ID"
    type = string
    default = "your-project-Id"
}

variable "region"{
    description = "GCE region"
    type = string
    default = "your-region"
}

variable "machine_type"{
    description = "GCE machine type"
    type = string
    default = "your-vm-machine-type"
}

variable "zone"{
    description ="GCE zone"
    type =string
    default = "your-vm-zone"
}

variable "project_number"{
    type = string
    default = "your-project-number"
}

variable "email_name"{
    type = string
    default = "your-email-alert"
}

variable "oslogin_user_email" {
    description = "oslogin email"
    type = string
    default = "your-oslogin-user-email"
}
