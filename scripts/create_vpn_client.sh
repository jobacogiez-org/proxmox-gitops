#!/bin/bash
# Bypass wg-easy WebCrypto requirement to create the first client
set -e

CLIENT_NAME=${1:-"admin"}
PROXMOX_IP=$2

if [ -z "$PROXMOX_IP" ]; then
    echo "Usage: ./create_vpn_client.sh <client_name> <proxmox_ip>"
    exit 1
fi

echo "Creating VPN client '$CLIENT_NAME' directly in SQLite on $PROXMOX_IP..."

ssh -i ~/.ssh/proxmox_terraform -o StrictHostKeyChecking=no root@$PROXMOX_IP "docker exec wgeasy wget -qO /tmp/wg-cli.sh https://raw.githubusercontent.com/WeeJeWel/wg-easy/master/src/cli.js && docker exec wgeasy node /tmp/wg-cli.sh add $CLIENT_NAME" || true

echo "Please check the wg-easy UI or use docker logs to see the client configuration."
