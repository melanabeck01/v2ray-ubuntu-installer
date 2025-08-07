#!/bin/bash
H="107.189.19.151"
P="2R9HaQ1JJCgr1N"
echo "Testing connection to $H..."
for i in {1..10}; do
    echo -n "Attempt $i: "
    if sshpass -p "$P" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$H 'echo "Connected!"' 2>/dev/null; then
        echo "SUCCESS! Server is available."
        echo "Running V2Ray installer..."
        sshpass -p "$P" scp -o StrictHostKeyChecking=no install_v2ray_improved.sh root@$H:/tmp/
        sshpass -p "$P" ssh -o StrictHostKeyChecking=no root@$H '/tmp/install_v2ray_improved.sh'
        echo "Testing installation..."
        sshpass -p "$P" scp -o StrictHostKeyChecking=no check_install.sh root@$H:/tmp/
        sshpass -p "$P" ssh -o StrictHostKeyChecking=no root@$H '/tmp/check_install.sh'
        exit 0
    else
        echo "Failed"
        sleep 30
    fi
done
echo "Server is not responding after 10 attempts."