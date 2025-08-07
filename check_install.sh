#!/bin/bash
echo "V2Ray Installation Check"
echo "========================"
echo "Service status: $(systemctl is-active v2ray 2>/dev/null || echo 'not installed')"
echo "Process: $(pgrep v2ray >/dev/null && echo 'running' || echo 'not running')"
echo "Port 8443: $(netstat -ln 2>/dev/null | grep :8443 >/dev/null && echo 'listening' || echo 'not listening')"
echo "Config file: $(test -f /etc/v2ray/config.json && echo 'exists' || echo 'missing')"
echo "Binary: $(test -f /usr/local/bin/v2ray && echo 'exists' || echo 'missing')"
echo "Firewall status:"
ufw status 2>/dev/null | grep 8443 || echo "Port 8443 not configured in firewall"
echo
echo "If V2Ray is running, connection info:"
if [[ -f /etc/v2ray/config.json ]]; then
    U=$(grep -o '"id": *"[^"]*"' /etc/v2ray/config.json | cut -d'"' -f4)
    H=$(hostname -I | awk '{print $1}')
    echo "Server: $H:8443"
    echo "UUID: $U"
    echo "Network: ws"
    echo "Path: /ws"
fi