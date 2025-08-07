#!/bin/bash

echo "SSH Access Diagnostic and Fix Script"
echo "===================================="

SERVER_IP="107.189.19.151"
SERVER_USER="root"
SERVER_PASS="2R9HaQ1JJCgr1N"

echo "1. Testing basic connectivity..."
if ping -c 2 $SERVER_IP >/dev/null 2>&1; then
    echo "✓ Server is reachable via ping"
else
    echo "✗ Server is not reachable via ping"
    exit 1
fi

echo ""
echo "2. Testing SSH port 22..."
if nc -zv $SERVER_IP 22 2>/dev/null; then
    echo "✓ SSH port 22 is open"
    echo "Testing SSH authentication..."
    sshpass -p "$SERVER_PASS" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP 'echo "SSH works!"' 2>/dev/null && echo "✓ SSH authentication successful" || echo "✗ SSH authentication failed"
else
    echo "✗ SSH port 22 is closed or filtered"
    echo ""
    echo "3. Checking alternative SSH ports..."
    for port in 2222 2223 10022 22222; do
        echo -n "Testing port $port... "
        if nc -zv $SERVER_IP $port 2>/dev/null; then
            echo "✓ OPEN"
            echo "Trying SSH on port $port..."
            sshpass -p "$SERVER_PASS" ssh -p $port -o ConnectTimeout=10 -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP 'echo "SSH works on port '$port'!"' && echo "✓ SSH works on port $port" || echo "✗ SSH failed on port $port"
        else
            echo "closed"
        fi
    done
fi

echo ""
echo "4. Testing V2Ray port 8443..."
if nc -zv $SERVER_IP 8443 2>/dev/null; then
    echo "✓ V2Ray port 8443 is open"
else
    echo "✗ V2Ray port 8443 is closed or filtered"
fi

echo ""
echo "POSSIBLE SOLUTIONS:"
echo "==================="
echo "If SSH is not accessible:"
echo "1. Contact your VPS provider to:"
echo "   - Reset firewall rules"
echo "   - Enable SSH service"
echo "   - Provide console/VNC access"
echo ""
echo "2. Check if provider changed SSH port after reboot"
echo "3. Provider may have security policies blocking SSH"
echo ""
echo "If only V2Ray port is blocked:"
echo "- UFW firewall may have reset rules after reboot"
echo "- Need SSH access to re-run V2Ray installer"