#!/usr/bin/env bash

set -e

echo "Starting arr container configuration..."
timedatectl set-timezone America/Chicago

apt update && apt full-upgrade -y

echo "Installing Docker..."
/opt/setup/install-docker.sh

echo "Creating application user: arruser"
useradd -u 1000 -m -s /bin/bash arruser

echo "Adding arruser to docker group"
usermod -aG docker arruser

# Copy docker-compose.yaml to arruser home directory
cp /opt/setup/docker-compose.yaml /home/arruser/
chown arruser:arruser /home/arruser/docker-compose.yaml

# Create required directories in persistent volume
mkdir -p /home/arruser/config/prowlarr
mkdir -p /home/arruser/config/radarr
mkdir -p /home/arruser/config/sonarr

# Create media library directories
mkdir -p /media/movies
mkdir -p /media/tvshows

# Set ownership to arruser (UID 1000)
chown -R arruser:arruser /home/arruser/config
chown -R arruser:arruser /media/movies
chown -R arruser:arruser /media/tvshows

# Start the docker compose services
echo "Starting Docker Compose services..."
cd /home/arruser
docker compose up -d

echo "Installing Tailscale..."
/opt/setup/install-tailscale.sh

echo "Cleaning up setup files..."
rm -rf /opt/setup

echo "Container configuration complete!"
echo ""
echo "Services are starting up. Check status with: docker compose ps"
echo ""
echo "Web UI access (use container IP):"
echo "  - Prowlarr: port 9696"
echo "  - Radarr:   port 7878"
echo "  - Sonarr:   port 8989"
