#!/bin/bash
set -e
P=/etc/v2ray
U=$(uuidgen)
H=$(hostname -I|awk '{print $1}')
if [[ $(lsb_release -rs|cut -d. -f1) -lt 20 ]];then echo "Ubuntu 20+ required";exit 1;fi
apt update -qq&&apt install -y curl wget unzip uuid-runtime ufw>/dev/null 2>&1
[[ -d $P ]]&&rm -rf $P;mkdir -p $P
curl -sL https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip -o /tmp/v2.zip
unzip -oq /tmp/v2.zip -d /tmp/v2&&cp /tmp/v2/v2ray /usr/local/bin/&&chmod +x /usr/local/bin/v2ray
cat>$P/config.json<<E
{"log":{"loglevel":"warning"},"inbounds":[{"port":8443,"protocol":"vmess","settings":{"clients":[{"id":"$U","alterId":0}]},"streamSettings":{"network":"ws","wsSettings":{"path":"/ws"}}}],"outbounds":[{"protocol":"freedom"}]}
E
cat>/etc/systemd/system/v2ray.service<<E
[Unit]
Description=V2Ray
After=network.target
[Service]
ExecStart=/usr/local/bin/v2ray run -config /etc/v2ray/config.json
Restart=on-failure
User=nobody
[Install]
WantedBy=multi-user.target
E
systemctl daemon-reload&&systemctl enable v2ray&&systemctl start v2ray
ufw --force enable >/dev/null 2>&1
ufw allow 8443 >/dev/null 2>&1
echo "V2Ray installed successfully!"
echo "Server: $H:8443"
echo "UUID: $U"
echo "Network: ws"
echo "Path: /ws"
echo "Client config:"
echo "{\"v\":\"2\",\"ps\":\"V2Ray-$H\",\"add\":\"$H\",\"port\":\"8443\",\"id\":\"$U\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"\",\"path\":\"/ws\",\"tls\":\"\"}"
rm -f /tmp/v2.zip;rm -rf /tmp/v2