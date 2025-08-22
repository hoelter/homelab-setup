#!/usr/bin/env bash

set -e

SCRIPT_DIR="/home/chris/setup-scripts"
CONTAINER_NAME="jellyfin"

echo "Starting Jellyfin incus container setup..."

# Create jellyfin config volume
echo "Creating jellyfin config volume..."
incus storage volume create default jellyfin-config 2>/dev/null || true

# Launch the incus container
echo "Launching incus container: $CONTAINER_NAME"
incus launch images:debian/13 $CONTAINER_NAME

# Mount the jellyfin config volume
echo "Mounting jellyfin config volume..."
incus config device add $CONTAINER_NAME jellyfin-config disk \
    pool=default source=jellyfin-config path=/var/lib/jellyfin

# Mount the shared torrents volume for media access (read-only for safety)
echo "Mounting shared media volume from torrent container..."
incus config device add $CONTAINER_NAME media-disk disk \
    pool=external-storage source=torrent-downloads path=/media readonly=true

# Copy setup files to container
echo "Copying setup files to container..."
incus file push $SCRIPT_DIR/jellyfin/*.sh "$CONTAINER_NAME/opt/setup/" --create-dirs
incus file push $SCRIPT_DIR/common/*.sh "$CONTAINER_NAME/opt/setup/"

# Setup the container environment
echo "Setting up container environment..."
sleep 5
incus exec $CONTAINER_NAME -- bash /opt/setup/configure-container.sh

echo "Creating macvlan network"
incus network create homebr0 --type=macvlan parent=enp1s0 2>/dev/null || true

sleep 5
echo "Adding container to macvlan network"
incus config device add $CONTAINER_NAME eth0 nic network=homebr0

# Configure snapshots
incus config set $CONTAINER_NAME snapshots.schedule "0 7 * * *" # Daily at 7 AM
incus config set $CONTAINER_NAME snapshots.pattern "auto%d"
incus config set $CONTAINER_NAME snapshots.expiry "30d"

incus storage volume set default jellyfin-config snapshots.schedule "0 7 * * *" # Daily at 7 AM
incus storage volume set default jellyfin-config snapshots.pattern "auto%d"
incus storage volume set default jellyfin-config snapshots.expiry "30d"

echo "Setup complete!"
echo "Container '$CONTAINER_NAME' is ready."
echo ""
echo "Next steps:"
echo "1. Jellyfin web UI will be available on the container's IP on port 8096"
echo "2. Media files are accessible at /media (read-only from torrent-downloads volume)"
echo "3. Complete setup through the web interface"
echo ""
echo "Security note: Media directory is mounted read-only for safety."
