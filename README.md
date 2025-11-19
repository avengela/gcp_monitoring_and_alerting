# gcp_monitoring_and_alerting
This project is part of an assignment for Project Level Up – Advanced ICT Skills Academy for Women, Topic 7: Monitoring and Alerting for Multi-VM Environment.

# Monitoring and Alerting for Multi-VM Environment
The goal of this project is to set up a central infrastructure monitoring system that detects failures and sends notifications to Cloud Monitoring. 
The project involves creating a test environment in Google Cloud with several virtual machines, 
monitoring their status, and responding to failures through alerts.

## Tools
The following tools are used in this project:

-**Compute Engine**

-**Terraform**

-**Google Cloud Provider**

-**Cloud Monitoring** 

-**Cloud Logging**

-**Alerting Policies**

## Creating the Environment
In this project, a monitoring and alerting system is configured using Terraform.

### [variables.tf](terraform/variables.tf)
The **variables.tf** file contains definitions that are used in other configuration files. 
It includes variables for project ID, region, zone, machine type and alert notification data.

### [main.tf](terraform/main.tf)
The **main.tf** file contains the basic Terraform configuration, 
including the required versions of tools and the configuration of the Google Cloud provider, 
which is used to manage resources in the cloud.

### [network.tf](terraform/network.tf)
The **network.tf** file is responsible for configuring the network in Google Cloud, 
including creating a virtual private network (VPC), 
subnets and firewall rules (rule allowing HTTP access and rule allowing SSH access)

### [compute.tf](terraform/compute.tf)
The **compute.tf** file defines the creation of 3 virtual machines on Google Compute Engine. 
Each virtual machine is launched with a specified size and assigned role. 
Additionally, a stratup script is executed on each machine.

### [startup.sh](terraform/scripts/startup.sh)
The **startup.sh** file is a script that runs when each virtual machine in the project.

***It performs the following tasks:***
-installs nginx, curl and telnet to enable service monitoring and testing the availability of network services on the VM,

-enables and restarts the nginx service, setting it up as a web server to serve the monitoring page,

-creates a simple HTML page,

-writes a simple "OK" message to /var/www/html/healthz, which is used for health checks to ensure the VM is up and running,

-installs Google Cloud Ops Agent by downloading the installation script and executing it,

-configures the Ops Agent by creating necessary configuration files for logging and metric collection, 
specifically forsyslog error, nginx access logs, host metrics.


### [uptime_check.tf](terraform/uptime_check.tf)
The **uptime_check.tf** file configures uptime checks for virtual machines using HTTP. 
It monitors the availability of machines by checking if they respond to HTTP requests every 60 seconds.

### [monitoring_alerts.tf](terraform/monitoring_alerts.tf)
The **monitoring_alerts.tf** file is responsible for configuring alert policies in Google Cloud Monitoring. 
These policies allow for detecting issues with virtual machines and sending immediate notifications (via email) if predefined thresholds are exceeded.

1. **Alert for high CPU utilization**
   
This alert detects when CPU usage on virtual machines exceeds 80% for 5 minutes.

A notification is sent if this threshold is exceeded. 

2. **Alert for high RAM utilization**
   
This alert triggers when RAM usage exceeds 47% for 2 minutes.
In this case, a notification is also sent. 

3. **Alert for failed uptime check**
   
This alert checks if virtual machines are available and responding to HTTP requests.
If a machine fails the availability check for 3 minutes, a notification is triggered.

4. **Alert for syslog error spikes**
   
This policy monitors the logs of virtual machines for "ERROR"-type error in the syslog.
If the numer of errors exceeds 1 within a minute, a notification is generated.

## **Cloud Monitoring Dashboard Configuration (CPU, RAM, uptime)**

The VM Full Monitoring Dashboard provides a centralized view of the key metrics and logs from all virtual machines in the project. It is organized into multiple widgets, each visualizing a different aspect of VM health and performance.

Identified metrics are:
1. **CPU Utilization per Instance**
**Metric**: agent.googleapis.com/cpu/utilization
**Purpose**: Shows how much CPU is actively used per VM.
<img width="607" height="483" alt="image" src="https://github.com/user-attachments/assets/ef5df238-8550-4dd1-9434-1b3cd7eec1f8" />

2. Used Memory % per Instance
**Metric**: agent.googleapis.com/memory/percent_used
**Purpose**: Visualizes the percentage of RAM used on each VM.
<img width="612" height="477" alt="image" src="https://github.com/user-attachments/assets/72189f2e-251b-4e30-9866-d527682e0a64" />

3. VM Uptime Check Status
**Metric**: agent.googleapis.com/memory/percent_used
**Purpose**: Visualizes the percentage of RAM used on each VM.
<img width="597" height="471" alt="image" src="https://github.com/user-attachments/assets/6db3f885-e73c-4406-b741-efc46b6ecfc4" />

5. Syslog Warning Count per VM
**Metric**: agent.googleapis.com/memory/percent_used
**Purpose**: Visualizes the percentage of RAM used on each VM.
<img width="606" height="475" alt="image" src="https://github.com/user-attachments/assets/a05b488b-4d27-4e38-b4d0-f55a40629940" />

6. Syslog Error Count per VM
**Metric**: agent.googleapis.com/memory/percent_used
**Purpose**: Visualizes the percentage of RAM used on each VM.
