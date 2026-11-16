#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

cloud-init status --wait
apt-get update -y
apt-get upgrade -y
apt-get install -y --no-install-recommends curl gpg unzip docker.io docker-buildx postgresql-client

curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
aws --version
rm -rf /tmp/aws /tmp/awscliv2.zip

systemctl enable --now docker
docker build --build-arg KEYCLOAK_VERSION="${KEYCLOAK_VERSION}" -t "keycloak:${KEYCLOAK_VERSION}" - < /tmp/Dockerfile
docker run --rm "keycloak:${KEYCLOAK_VERSION}" --version
echo "KEYCLOAK_IMAGE=keycloak:${KEYCLOAK_VERSION}" > /etc/default/keycloak
install -m 0644 /tmp/keycloak.service /etc/systemd/system/keycloak.service

mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
apt-get update -y
apt-get install -y alloy
install -m 0644 /tmp/config.alloy /etc/alloy/config.alloy
alloy fmt /etc/alloy/config.alloy > /dev/null

systemctl daemon-reload
systemctl enable docker keycloak alloy

cloud-init clean --logs
