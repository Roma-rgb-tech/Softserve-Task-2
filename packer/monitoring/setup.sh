#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

cloud-init status --wait
apt-get update -y
apt-get upgrade -y
apt-get install -y --no-install-recommends curl gpg unzip prometheus prometheus-alertmanager

mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
apt-get update -y
apt-get install -y grafana alloy

install -m 0644 /tmp/prometheus/prometheus.yml /etc/prometheus/prometheus.yml
echo 'ARGS="--web.enable-remote-write-receiver --storage.tsdb.retention.time=7d"' > /etc/default/prometheus
promtool check config /etc/prometheus/prometheus.yml

install -m 0644 /tmp/alertmanager/alertmanager.yml /etc/prometheus/alertmanager.yml
amtool check-config /etc/prometheus/alertmanager.yml

install -m 0644 /tmp/config.alloy /etc/alloy/config.alloy

curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
aws --version
rm -rf /tmp/aws /tmp/awscliv2.zip
systemctl enable prometheus prometheus-alertmanager  alloy

cloud-init clean --logs
