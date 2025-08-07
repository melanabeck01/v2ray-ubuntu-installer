#!/bin/bash

# Quick vmess:// link extractor
if [[ -f /etc/v2ray/config.json ]]; then
    UUID=$(grep -o '"id": *"[^"]*"' /etc/v2ray/config.json | cut -d'"' -f4)
    SERVER_IP=$(hostname -I | awk '{print $1}')
    VMESS_JSON="{\"v\":\"2\",\"ps\":\"V2Ray-$SERVER_IP\",\"add\":\"$SERVER_IP\",\"port\":\"8443\",\"id\":\"$UUID\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"\",\"path\":\"/ws\",\"tls\":\"\"}"
    VMESS_LINK="vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"
    
    echo "Your vmess:// link:"
    echo "$VMESS_LINK"
else
    echo "V2Ray not installed. Run ./install_v2ray_improved.sh first"
fi