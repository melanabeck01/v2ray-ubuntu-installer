#!/bin/bash
set -e

echo "Starting SAFE V2Ray installation (preserves SSH access)..."

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

# SAFETY: Preserve SSH access before any firewall changes
echo "SAFETY: Ensuring SSH access is preserved..."
# Get current SSH port
SSH_PORT=$(ss -tlnp | grep sshd | head -1 | awk '{print $4}' | cut -d: -f2 || echo "22")
echo "Detected SSH port: $SSH_PORT"

# Install dependencies
echo "Installing dependencies..."
apt update
apt install -y curl wget unzip uuid-runtime

# SAFETY: Configure UFW to allow SSH BEFORE enabling it
echo "SAFETY: Configuring firewall to preserve SSH..."
ufw --force reset  # Reset to clean state
ufw default deny incoming
ufw default allow outgoing
ufw allow $SSH_PORT/tcp comment 'SSH access'
ufw allow 8443/tcp comment 'V2Ray'
# Don't enable UFW yet - will do it at the end

# Download V2Ray
echo "Downloading V2Ray..."
cd /tmp
curl -s https://api.github.com/repos/v2fly/v2ray-core/releases/latest | grep "browser_download_url.*linux-64.zip" | cut -d '"' -f 4 | head -1 | xargs wget -O v2ray.zip
unzip -q v2ray.zip -d v2ray/

# Install V2Ray
echo "Installing V2Ray..."
install -m 755 v2ray/v2ray /usr/local/bin/
mkdir -p $P

# Create config
echo "Creating configuration..."
cat > $P/config.json << EOF
{
  "inbounds": [{
    "port": 8443,
    "protocol": "vmess",
    "settings": {
      "clients": [{ "id": "$U", "alterId": 0 }]
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": { "path": "/ws" }
    }
  }],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

# Create SAFE systemd service
echo "Creating systemd service..."
cat > /etc/systemd/system/v2ray.service << EOF
[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target network-online.target nss-lookup.target
Wants=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=simple
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/v2ray run -config /etc/v2ray/config.json
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=5
RestartPreventExitStatus=23
KillMode=mixed
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start service
echo "Starting V2Ray service..."
systemctl daemon-reload
systemctl enable v2ray
systemctl start v2ray

# FINAL SAFETY CHECK: Verify SSH is still working before enabling firewall
echo "FINAL SAFETY CHECK: Verifying SSH connectivity..."
sleep 2
if ss -tlnp | grep ":$SSH_PORT.*sshd" >/dev/null; then
    echo "✓ SSH service is running on port $SSH_PORT"
    # NOW it's safe to enable firewall
    echo "Enabling firewall with SSH protection..."
    ufw --force enable
else
    echo "⚠ WARNING: SSH may not be running! Firewall NOT enabled for safety."
    echo "Please check SSH service manually before enabling firewall."
fi

# Cleanup
rm -f /tmp/v2ray.zip
rm -rf /tmp/v2ray/

# Output results
echo
echo "============================================"
echo "SAFE V2Ray installation completed!"
echo "============================================"
echo "Server IP: $H"
echo "Port: 8443"
echo "UUID: $U"
echo "Network: ws"
echo "Path: /ws"
echo "Security: none"
echo
echo "SSH Protection:"
echo "SSH Port: $SSH_PORT (protected in firewall)"
echo
echo "Service status:"
systemctl is-active v2ray && echo "✓ V2Ray is running" || echo "✗ V2Ray failed to start"
systemctl is-enabled v2ray && echo "✓ Autostart enabled" || echo "✗ Autostart disabled"
echo "Firewall: $(ufw status | head -1)"
echo

# Generate vmess link
VMESS_JSON="{\"v\":\"2\",\"ps\":\"V2Ray-$H\",\"add\":\"$H\",\"port\":\"8443\",\"id\":\"$U\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"\",\"path\":\"/ws\",\"tls\":\"\"}"
VMESS_BASE64=$(echo -n "$VMESS_JSON" | base64 -w 0)
VMESS_LINK="vmess://$VMESS_BASE64"

echo "Client configuration (JSON):"
echo "$VMESS_JSON"
echo
echo "vmess:// link for easy import:"
echo "$VMESS_LINK"
echo
echo "IMPORTANT: SSH access preserved on port $SSH_PORT"
echo "============================================"