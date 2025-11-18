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
<body style='background-color:rgb(250, 210, 210);'> 
<h1>Monitoring and Alerting for Multi-VM Environment  </h1> 
<p><strong>VM Hostname:</strong> $HOSTNAME</p> 
<p><strong>VM IP Address:</strong> $(hostname -I)</p> 
<p><strong>Application Version:</strong> V1</p> 
<p> Project LevelUp</p> 
</body>
</html>
EOF

echo "OK" > /var/www/html/healthz
chmod -R 755 /var/www/html

touch b
echo "OK" > /var/www/html/healthz
chmod -R 755 /var/www/html

touch c

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
sudo apt list --installed | grep google-cloud-ops-agent

touch d

cat /var/www/html/index.html > 2.txt

sudo mkdir -p /etc/google-cloud-ops-agent/config.d
touch e
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
      severity_levels: ["ERROR"]

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

cat /var/www/html/index.html > 3.txt
touch f

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
touch g

cat /var/www/html/index.html > 4.txt

sudo service google-cloud-ops-agent restart
touch h
