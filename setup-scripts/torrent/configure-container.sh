#!/usr/bin/env bash

set -e

echo "Starting torrent container configuration..."
timedatectl set-timezone America/Chicago
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
mkdir -p /downloads

# Set ownership to torrentuser (UID 1000)
chown -R torrentuser:torrentuser /home/torrentuser/config

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

echo "Creating .env file for Docker Compose..."

# Create .env file with private key
echo "WIREGUARD_PRIVATE_KEY=$private_key" > /home/torrentuser/.env

# Set proper permissions for .env file
chown torrentuser:torrentuser /home/torrentuser/.env
chmod 600 /home/torrentuser/.env

# Start the docker compose services
cd /home/torrentuser
docker compose up -d

echo "Cleaning up setup files..."
rm -rf /opt/setup

echo "Container configuration complete!"
echo ""
echo "ProtonVPN private key configured successfully."
echo "Docker Compose services are starting up..."
