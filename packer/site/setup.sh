#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

cloud-init status --wait
apt-get update -y
apt-get upgrade -y
apt-get install -y --no-install-recommends curl gpg nginx

install -d -m 0755 /var/www/site
install -m 0644 /tmp/index.html /var/www/site/index.html
install -m 0644 /tmp/site.conf /etc/nginx/sites-available/site
ln -sf /etc/nginx/sites-available/site /etc/nginx/sites-enabled/site
rm -f /etc/nginx/sites-enabled/default
nginx -t

mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
apt-get update -y
apt-get install -y alloy
install -m 0644 /tmp/config.alloy /etc/alloy/config.alloy
alloy fmt /etc/alloy/config.alloy > /dev/null

systemctl enable nginx alloy

cloud-init clean --logs
