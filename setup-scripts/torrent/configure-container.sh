#!/usr/bin/env bash

set -e

echo "Starting torrent container configuration..."
timedatectl set-timezone America/Chicago

# Read ProtonVPN WireGuard private key from user input
echo ""
echo "=== ProtonVPN WireGuard Private Key Setup ==="
echo "Please enter your ProtonVPN WireGuard private key below."
echo "To get your private key:"
echo "1. Go to ProtonVPN dashboard > Downloads > WireGuard configuration"
echo "2. Download any server configuration file"
echo "3. Copy the value after 'PrivateKey=' (without quotes)"
echo ""

read -s -p "Private Key: " private_key
echo ""

# Validate that we received a private key
if [ -z "$private_key" ]; then
    echo "Error: No private key provided"
    exit 1
fi

apt update && apt full-upgrade -y

echo "Installing Docker..."
/opt/setup/install-docker.sh

echo "Creating application user: torrentuser"
useradd -u 1000 -m -s /bin/bash torrentuser

echo "Adding torrentuser to docker group"
usermod -aG docker torrentuser

# Copy docker-compose.yaml to torrentuser home directory
cp /opt/setup/docker-compose.yaml /home/torrentuser/
chown torrentuser:torrentuser /home/torrentuser/docker-compose.yaml

# Create required directories in persistent volume
mkdir -p /home/torrentuser/config/qbittorrent
mkdir -p /home/torrentuser/config/gluetun

# Set ownership to torrentuser (UID 1000)
chown -R torrentuser:torrentuser /home/torrentuser/config

echo "Creating .env file for Docker Compose..."

# Detect Docker subnet (from container's network interface)
DOCKER_SUBNET=$(ip route | grep -E '^172\.' | grep -E 'scope link' | awk '{print $1}' | head -1)
if [ -z "$DOCKER_SUBNET" ]; then
    # Fallback to common Docker subnet
    DOCKER_SUBNET="172.17.0.0/16"
fi

# Detect local network subnet (look for common private ranges)
LOCAL_SUBNET=$(ip route | grep -E '^192\.168\.|^10\.|^172\.(1[6-9]|2[0-9]|3[01])\.' | grep -v docker | grep -E 'scope link' | awk '{print $1}' | head -1)
if [ -z "$LOCAL_SUBNET" ]; then
    # Fallback to incus subnet
    LOCAL_SUBNET="172.18.0.0/16"
fi

echo "Detected Docker subnet: $DOCKER_SUBNET"
echo "Detected local subnet: $LOCAL_SUBNET"

# Create .env file with private key and network subnets
cat > /home/torrentuser/.env << EOF
WIREGUARD_PRIVATE_KEY=$private_key
DOCKER_SUBNET=$DOCKER_SUBNET
LOCAL_SUBNET=$LOCAL_SUBNET
EOF

# Set proper permissions for .env file
chown torrentuser:torrentuser /home/torrentuser/.env
chmod 600 /home/torrentuser/.env

# Start the docker compose services
cd /home/torrentuser
docker compose up -d

echo "Installing Tailscale..."
/opt/setup/install-tailscale.sh

echo "Cleaning up setup files..."
rm -rf /opt/setup

echo "Container configuration complete!"
echo ""
echo "ProtonVPN private key configured successfully."
echo "Docker Compose services are starting up..."
echo "Port manager container will automatically handle port forwarding."
echo ""
echo "Note: qBittorrent will generate a temporary password on first startup."
echo "Check container logs for the password: docker logs qbittorrent"
echo "Check port manager logs: docker logs gluetun-qbittorrent-port-manager"

