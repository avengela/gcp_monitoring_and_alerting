#!/usr/bin/env bash
set -euxo pipefail

apt-get update -y
apt-get install -y nginx curl telnet

systemctl enable nginx
systemctl restart nginx

HOSTNAME=$(hostname)
sudo tee /var/www/html/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Monitoring & Alerting – Multi-VM GCP Environment</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
body {
margin: 0;
font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
background: #020617;
color: #e5e7eb;
display: flex;
justify-content: center;
padding: 24px;
}
.page {
width: 100%;
max-width: 1100px;
}
.shell {
background: radial-gradient(circle at top, #1f2937 0, #020617 55%);
border-radius: 20px;
padding: 20px;
border: 1px solid rgba(148, 163, 184, 0.3);
box-shadow: 0 20px 40px rgba(15, 23, 42, 0.9);
}
.header {
display: flex;
justify-content: space-between;
gap: 16px;
align-items: center;
margin-bottom: 20px;
}
.title {
font-size: 24px;
font-weight: 700;
letter-spacing: 0.04em;
}
.subtitle {
font-size: 13px;
color: #9ca3af;
}
.vm {
border-radius: 999px;
border: 1px solid rgba(148, 163, 184, 0.4);
padding: 8px 12px;
font-size: 12px;
background: rgba(15, 23, 42, 0.9);
min-width: 220px;
}
.vm-label {
font-size: 10px;
text-transform: uppercase;
letter-spacing: 0.16em;
color: #9ca3af;
}
.vm-main {
font-size: 13px;
}
.vm-detail {
font-size: 11px;
color: #9ca3af;
}
.grid {
display: grid;
grid-template-columns: repeat(2, minmax(0, 1fr));
gap: 16px;
margin-bottom: 16px;
}
@media (max-width: 900px) {
.grid {
grid-template-columns: minmax(0, 1fr);
}
.header {
flex-direction: column;
align-items: flex-start;
}
.shell {
padding: 16px;
}
}
.card {
background: rgba(15, 23, 42, 0.96);
border-radius: 16px;
padding: 14px 16px;
border: 1px solid rgba(148, 163, 184, 0.4);
box-shadow: 0 12px 30px rgba(15, 23, 42, 0.8);
}
.card-header {
display: flex;
justify-content: space-between;
align-items: baseline;
margin-bottom: 8px;
}
.card-title {
text-transform: uppercase;
font-size: 13px;
letter-spacing: 0.12em;
color: #9ca3af;
}
.tag {
font-size: 11px;
border-radius: 999px;
border: 1px solid rgba(148, 163, 184, 0.5);
padding: 3px 9px;
color: #38bdf8;
background: rgba(15, 23, 42, 0.9);
}
.card-body {
font-size: 13px;
}
.list {
margin-top: 8px;
padding-left: 18px;
color: #9ca3af;
font-size: 13px;
}
.highlight {
margin-top: 10px;
font-size: 12px;
padding: 8px 10px;
border-radius: 10px;
background: rgba(15, 23, 42, 0.9);
border: 1px dashed rgba(148, 163, 184, 0.6);
color: #9ca3af;
}
.pills {
display: flex;
flex-wrap: wrap;
gap: 8px;
margin-top: 8px;
}
.pill {
font-size: 11px;
border-radius: 999px;
border: 1px solid rgba(148, 163, 184, 0.4);
padding: 4px 8px;
background: rgba(15, 23, 42, 0.9);
color: #9ca3af;
}
.stats {
display: grid;
grid-template-columns: repeat(2, minmax(0, 1fr));
gap: 10px;
margin-bottom: 8px;
}
.stat {
border-radius: 12px;
border: 1px solid rgba(148, 163, 184, 0.4);
padding: 8px 10px;
background: rgba(15, 23, 42, 0.98);
font-size: 12px;
}
.stat-label {
font-size: 10px;
color: #9ca3af;
text-transform: uppercase;
letter-spacing: 0.14em;
margin-bottom: 2px;
}
.stat-main {
font-size: 14px;
font-weight: 600;
}
.ok {
color: #4ade80;
}
.err {
color: #f97373;
}
.th {
font-size: 11px;
color: #9ca3af;
margin-top: 4px;
}
.health {
display: flex;
justify-content: space-between;
gap: 10px;
align-items: center;
margin-top: 4px;
}
.health-right {
font-size: 12px;
color: #9ca3af;
}
canvas {
width: 100%;
max-height: 210px;
}
.note {
margin-top: 8px;
font-size: 11px;
color: #9ca3af;
}
.note code {
padding: 2px 5px;
border-radius: 6px;
background: rgba(15, 23, 42, 0.9);
border: 1px solid rgba(148, 163, 184, 0.5);
font-size: 11px;
}
</style>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
<main class="page">
<section class="shell">
<header class="header">
<div>
<div class="title">Monitoring &amp; Alerting Dashboard</div>
<p class="subtitle">Multi-VM environment for the <strong>LevelUp</strong> GCP monitoring project.</p>
</div>
<aside class="vm">
<div class="vm-label">Current VM</div>
<div class="vm-main"><strong>$HOSTNAME</strong></div>
<div class="vm-detail">IP: $(hostname -I) · GCE instance</div>
</aside>
</header>
<section class="grid">
<article class="card">
<div class="card-header">
<h2 class="card-title">Project overview</h2>
<span class="tag">GCP · Monitoring</span>
</div>
<div class="card-body">
<p>This VM is part of a demo environment for <strong>centralized monitoring and alerting</strong> in Google Cloud. Metrics and logs from multiple instances are used to detect issues early and notify on-call engineers.</p>
<ul class="list">
<li>CPU, RAM and <strong>disk usage</strong> are continuously monitored.</li>
<li>Availability is tracked with <strong>uptime checks</strong> against a health endpoint.</li>
</ul>
<div class="highlight">Google Cloud Ops Agent on this VM sends host metrics and logs to Cloud Monitoring, where alerting policies are defined (CPU, memory, disk and uptime alerts).</div>
<div class="pills">
<span class="pill"><strong>Stack:</strong> GCE · Nginx · Ops Agent</span>
<span class="pill"><strong>Metrics:</strong> CPU · RAM · Disk · Uptime</span>
<span class="pill"><strong>Logs:</strong> Syslog · Nginx access</span>
</div>
</div>
</article>
<article class="card">
<div class="card-header">
<h2 class="card-title">Live VM status</h2>
<span class="tag">Health check: /healthz</span>
</div>
<div class="card-body">
<div class="stats">
<div class="stat">
<div class="stat-label">Uptime status</div>
<div class="stat-main"><span class="ok">OK</span></div>
<div class="th">Last successful uptime check: <strong>60s</strong> ago.</div>
</div>
<div class="stat">
<div class="stat-label">Disk usage (root filesystem)</div>
<div class="stat-main"><span class="ok">72% used</span></div>
<div class="th">Example disk alert when usage exceeds <strong>80%</strong> for <strong>60 seconds</strong>.</div>
</div>
</div>
<div class="health">
<div>
<div class="stat-label">Service health</div>
<div class="stat-main"><span class="ok">Nginx responding on port 80</span></div>
</div>
<div class="health-right">Health endpoint: <code>/healthz</code></div>
</div>
<p class="note">This instance is one of several VMs. When any VM fails or crosses thresholds, <code>Cloud Monitoring</code> triggers alerts through configured notification channels.</p>
</div>
</article>
</section>
<section class="grid">
<article class="card">
<div class="card-header">
<h2 class="card-title">CPU usage</h2>
<span class="tag">Alert &gt; 80% for 5 min</span>
</div>
<div class="card-body">
<canvas id="cpuChart"></canvas>
<p class="th">Example CPU utilization over the last 10 minutes for this VM. In the real setup, this visual represents data coming from Cloud Monitoring.</p>
</div>
</article>
<article class="card">
<div class="card-header">
<h2 class="card-title">RAM usage</h2>
<span class="tag">Alert &gt; 70% for 2 min</span>
</div>
<div class="card-body">
<canvas id="ramChart"></canvas>
<p class="th">Example RAM usage trend. Crossing the threshold for a sustained period fires a memory pressure alert.</p>
</div>
</article>
</section>
</section>
</main>
<script>
const labels = ["-9m","-8m","-7m","-6m","-5m","-4m","-3m","-2m","-1m","now"];
const cpuData = [22,35,30,45,58,63,79,88,84,76];
const ramData = [48,51,55,60,64,67,70,72,69,66];
const cpuThreshold = 80;
const ramThreshold = 70;
const baseOptions = {
responsive: true,
maintainAspectRatio: false,
scales: {
y: {
beginAtZero: true,
max: 100,
ticks: {
color: "#9ca3af",
font: { size: 10 }
},
grid: {
color: "rgba(148,163,184,.25)"
}
},
x: {
ticks: {
color: "#9ca3af",
font: { size: 10 }
},
grid: {
display: false
}
}
},
plugins: {
legend: {
labels: {
color: "#e5e7eb",
font: { size: 11 }
}
}
}
};
const cpuCtx = document.getElementById("cpuChart").getContext("2d");
new Chart(cpuCtx, {
type: "line",
data: {
labels: labels,
datasets: [
{
label: "CPU usage (%)",
data: cpuData,
borderWidth: 2,
tension: 0.35
},
{
label: "Alert threshold (80%)",
data: labels.map(() => cpuThreshold),
borderWidth: 1,
borderDash: [5,4]
}
]
},
options: baseOptions
});
const ramCtx = document.getElementById("ramChart").getContext("2d");
new Chart(ramCtx, {
type: "line",
data: {
labels: labels,
datasets: [
{
label: "RAM usage (%)",
data: ramData,
borderWidth: 2,
tension: 0.35
},
{
label: "Alert threshold (70%)",
data: labels.map(() => ramThreshold),
borderWidth: 1,
borderDash: [5,4]
}
]
},
options: baseOptions
});
</script>
</body>
</html>
EOF

echo "OK" > /var/www/html/healthz
chmod -R 755 /var/www/html

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