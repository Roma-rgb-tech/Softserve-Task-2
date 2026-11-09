#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

cloud-init status --wait
apt-get update -y
apt-get upgrade -y
apt-get install -y --no-install-recommends curl gpg prometheus prometheus-alertmanager

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

install -m 0644 /tmp/grafana/datasources.yaml /etc/grafana/provisioning/datasources/datasources.yaml
install -m 0644 /tmp/grafana/dashboards.yaml /etc/grafana/provisioning/dashboards/dashboards.yaml
install -d -o grafana -g grafana /var/lib/grafana/dashboards

install -m 0644 /tmp/config.alloy /etc/alloy/config.alloy

systemctl enable prometheus prometheus-alertmanager grafana-server alloy

cloud-init clean --logs
