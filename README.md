<img width="1132" height="475" alt="image" src="https://github.com/user-attachments/assets/69b2850a-6a15-4a3b-b79f-cd3fd5e667db" /># gcp_monitoring_and_alerting
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
   
This policy monitors the disk usage of virtual machines.
If the percentage of used space on any disk exceeds 80% for at least 1 minute, a notification is sent to the configured channel.
It helps prevent issues caused by disks filling up, such as application failures or system crashes.

4. **Alert for high disk usage**
   
This policy monitors the logs of virtual machines for "ERROR"-type error in the syslog.
If the numer of errors exceeds 1 within a minute, a notification is generated.

## **Cloud Monitoring Dashboard Configuration (CPU, RAM, uptime)**

The VM Monitoring Dashboard provides a centralized view of the key metrics and logs from all virtual machines in the project. It is organized into multiple widgets, each visualizing a different aspect of VM health and performance.

### Identified metrics are:

**1. CPU Utilization per VM**
<br>**Metric**: agent.googleapis.com/cpu/utilization
<br>**Purpose**: Shows how much CPU is actively used per VM, excluding idle CPU.
<br>**Threshold**: 80% CPU usage triggers high alert.
<br><br><img width="1132" height="475" alt="image" src="https://github.com/user-attachments/assets/b38e0bf7-f5e2-4188-8b8f-be760b526575" />

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

<br><br><img width="704" height="644" alt="image" src="https://github.com/user-attachments/assets/81ffb586-51d8-4408-bf91-9bc0da824a44" />
<br><br><img width="735" height="655" alt="image" src="https://github.com/user-attachments/assets/4f2e4358-b2a4-425c-9b9c-9d9ff05d32a3" />


After the stress test ended, the alert cleared and a recovery notification was sent to the configured email.
<br><br><img width="742" height="623" alt="image" src="https://github.com/user-attachments/assets/24eacb2c-660a-4437-ab47-6a7f14d8b8e2" />
<br><br><img width="694" height="642" alt="image" src="https://github.com/user-attachments/assets/1e5dcc38-6cb4-4cf6-8a0f-97197e551190" />



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
<br><br><img width="682" height="643" alt="image" src="https://github.com/user-attachments/assets/c6881c1a-b3eb-4d76-a7f6-7b9079c87c49" />
<br><br>Shortly after, a recovery alert was sent.
<br><br><img width="721" height="634" alt="image" src="https://github.com/user-attachments/assets/604c19c9-0ed8-4269-b00f-f626502295e6" />


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
<br><br><img width="738" height="654" alt="image" src="https://github.com/user-attachments/assets/b90b72a5-dfc7-4603-ac94-7e388492b29b" />

<br><br>A successful recovery email was sent a few minutes later.
<br><br><img width="701" height="679" alt="image" src="https://github.com/user-attachments/assets/361ecc54-9d97-489c-ba78-53be98237c41" />



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
<br><br><img width="1138" height="493" alt="image" src="https://github.com/user-attachments/assets/48f8f8c0-217e-47b2-aa79-36243834ab38" />


<br>**Received emails**:
<br>A notification email was received indicating high disk usage on the affected VM.
<br><br><img width="681" height="643" alt="image" src="https://github.com/user-attachments/assets/689a07b6-d52f-4448-8f79-a017307e9908" />

<br>Shortly after, a recovery alert was sent once the test file was removed and disk usage dropped below the threshold.
<br><br><img width="729" height="610" alt="image" src="https://github.com/user-attachments/assets/f99bf07f-c03d-4b73-bf1c-6ea8c821871e" />


