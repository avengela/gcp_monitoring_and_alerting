This project is part of an assignment for Project Level Up – Advanced ICT Skills Academy for Women, Topic 7: Monitoring and Alerting for Multi-VM Environment.

# Monitoring and Alerting for Multi-VM Environment
The goal of this project is to set up a central infrastructure monitoring system that detects failures and sends notifications to Cloud Monitoring. 
The project involves creating a test environment in Google Cloud with several virtual machines, 
monitoring their status, and responding to failures through alerts.

### Project visualization added to the startup script as an automatically generated monitoring dashboard accessible through the VM's external IP address:
<img width="1141" height="832" alt="obraz" src="https://github.com/user-attachments/assets/f36322cc-5fd3-45ac-b700-5c39f2977eea" />

## Architecture
```
Terraform
│
├── Network
│     ├── VPC
│     ├── Subnet 10.10.0.0/24
│     └── Firewall
│            ├── allow-http (80)
│            └── allow-ssh (22)
│
├── Compute Engine (3× VM)
│     ├── Debian 12
│     ├── KMS-encrypted disk
│     ├── Service Account
│     └── Startup Script
│            ├── Nginx + /healthz
│            ├── HTML dashboard
│            └── Ops Agent (metrics + logs)
│
├── IAM
│     ├── logging.logWriter
│     ├── monitoring.metricWriter 
│     ├── compute.osLogin 
│     └── compute.osAdminLogin 
│
├── KMS
│     ├── Key Ring: vm-key-ring-1
│     └── Crypto Key: vm-disk-key
│
├── Monitoring
│     ├── Dashboard
│     ├── Uptime Checks (per VM)
│     └── Alert Policies
│           ├── High CPU (>80%)
│           ├── High RAM (>70%)
│           ├── High Disk (>80%)
│           └── Uptime Failed
│
└── Notification Channel
      └── Email → var.email_name
```
      
## Creating the Environment
In this project, a monitoring and alerting system is configured using Terraform.

### [variables.tf](terraform/variables.tf)
The variables.tf file contains definitions of variables that are used in other configuration files. 
It includes variables for the project ID, region, zone, machine type, project number, and alert notification data, including the email address for notifications and the OS login user’s email address.

```bash
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
```

### [main.tf](terraform/main.tf)
The **main.tf** file containsthe key configuration for Terraform, 
including the tool version, Google Cloud provider configuration and resources that need to be created to prepare the environment.

This fragment sets the version requirements for Terraform and the Google Cloud provider:

```bash
terraform {
    required_version = ">= 1.5.0"

    required_providers {
        google = {
            source = "hashicorp/google"
            version = "~> 6.0"
        }
    }
}
```
**Google Cloud Provider**

In this section, configuration data for the Google Cloud provider is specified, such as the project ID, region, and zone, where resources will be created.

```bash
provider "google"{
    project = var.project_id 
    region = var.region
    zone = var.zone
}
```

**Service Account**

A service account is created and assigned to the project. 
This account will be used by the virtual machines to access Google Cloud resources, such as logs and metrics.

```bash
resource "google_service_account" "vm_service_account" {
    account_id = "vm-service-account"
    display_name = "VM Service Account"
    project = var.project_id
}
```
**Enabling KMS API**

This enables the Key Management Service (KMS) API, which allows managing encryption keys in Google Cloud. 
KMS will be used for data encryption, ensuring data security in the cloud.

```bash
resource "google_project_service" "kms_api" {
    project = var.project_id
    service = "cloudkms.googleapis.com"
    disable_on_destroy = false
}
```
**Enabling OS Login**

The OS Login service is enabled, allowing login to virtual machines using IAM credentials, eliminating the need to manage traditional SSH keys.

```bash
resource "google_compute_project_metadata" "oslogin" {
    project = var.project_id

    metadata = {
        enable-oslogin = "TRUE"
    }
}
```

### [network.tf](terraform/network.tf)
The **network.tf** file is responsible for configuring the network in Google Cloud, 
including creating a virtual private network (VPC), subnets and firewall rules (rule allowing HTTP access and rule allowing SSH access)

```bash
resource "google_compute_network" "vpc"{
    name = "vpc-observability"
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

```

### [compute.tf](terraform/compute.tf)
The **compute.tf** file defines the creation of 3 virtual machines on Google Compute Engine. 
Each virtual machine is launched with a specified size and assigned role. 
Additionally, a startup script is executed on each machine.

```bash
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
```

### [startup.sh](terraform/scripts/startup.sh)
The **startup.sh** file is a script that runs on each virtual machine. It installs Nginx, curl, and telnet to allow service monitoring and availability testing. 
It also creates an HTML file for the monitoring page. Additionally, the script installs the Google Cloud Ops agent and configures it to collect metrics and logs.

**System Update and Package Installation**

The script starts by updating the system and installing the necessary packages to monitor the availability of virtual machines. 
The nginx, curl, and telnet packages allow testing network connections and application availability.

```bash
apt-get update -y
apt-get install -y nginx curl telnet

```

**Starting and Configuring Nginx**

This part of the script starts the Nginx service, configures it to start automatically on system boot, and then restarts the service to ensure it is working correctly.

```bash
systemctl enable nginx
systemctl restart nginx
```

**Creating the healthz File**

The healthz file is created and will be used to test the availability of the virtual machine. 
This file is used by monitoring mechanisms to check if the machine is running properly.

```bash
echo "OK" > /var/www/html/healthz
chmod -R 755 /var/www/html
```
**Installing and Configuring Google Cloud Ops Agent**
This part of the script installs the Google Cloud Ops Agent, which is responsible for collecting metrics 
and logs from the virtual machine and sending them to Google Cloud Monitoring and Cloud Logging. 
Then, configuration files are set up to collect metrics (e.g., CPU, memory, disk usage) and logs (e.g., syslog, nginx access).

```bash
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
sudo apt list --installed | grep google-cloud-ops-agent

sudo mkdir -p /etc/google-cloud-ops-agent/config.d

sudo bash -c 'cat << EOF > /etc/google-cloud-ops-agent/config.d/metrics.yaml
---
metrics:
  receivers:
    hostmetrics:
      type: hostmetrics
    service:
      pipelines:
        default_pipeline:
          receivers: [hostmetrics]
EOF'

sudo bash -c 'cat << EOF > /etc/google-cloud-ops-agent/config.d/nginx-logs.yaml
---
logging:
  receivers:
    type: nginx_access
    include_paths:
      - /var/log/nginx/access.log
  service:
    pipelines:
      nginx_pipeline:
        receivers: [nginx_access]
EOF'

sudo bash -c 'cat << EOF > /etc/google-cloud-ops-agent/config.d/syslog-logs.yaml
---
logging:
  receivers:
    syslog_receiver:
      type: files
      include_paths:
        - /var/log/syslog

  processors:
    syslog_parser:
      type: syslog
    
    severity_filter:
      type: severity
      severity_levels: ["CRITICAL", "ERROR", "WARNING"]

  service:
    pipelines:
      default_pipeline:
        receivers: [syslog_receiver]
        processors: [syslog_parser, severity_filter]
EOF'

sudo service google-cloud-ops-agent restart
```

### [iam.tf](terraform/iam.tf)
The **iam.tf** file configures the appropriate IAM permissions for the virtual machine's service account and the OS Login user. 
The virtual machine's service account is granted roles that allow it to write logs and metrics to Google Cloud, 
while the OS Login user is granted access to the virtual machines.

This is essential for allowing the VM's service account to push logs (e.g., nginx, syslog) to Google Cloud Logging. 
This allows us to monitor and troubleshoot our VMs based on their logs:

```bash
resource "google_project_iam_member" "logging_writer" {
    project = var.project_id
    member = "serviceAccount:${google_service_account.vm_service_account.email}"
    role = "roles/logging.logWriter"
}
```

This role ensures the VM can send performance metrics (e.g., CPU, RAM, disk usage) to Google Cloud Monitoring. 
These metrics are crucial for creating dashboards and setting up alert policies to monitor the health and performance of the VM environment:

```bash
resource "google_project_iam_member" "monitoring_metric_writer" {
    project = var.project_id
    member = "serviceAccount:${google_service_account.vm_service_account.email}"
    role = "roles/monitoring.metricWriter"
}
```
These roles enable secure access to the VMs through OS Login. 
The osLogin_user role allows regular users to log in, while the osLogin_admin role provides administrative access. 
This eliminates the need to manage SSH keys manually:

```bash
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
```
### [kms.tf](terraform/kms.tf)
The kms.tf file configures Key Management Service (KMS) in Google Cloud. It creates a Key Ring and Crypto Key, 
which are used for encrypting virtual machine disks. This ensures the security of data stored on the virtual machines.

```bash
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
```

### [monitoring_alerts.tf](terraform/monitoring_alerts.tf)
The **monitoring_alerts.tf** file is responsible for configuring alert policies in Google Cloud Monitoring. 
These policies allow for detecting issues with virtual machines and sending immediate notifications (via email) if predefined thresholds are exceeded.

**Google Monitoring Notification Channel**

Before discussing the specific alerts, it is important to explain the google_monitoring_notification_channel resource. 
This resource configures the notification channel that will be used by alerts to send notifications (e.g., by email).

```bash
resource "google_monitoring_notification_channel" "main_email" {
    display_name = "Main email"
    type = "email"

    labels = {
        email_address = var.email_name
    }
}
```
### Alerts

1. **High CPU Utilization Alert**
   
This alert detects when CPU usage on virtual machines exceeds 80% for 5 minutes. 
A notification is sent when this threshold is exceeded.

```bash
resource "google_monitoring_alert_policy" "high_cpu" {
    display_name = "High CPU on VM instances"
    combiner = "OR"
    enabled = true

    conditions {
        display_name = "CPU > 80% for 5 minutes"

        condition_threshold{
            filter = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\""
            comparison = "COMPARISON_GT"
            threshold_value = 0.8
            duration = "300s"
            
            trigger {
                count = 1
            }
        }
    }
    severity = "WARNING"
    notification_channels = [google_monitoring_notification_channel.main_email.id]
}
```

2. **High RAM Utilization Alert**
   
This alert triggers when RAM usage exceeds 70% for 2 minutes. 
A notification is also sent when this threshold is exceeded.

```bash
resource "google_monitoring_alert_policy" "high_memory" {
    display_name = "High memory usage on VM instances"
    combiner = "OR"
    enabled = true

    conditions {
        display_name = "RAM > 70% for 2 minutes"
        condition_threshold {
            filter = "metric.type=\"agent.googleapis.com/memory/percent_used\" AND resource.type=\"gce_instance\""
            comparison = "COMPARISON_GT"
            threshold_value = 70
            duration = "120s"

            trigger {
                count = 1
            }
        }
    }
    severity = "WARNING"
    notification_channels = [google_monitoring_notification_channel.main_email.id]
}
```

3. **Uptime Check Failed Alert**

This alert checks whether virtual machines are available and responding to HTTP requests.
If a machine fails the availability check for 3 minutes, a notification is triggered.

```bash
resource "google_monitoring_alert_policy" "uptime_failed" {
    display_name = "Uptime check failed"
    combiner = "OR"
    enabled = true

    conditions {
        display_name = "Uptime check failed for 3 minutes"

        condition_threshold {
            filter ="metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"gce_instance\""
            comparison = "COMPARISON_LT"
            threshold_value = 1
            duration = "180s"
        
            trigger {
                count = 1
            }
        }
    }
    severity = "ERROR"
    notification_channels = [google_monitoring_notification_channel.main_email.id]
}
```
4. **High Disk Usage Alert**
   
This alert monitors disk usage on virtual machines and triggers a notification when disk usage exceeds 80%.

```bash
resource "google_monitoring_alert_policy" "disk_full" {
  display_name = "High Disk Usage"
  combiner     = "OR"
  enabled = true

  conditions {
    display_name = "Disk > 80%"
    condition_threshold {
      filter          = "metric.type=\"agent.googleapis.com/disk/percent_used\" AND resource.type=\"gce_instance\" AND metric.label.state = \"used\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 80
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  severity = "WARNING"
  notification_channels = [google_monitoring_notification_channel.main_email.id]
}
```

### [uptime_check.tf](terraform/uptime_check.tf)
The **uptime_check.tf** file configures uptime checks for virtual machines using HTTP. 
It monitors the availability of machines by checking if they respond to HTTP requests every 60 seconds.

```bash
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
        path = "/"
        port = 80
    }

    monitored_resource  { 
        type = "gce_instance"
        labels = {
            project_id = var.project_id
            instance_id = each.value.instance_id
            zone = each.value.zone
        }
    }
}

```

###  [monitoring_dashboard.tf](terraform/monitoring_dashboard.tf)
The monitoring_dashboard.tf file is responsible for creating a custom monitoring dashboard in Cloud Monitoring. 
The dashboard contains widgets to monitor CPU, RAM, machine availability, and disk usage.


This section creates a VM Monitoring Dashboard in Cloud Monitoring with a grid layout of 2 columns. 
The dashboard will display various widgets to monitor the performance and availability of the virtual machines.

```bash
resource "google_monitoring_dashboard" "vm_full_dashboard" {
  dashboard_json = jsonencode({
    displayName = "VM Monitoring Dashboard"

    gridLayout = {
      columns = 2
      widgets = [
``
```

**CPU Utilization per VM Widget**

This widget monitors the CPU utilization per VM. It displays CPU usage (excluding idle time) for each VM over time.

```bash
        {
          title = "CPU Utilization per VM"
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
            thresholds = [
              {
                label = "80% High CPU"
                value = 80
              }
            ]
            yAxis = {
              label = "CPU Usage (%)"
              scale = "LINEAR"
            }
          }
        },
```
**RAM Usage per VM Widget**

This widget displays the RAM usage per VM. It tracks the percentage of RAM used on each VM. 

```bash
        {
          title = "RAM Usage per VM"
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
            thresholds = [
              {
                label = "70% High RAM"
                value = 70
              }
            ]
            yAxis = {
              label = "RAM Usage (%)"
              scale = "LINEAR"
            }
          }
        },
```
**Uptime Check Status per VM Widget**

This widget monitors the uptime check status per VM. It tracks whether the VM is responding to the health check.

```bash
        {
          title = "Uptime Check Status per VM"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\""
                    aggregation = {
                      alignmentPeriod  = "300s"
                      perSeriesAligner = "ALIGN_FRACTION_TRUE"
                      groupByFields    = ["metric.labels.check_id"]
                    }
                  }
                }
              }
            ]
            thresholds = [
              {
                label = "Fail Threshold"
                value = 0
              }
            ]
            yAxis = {
              label = "Check Passed (1=OK, 0=Fail)"
              scale = "LINEAR"
            }
          }
        },
```
**Disk Usage per VM Widget**

This widget monitors the disk usage per VM for the /dev/sda1 partition. It tracks how much of the disk space is udes on each VM. 

```bash
        {
          title = "Disk Usage (/dev/sda1) per VM"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"agent.googleapis.com/disk/percent_used\" AND resource.type=\"gce_instance\" AND metric.label.state = \"used\" AND metric.label.device = \"/dev/sda1\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }
            ]
            thresholds = [
              {
                label = "80% Full"
                value = 80
              }
            ]
            yAxis = {
              label = "Disk Usage (%)"
              scale = "LINEAR"
            }
          }
        }

      ]
    }
  })
}
```

## **Cloud Monitoring Dashboard Configuration (CPU, RAM, uptime)**

The VM Monitoring Dashboard provides a centralized view of the key metrics and logs from all virtual machines in the project. It is organized into multiple widgets, each visualizing a different aspect of VM health and performance.

### Identified metrics are:

**1. CPU Utilization per VM**
<br>**Metric**: agent.googleapis.com/cpu/utilization
<br>**Purpose**: Shows how much CPU is actively used per VM, excluding idle CPU.
<br>**Threshold**: 80% CPU usage triggers high alert.
<br><br><img width="600" alt="image" src="https://github.com/user-attachments/assets/b38e0bf7-f5e2-4188-8b8f-be760b526575" />

**2. RAM Usage per VM**
<br>**Metric**: agent.googleapis.com/memory/percent_used
<br>**Purpose**: Visualizes the percentage of RAM used on each VM. Only used memory is considered.
<br>**Threshold**: 70% RAM usage triggers high alert.
<br><br><img width="1117" height="469" alt="image" src="https://github.com/user-attachments/assets/7ccbe8ad-0f91-4bf0-8b5e-a1b2432fb420" />

**3. VM Uptime Check Status**
<br>**Metric**: monitoring.googleapis.com/uptime_check/check_passed
<br>**Purpose**: Shows the result of uptime checks per VM (1 = OK, 0 = Fail).
<br>**Threshold**: 0 indicates failed uptime check.
<br><br><img width="1133" height="474" alt="image" src="https://github.com/user-attachments/assets/56936430-b289-45c7-b935-9c29e5d4b55a" />

**4. Disk Usage (/dev/sda1) per VM**
<br>**Metric**: agent.googleapis.com/disk/percent_used
<br>**Purpose**: Visualizes the percentage of disk usage for the main system disk /dev/sda1 per VM. Only used space is considered.
<br>**Threshold**: 80% disk usage triggers high alert.
<br><br><img width="1128" height="474" alt="image" src="https://github.com/user-attachments/assets/3f0aa34e-4523-4a46-9e1d-3f30e45b301a" />

## **Conduct a failure test and observe system response**
The goal is to verify that monitoring and alerting work correctly to ensure that the user is well informed about important issues with the VM.

**1. High CPU utilization Test**
<br>**Test execution**: 
<br>Running the following commands on the two VMs:
```bash
sudo apt update
sudo apt install stress -y
```
<br>VM1: 
```bash
stress --cpu 4 --timeout 400s
```
<br>VM2: 
```bash
stress --cpu 6 --timeout 400s
```

<br>**Result on dashboard**: 
<br>CPU usage spikes are visible on VM1 and VM2. Both VMs exceed the threshold and would trigger a high CPU alert if the spike persists for 5 minutes.The previous attempt did not trigger an alert because the spike lasted only 4 minutes instead of the expected 5.
<br><br><img width="1122" height="470" alt="image" src="https://github.com/user-attachments/assets/fde5fea7-8474-42dd-980c-5ef3e1491044" />
<br><br>After the spike, the email alert appeared on the dashboard.
<br><br><img width="1228" height="561" alt="Screenshot 2025-11-20 211328" src="https://github.com/user-attachments/assets/4e91c6b8-95d7-4dda-a4c9-cb3571764db1" />

<br>**Received email**: 
<br>Notification email received indicating high CPU usage on the affected VMs. Severity warning as per code expectations.

<br><br><img width="500" alt="image" src="https://github.com/user-attachments/assets/81ffb586-51d8-4408-bf91-9bc0da824a44" />
<br><br><img width="500" alt="image" src="https://github.com/user-attachments/assets/4f2e4358-b2a4-425c-9b9c-9d9ff05d32a3" />


After the stress test ended, the alert cleared and a recovery notification was sent to the configured email.
<br><br><img width="500" alt="image" src="https://github.com/user-attachments/assets/24eacb2c-660a-4437-ab47-6a7f14d8b8e2" />
<br><br><img width="500" alt="image" src="https://github.com/user-attachments/assets/1e5dcc38-6cb4-4cf6-8a0f-97197e551190" />



**2. High RAM utilization test**

<br>**Test execution**: 
<br>Running the following commands on VM2:
```bash
python3 - <<EOF
import time
import os

target_mb = 500  
chunk_size = 10  
chunks = []

allocated = 0
while allocated < target_mb:
    try:
        chunks.append(' ' * (chunk_size * 1024 * 1024))
        allocated += chunk_size
        print(f"Allocated {allocated} MB RAM")
        time.sleep(2) 
    except MemoryError:
        print("MemoryError: Cannot allocate more RAM")
        break

print(f"Holding {allocated} MB RAM for 300s (5 min)...")
time.sleep(300)
EOF
```

<br>**Result on dashboard**: 
<br>RAM usage spikes are visible on VM2. The RAM usage spike triggered the alert and is visible on the dashboard.
<br><br><img width="1154" height="555" alt="image" src="https://github.com/user-attachments/assets/0dec5c8c-6feb-41dc-990a-9107f39e7c66" />


<br>**Received emails**: 
<br>A notification email was received indicating high RAM utilization on the affected VM.
<br><br><img width="500" alt="image" src="https://github.com/user-attachments/assets/c6881c1a-b3eb-4d76-a7f6-7b9079c87c49" />
<br><br>Shortly after, a recovery alert was sent.
<br><br><img width="500" alt="image" src="https://github.com/user-attachments/assets/604c19c9-0ed8-4269-b00f-f626502295e6" />


**3. Failed uptime check test**
<br>**Test execution**: 
<br>VM3 was manually stopped in the VM Instances to test the solution. After alerts were received, the VM was restarted.

<br>**Result on dashboard**: 
<br>After 1 minute, the dashboard started showing issues with VM3.
<br><br><img width="1048" height="826" alt="image" src="https://github.com/user-attachments/assets/0804c19e-c76d-40bc-b28a-0ad1ca574510" />
<br><br>Recovery occurred after restarting the VM.
<br><br><img width="810" height="475" alt="image" src="https://github.com/user-attachments/assets/0fb7cbc1-859e-44d8-9c25-0ac4dbbaece2" />

<br>**Received emails**: 
<br>I received 6 emails from different pods reporting the issue. This time the issue has severity of an error as visible on the screenshot.
<br><br><img width="500" alt="image" src="https://github.com/user-attachments/assets/b90b72a5-dfc7-4603-ac94-7e388492b29b" />

<br><br>A successful recovery email was sent a few minutes later.
<br><br><img width="500" alt="image" src="https://github.com/user-attachments/assets/361ecc54-9d97-489c-ba78-53be98237c41" />



**4. High disk usage test**

<br>**Test execution**: 
<br>Running the following commands on VM1:
```bash
fallocate -l 8G /tmp/testfile1
```

<br>**Result on dashboard**:
<br>A visible spike in disk usage appeared on the dashboard at the time of code execution. For this alert to be triggered, the disk usage must exceed the threshold for at least 1 minute.
<br><br><img width="1139" height="480" alt="image" src="https://github.com/user-attachments/assets/034a65db-0669-4a9e-a2ab-9bb53f341fe0" />
<br><br>Disk usage decreased to normal levels after the test file was removed.
<br><br><img width="1153" height="612" alt="image" src="https://github.com/user-attachments/assets/56ff4620-8834-4367-80d2-0bb92741400b" />



<br>**Received emails**:
<br>A notification email was received indicating high disk usage on the affected VM.
<br><br><img width="500" alt="image" src="https://github.com/user-attachments/assets/689a07b6-d52f-4448-8f79-a017307e9908" />

<br>Shortly after, a recovery alert was sent once the test file was removed and disk usage dropped below the threshold.
<br><br><img width="500" alt="image" src="https://github.com/user-attachments/assets/f99bf07f-c03d-4b73-bf1c-6ea8c821871e" />


