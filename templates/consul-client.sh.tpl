#!/usr/bin/env bash
set -e

echo "Grabbing IPs..."
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)

echo "Installing dependencies..."
sudo yum update -y &>/dev/null
sudo yum install unzip -y &>/dev/null

# Setup Consul
sudo useradd consul
sudo mkdir -p /home/consul/bin
sudo mkdir -p /home/consul/data
sudo mkdir -p /home/consul/config
sudo tee /home/consul/config/config.json > /dev/null <<EOF
{
  "bind_addr": "$PRIVATE_IP",
  "advertise_addr": "$PRIVATE_IP",
  "advertise_addr_wan": "$PUBLIC_IP",
  "data_dir": "/home/consul/data",
  "disable_remote_exec": true,
  "disable_update_check": true,
  "leave_on_terminate": true,
  "ui": true,
  "acl_enforce_version_8": false,
  "addresses": {
    "http": "0.0.0.0"
  },
  ${config}
}
EOF

echo "Fetching Consul..."
cd /tmp
curl -sLo consul.zip https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip

echo "Installing Consul..."
unzip consul.zip >/dev/null
sudo chmod +x consul
sudo mv consul /home/consul/bin/consul

echo "Enabling Service"
sudo tee /etc/init/consul.conf > /dev/null <<"EOF"
description "Consul"
start on runlevel [2345]
stop on runlevel [06]
respawn
post-stop exec sleep 5
# This is to avoid Upstart re-spawning the process upon `consul leave`
normal exit 0 INT
exec /home/consul/bin/consul agent -config-dir="/home/consul/config"
EOF

sudo stop consul || true
sudo start consul 

echo "Hello from $(hostname)" > /tmp/index.html
(cd /tmp/; nohup nohup ruby -rwebrick -e'WEBrick::HTTPServer.new(:Port => 8888, :DocumentRoot => Dir.pwd).start')&


