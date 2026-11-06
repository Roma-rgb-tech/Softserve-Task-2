#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

cloud-init status --wait
apt-get update -y
apt-get upgrade -y
apt-get install -y curl gpg

mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
apt-get update -y
apt-get install -y alloy
install -m 0644 /tmp/config.alloy /etc/alloy/config.alloy
systemctl enable alloy

cloud-init clean --logs
