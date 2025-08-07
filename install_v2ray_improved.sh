#!/bin/bash
set -e

echo "Starting V2Ray installation..."

# Variables
P=/etc/v2ray
U=$(uuidgen 2>/dev/null || echo "$(cat /proc/sys/kernel/random/uuid)")
H=$(hostname -I 2>/dev/null | awk '{print $1}' || ip route get 1 | awk '{print $7; exit}')

# Check Ubuntu version
VER=$(lsb_release -rs 2>/dev/null | cut -d. -f1 || echo "0")
if [[ $VER -lt 20 ]]; then
    echo "Error: Ubuntu 20+ required, found: $(lsb_release -ds 2>/dev/null || echo 'Unknown')"
    exit 1
fi

echo "Ubuntu version check: OK"
echo "Server IP: $H"
echo "Generated UUID: $U"

# Update and install dependencies
echo "Installing dependencies..."
apt update -qq
apt install -y curl wget unzip uuid-runtime ufw

# Clean previous installation
echo "Cleaning previous installation..."
systemctl stop v2ray 2>/dev/null || true
systemctl disable v2ray 2>/dev/null || true
[[ -d $P ]] && rm -rf $P
mkdir -p $P

# Download and install V2Ray
echo "Downloading V2Ray..."
curl -sL "https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip" -o /tmp/v2ray.zip
unzip -oq /tmp/v2ray.zip -d /tmp/v2ray/
cp /tmp/v2ray/v2ray /usr/local/bin/
chmod +x /usr/local/bin/v2ray

# Create config
echo "Creating configuration..."
cat > $P/config.json << EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [{
    "port": 8443,
    "protocol": "vmess",
    "settings": {
      "clients": [{
        "id": "$U",
        "alterId": 0
      }]
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "/ws"
      }
    }
  }],
  "outbounds": [{
    "protocol": "freedom"
  }]
}
EOF

# Create systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/v2ray.service << EOF
[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/v2ray run -config /etc/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF

# Start service
echo "Starting V2Ray service..."
systemctl daemon-reload
systemctl enable v2ray
systemctl start v2ray

# Configure firewall
echo "Configuring firewall..."
ufw --force enable
ufw allow 8443/tcp

# Cleanup
rm -f /tmp/v2ray.zip
rm -rf /tmp/v2ray/

# Output results
echo
echo "============================================"
echo "V2Ray installation completed successfully!"
echo "============================================"
echo "Server IP: $H"
echo "Port: 8443"
echo "UUID: $U"
echo "Network: ws"
echo "Path: /ws"
echo "Security: none"
echo
echo "Service status:"
systemctl is-active v2ray && echo "✓ V2Ray is running" || echo "✗ V2Ray failed to start"
echo
echo "Client configuration (JSON):"
echo "{\"v\":\"2\",\"ps\":\"V2Ray-$H\",\"add\":\"$H\",\"port\":\"8443\",\"id\":\"$U\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"\",\"path\":\"/ws\",\"tls\":\"\"}"
echo
echo "Use this config in your V2Ray client."
echo "============================================"