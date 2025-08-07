#!/bin/bash

echo "V2Ray vmess:// Link Generator"
echo "============================"

# Check if V2Ray is installed
if [[ ! -f /etc/v2ray/config.json ]]; then
    echo "❌ V2Ray config not found at /etc/v2ray/config.json"
    echo "Run the installer first: ./install_v2ray_improved.sh"
    exit 1
fi

echo "✅ V2Ray config found"

# Extract UUID from config
UUID=$(grep -o '"id": *"[^"]*"' /etc/v2ray/config.json | cut -d'"' -f4)
if [[ -z "$UUID" ]]; then
    echo "❌ Could not extract UUID from config"
    exit 1
fi

# Get server IP
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ip route get 1 | awk '{print $7; exit}')
if [[ -z "$SERVER_IP" ]]; then
    echo "❌ Could not determine server IP"
    exit 1
fi

# Extract port from config (default 8443)
PORT=$(grep -o '"port": *[0-9]*' /etc/v2ray/config.json | grep -o '[0-9]*' || echo "8443")

# Extract path from config (default /ws)
PATH_WS=$(grep -o '"path": *"[^"]*"' /etc/v2ray/config.json | cut -d'"' -f4 || echo "/ws")

echo ""
echo "📋 V2Ray Server Details:"
echo "========================"
echo "Server IP: $SERVER_IP"
echo "Port: $PORT"
echo "UUID: $UUID"
echo "Network: ws"
echo "Path: $PATH_WS"
echo "Security: none"
echo ""

# Generate JSON config
VMESS_JSON="{\"v\":\"2\",\"ps\":\"V2Ray-$SERVER_IP\",\"add\":\"$SERVER_IP\",\"port\":\"$PORT\",\"id\":\"$UUID\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"\",\"path\":\"$PATH_WS\",\"tls\":\"\"}"

# Generate base64 encoded vmess link
VMESS_BASE64=$(echo -n "$VMESS_JSON" | base64 -w 0)
VMESS_LINK="vmess://$VMESS_BASE64"

echo "🔗 vmess:// Link:"
echo "================="
echo "$VMESS_LINK"
echo ""

echo "📱 How to use:"
echo "=============="
echo "1. Copy the vmess:// link above"
echo "2. Open your V2Ray client (V2RayNG, V2RayN, etc.)"
echo "3. Add server → Import from clipboard/URL"
echo "4. Paste the vmess:// link"
echo "5. Connect!"
echo ""

echo "💾 Save to file:"
echo "================"
echo "This link has been saved to: vmess_link.txt"
echo "$VMESS_LINK" > vmess_link.txt

# Also show JSON config for manual setup
echo ""
echo "📝 JSON Config (for manual setup):"
echo "=================================="
echo "$VMESS_JSON" | python3 -m json.tool 2>/dev/null || echo "$VMESS_JSON"
echo ""

# Check service status
echo "🔍 Service Status:"
echo "================="
systemctl is-active v2ray >/dev/null && echo "✅ V2Ray is running" || echo "❌ V2Ray is not running"
systemctl is-enabled v2ray >/dev/null && echo "✅ Autostart enabled" || echo "❌ Autostart disabled"

# Check port
echo ""
echo "🌐 Port Status:"
echo "==============="
if netstat -tlnp 2>/dev/null | grep ":$PORT" >/dev/null; then
    echo "✅ Port $PORT is listening"
else
    echo "❌ Port $PORT is not listening"
    echo "Try: systemctl restart v2ray"
fi

echo ""
echo "Done! Your vmess:// link is ready to use."