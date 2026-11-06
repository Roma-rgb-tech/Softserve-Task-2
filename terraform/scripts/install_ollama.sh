#!bin/bash
exec > /var/log/user-data.log 2>&1
echo "=== Starting Setup ==="

fallocate -1 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

apt-get update -y
apt-get install -y postgresql-client

curl -fsSL https://ollama.com/install.sh | sh

systemctl enable ollama
systemctl start ollama
sleep 5

export HOME=/root
ollama pull qwen2.5:0.5b

echo "=== Setup Complete"
