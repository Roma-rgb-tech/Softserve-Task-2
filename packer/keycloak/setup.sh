#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

cloud-init status --wait
apt-get update -y
apt-get upgrade -y
apt-get install -y --no-install-recommends curl gpg unzip openjdk-21-jre-headless postgresql-client

curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
aws --version
rm -rf /tmp/aws /tmp/awscliv2.zip

useradd --system --home-dir /opt/keycloak --shell /usr/sbin/nologin keycloak

KC_URL="https://github.com/keycloak/keycloak/releases/download/${KEYCLOAK_VERSION}/keycloak-${KEYCLOAK_VERSION}.zip"
curl -fsSL "$KC_URL" -o /tmp/keycloak.zip
echo "$(curl -fsSL "${KC_URL}.sha1" | awk '{print $1}')  /tmp/keycloak.zip" | sha1sum -c -
unzip -q /tmp/keycloak.zip -d /opt
mv "/opt/keycloak-${KEYCLOAK_VERSION}" /opt/keycloak
rm -f /tmp/keycloak.zip

cat >> /opt/keycloak/conf/keycloak.conf <<'EOF'
db=postgres
health-enabled=true
metrics-enabled=true
EOF
/opt/keycloak/bin/kc.sh build

chown -R keycloak:keycloak /opt/keycloak
/opt/keycloak/bin/kc.sh --version
install -m 0644 /tmp/keycloak.service /etc/systemd/system/keycloak.service

mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
apt-get update -y
apt-get install -y alloy
install -m 0644 /tmp/config.alloy /etc/alloy/config.alloy
alloy fmt /etc/alloy/config.alloy > /dev/null

systemctl daemon-reload
systemctl enable keycloak alloy

cloud-init clean --logs
