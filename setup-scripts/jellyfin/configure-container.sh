#!/usr/bin/env bash

set -e

echo "Starting Jellyfin container configuration..."
timedatectl set-timezone America/Chicago
apt update && apt full-upgrade -y

echo "Installing dependencies..."
apt install -y \
    openssh-server \
    curl \
    gnupg2 \
    lsb-release \
    libicu76

echo "Installing Jellyfin..."
# Add Jellyfin repository with proper keyring isolation
curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | gpg --dearmor -o /usr/share/keyrings/jellyfin-archive-keyring.gpg
echo "deb [arch=$( dpkg --print-architecture ) signed-by=/usr/share/keyrings/jellyfin-archive-keyring.gpg] https://repo.jellyfin.org/debian $( lsb_release -c -s ) main" | tee /etc/apt/sources.list.d/jellyfin.list

# Update package list and install Jellyfin
apt update
apt install -y jellyfin

# Media directory has world read permissions (755) - jellyfin can read via bind mount

# Enable and start Jellyfin service
systemctl enable jellyfin
systemctl start jellyfin

# Wait for service to start and verify
sleep 5
if ! systemctl is-active --quiet jellyfin; then
    echo "ERROR: Jellyfin service failed to start"
    systemctl status jellyfin
    exit 1
fi
echo "Jellyfin service started successfully"

echo "Cleaning up setup files..."
rm -rf /opt/setup

echo "Container configuration complete!"
echo ""
echo "Jellyfin is now running and accessible on port 8096"
echo "Media files are available at /media (read-only)"
echo "Complete setup through the web interface on port 8096"
