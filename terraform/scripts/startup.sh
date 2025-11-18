#!/usr/bin/env bash
set -euxo pipefail

apt-get update -y
apt-get install -y nginx curl telnet

systemctl enable nginx
systemctl restart nginx


HOSTNAME=$(hostname)
sudo tee /var/www/html/index.html << EOF
<!DOCTYPE html> 
<html> 
<head>
<title>Monitoring and Alerting for Multi-VM Environment</title>
<style>
body {
background-color: #f1f1f1;
font-family: Arial, sans-serif;
margin: 0;
padding: 0;
text-align: center;
}
.container {
width: 80%;
margin: 0 auto;
padding: 20px;
background-color: #ffffff;
border-radius: 8px;
box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
}
h1 {
color: #333;
}
.section {
margin-bottom: 30px;
}
.section p {
font-size: 18px;
color: #555;
}
.alert {
background-color: #ffdddd;
padding: 10px;
color: red;
border-radius: 5px;
font-weight: bold;
}
.status {
font-size: 20px;
font-weight: bold;
}
.ok {
color: green;
}
.error {
color: red;
}
.healthz {
margin-top: 20px;
font-size: 16px;
color: #777;
}
canvas {
max-width: 100%;
height: auto;
margin-top: 20px;
}
</style>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
<div class="container">
<h1>Monitoring and Alerting for Multi-VM Environment</h1>
<div class="section">
<p><strong>VM Hostname:</strong> $HOSTNAME</p>
<p><strong>VM IP Address:</strong> $(hostname -I)</p>
<p><strong>Application Version:</strong> V1</p>
<p>Project: LevelUp</p>
</div>
<!-- Project Introduction -->
<div class="section">
<h2>Project Introduction</h2>
<p>
The goal of this project is to establish a centralized monitoring system for cloud infrastructure that detects performance issues and sends notifications to Cloud Monitoring when predefined thresholds are exceeded. 
It involves setting up a testing environment in Google Cloud with multiple virtual machines, monitoring their status, and responding to failures via alert policies.
</p>
<p>
This system monitors resource utilization metrics, including CPU and RAM, and checks the uptime of virtual machines. Alerts are triggered when these metrics exceed set thresholds, ensuring that any issues are detected early and can be addressed immediately.
</p>
</div>
<!-- CPU Alert Section -->
<div class="section">
<h2>CPU Usage Monitoring</h2>
<p class="alert">Alert: CPU usage exceeds 80% for 5 minutes!</p>
<!-- CPU Chart -->
<canvas id="cpuChart"></canvas>
</div>
<!-- RAM Alert Section -->
<div class="section">
<h2>RAM Usage Monitoring</h2>
<p class="alert">Alert: RAM usage exceeds 70% for 2 minutes!</p>
<!-- RAM Chart -->
<canvas id="ramChart"></canvas>
</div>
<!-- Uptime Check -->
<div class="section">
<h2>Uptime Monitoring</h2>
<p><strong>Uptime Status:</strong> <span class="status uptime-status">OK</span></p>
<p>Last Uptime Check: 60 seconds ago</p>
<p class="alert">Alert: VM is down for more than 3 minutes!</p>
</div>
<!-- Syslog Errors -->
<div class="section">
<h2>Syslog Error Monitoring</h2>
<p><strong>Recent Syslog Errors:</strong> <span class="status syslog-errors">2</span></p>
<p class="alert">Alert: Syslog errors exceed threshold!</p>
</div>
<!-- Health Check -->
<div class="healthz">
<p>Status: <strong class="ok">OK</strong></p>
</div>
</div>
<script>
const ctx1 = document.getElementById('cpuChart').getContext('2d');
const cpuChart = new Chart(ctx1, {
type: 'bar',
data: {
labels: ['CPU Usage'],
datasets: [{
label: 'CPU Usage (%)',
data: [80], // Example CPU usage, can be dynamically updated
backgroundColor: ['rgba(255, 99, 132, 0.2)'],
borderColor: ['rgba(255, 99, 132, 1)'],
borderWidth: 1
}]
},
options: {
scales: {
y: {
beginAtZero: true,
max: 100
}
}
}
});
const ctx2 = document.getElementById('ramChart').getContext('2d');
const ramChart = new Chart(ctx2, {
type: 'bar',
data: {
labels: ['RAM Usage'],
datasets: [{
label: 'RAM Usage (%)',
data: [70], // Example RAM usage, can be dynamically updated
backgroundColor: ['rgba(54, 162, 235, 0.2)'],
borderColor: ['rgba(54, 162, 235, 1)'],
borderWidth: 1
}]
},
options: {
scales: {
y: {
beginAtZero: true,
max: 100
}
}
}
});
</script>
</body>
</html>
EOF

echo "OK" > /var/www/html/healthz
chmod -R 755 /var/www/html

echo "OK" > /var/www/html/healthz
chmod -R 755 /var/www/html

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
sudo apt list --installed | grep google-cloud-ops-agent

sudo mkdir -p /etc/google-cloud-ops-agent/config.d
sudo bash -c 'cat << EOF > /etc/google-cloud-ops-agent/config.d/syslog-errors.yaml
---
logging:
  receivers:
    syslog:
      type: files
      include_paths:
        - /var/log/syslog
  processors:
    severity_filter:
      type: severity
      severity_levels: ["ERROR", "CRITICAL", "WARNING"]

  service:
    pipelines:
      default_pipeline:
        receivers: [syslog]
        processors: [severity_filter]

metrics:
  receivers:
    hostmetrics:
      type: hostmetrics
  service:
    pipelines:
      default_pipeline:
        receivers: [hostmetrics]
EOF'

sudo bash -c 'cat << EOF > /etc/google-cloud-ops-agent/config.yaml
---
logging:
  receivers:
    nginx_access:
      type: nginx_access
      include_paths: 
        - /var/log/nginx/access.log
  service:
    pipelines:
      nginx_pipeline:
        receivers: [nginx_access]

metrics:
  receivers:
    hostmetrics:
      type: hostmetrics
  service:
    pipelines:
      default_pipeline:
        receivers: [hostmetrics]
EOF'

sudo service google-cloud-ops-agent restart
