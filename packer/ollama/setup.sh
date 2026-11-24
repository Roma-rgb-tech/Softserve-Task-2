#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

cloud-init status --wait
apt-get update -y
apt-get upgrade -y
apt-get install -y curl gpg postgresql-client nginx prometheus-nginx-exporter

fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

curl -fsSL --retry 5 --retry-delay 15 --retry-all-errors https://ollama.com/install.sh | sh
mkdir -p /etc/systemd/system/ollama.service.d
printf '[Service]\nEnvironment="OLLAMA_HOST=127.0.0.1:11435"\nEnvironment="OLLAMA_KEEP_ALIVE=-1"\n' > /etc/systemd/system/ollama.service.d/override.conf
systemctl daemon-reload
systemctl enable ollama
systemctl restart ollama
until curl -fs http://127.0.0.1:11435 > /dev/null; do sleep 2; done
HOME=/root OLLAMA_HOST=127.0.0.1:11435 ollama pull qwen2.5:3b
HOME=/root OLLAMA_HOST=127.0.0.1:11435 ollama list | grep qwen2.5:3b

rm -f /etc/nginx/sites-enabled/default
install -m 0644 /tmp/nginx.conf /etc/nginx/conf.d/ollama.conf
nginx -t
systemctl disable nginx
systemctl restart nginx
until curl -fs http://127.0.0.1:11434 > /dev/null; do sleep 2; done

echo 'ARGS="--nginx.scrape-uri=http://127.0.0.1:8080/stub_status"' > /etc/default/prometheus-nginx-exporter
systemctl enable prometheus-nginx-exporter
systemctl restart prometheus-nginx-exporter
until curl -fs http://127.0.0.1:9113/metrics | grep nginx_connections_writing > /dev/null; do sleep 2; done

mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
apt-get update -y
apt-get install -y alloy
install -m 0644 /tmp/config.alloy /etc/alloy/config.alloy
systemctl enable alloy

cloud-init clean --logs
