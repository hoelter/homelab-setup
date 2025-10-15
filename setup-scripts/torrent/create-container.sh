#!/usr/bin/env bash

set -e

SCRIPT_DIR="/home/chris/setup-scripts"
CONTAINER_NAME="torrent"
TORRENT_CONFIG_VOLUME_NAME="torrent-config"
echo "Starting Torrent incus container setup..."

echo "Creating torrent config volume..."
incus storage volume create default $TORRENT_CONFIG_VOLUME_NAME 2>/dev/null || true

# # Create host directory for direct bind mount
# echo "Creating host directory for torrent downloads..."
# sudo mkdir -p /srv/torrents

# # Set up permissions on host - world readable, owner writable
# echo "Setting up media access permissions on host..."
# sudo chown 1000:1000 /srv/torrents  # UID 1000 (torrentuser)
# sudo chmod 755 /srv/torrents        # Owner: read/write/execute, Others: read/execute

# Launch the incus container with security isolation and ID mapping
echo "Launching incus container: $CONTAINER_NAME"
incus launch images:debian/13 $CONTAINER_NAME \
    -c security.nesting=true \
    -c security.syscalls.intercept.mknod=true \
    -c security.syscalls.intercept.setxattr=true

# Mount the config volume and downloads directory
echo "Mounting torrent config volume..."
incus config device add $CONTAINER_NAME $TORRENT_CONFIG_VOLUME_NAME disk \
    pool=default source=$TORRENT_CONFIG_VOLUME_NAME path=/home/torrentuser/config

echo "Mounting torrent downloads directory via bind mount..."
# incus config device add $CONTAINER_NAME torrent-downloads disk \
#     source=/srv/torrents path=/srv/torrents shift=true
incus config device add $CONTAINER_NAME torrent-downloads disk \
    source=/mnt/extension-drive/torrents path=/srv/torrents shift=true

# Copy setup files to container
echo "Copying setup files to container..."
incus file push $SCRIPT_DIR/torrent/*.sh "$CONTAINER_NAME/opt/setup/" --create-dirs
incus file push $SCRIPT_DIR/torrent/*.yaml "$CONTAINER_NAME/opt/setup/"
incus file push $SCRIPT_DIR/common/*.sh "$CONTAINER_NAME/opt/setup/"

# Setup the container environment
echo "Setting up container environment..."
sleep 5
incus exec $CONTAINER_NAME -- bash /opt/setup/configure-container.sh

# incus config device add torrent qbittorrent-web proxy listen=tcp:0.0.0.0:8080 connect=tcp:127.0.0.1:8080
echo "Creating macvlan network"
incus network create homebr0 --type=macvlan parent=enp1s0 2>/dev/null || true

sleep 5
echo "Adding container to macvlan network"
incus config device add $CONTAINER_NAME eth0 nic network=homebr0

incus config set $CONTAINER_NAME snapshots.schedule "0 7 * * *" # Daily at 7 AM
incus config set $CONTAINER_NAME snapshots.pattern "auto%d"
incus config set $CONTAINER_NAME snapshots.expiry "30d"

# Configure volume snapshots
incus storage volume set default $TORRENT_CONFIG_VOLUME_NAME snapshots.schedule "0 7 * * *" # Daily at 7 AM
incus storage volume set default $TORRENT_CONFIG_VOLUME_NAME snapshots.pattern "auto%d"
incus storage volume set default $TORRENT_CONFIG_VOLUME_NAME snapshots.expiry "30d"

incus exec torrent -- docker logs qbittorrent

echo "Setup complete!"
echo "Container '$CONTAINER_NAME' is ready."
echo ""
echo "Next steps:"
echo "1. The qBittorrent web UI will be available on the container's IP on port 8080"
echo "2. Default username is admin and password is in the qbittorrent container logs"
echo "3. Downloads will be saved to /downloads (mounted from external storage volume)"
echo ""
echo "Update qbitorrent webui to bypass localhost auth so that the port-updater functions as expected"
echo "Storage note: Downloads at /srv/torrents (external), configs in persistent volume."

