#!/usr/bin/env bash

set -e

echo "Starting Jellyfin container configuration..."
timedatectl set-timezone America/Chicago
apt update && apt full-upgrade -y

echo "Installing dependencies..."
apt install -y \
    openssh-server \
    git \
    sudo \
    curl \
    wget \
    gnupg2 \
    software-properties-common \
    apt-transport-https \
    ca-certificates

echo "Installing Jellyfin..."
# Add Jellyfin repository
curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/jellyfin.gpg
echo "deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/debian $( lsb_release -c -s ) main" | tee /etc/apt/sources.list.d/jellyfin.list

# Update package list and install Jellyfin
apt update
apt install -y jellyfin

# Ensure jellyfin can read the media directory
chmod 755 /media

# Enable and start Jellyfin service
systemctl enable jellyfin
systemctl start jellyfin

# Wait for service to start
sleep 5

echo "Cleaning up setup files..."
rm -rf /opt/setup

echo "Container configuration complete!"
echo ""
echo "Jellyfin is now running and accessible on port 8096"
echo "Media files are available at /media (read-only)"
echo "Complete setup through the web interface on port 8096"
