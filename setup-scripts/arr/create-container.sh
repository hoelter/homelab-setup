#!/usr/bin/env bash

set -e

SCRIPT_DIR="/home/chris/setup-scripts"
CONTAINER_NAME="arr"
ARR_CONFIG_VOLUME_NAME="arr-config"

echo "Starting Arr (Prowlarr/Radarr/Sonarr) incus container setup..."

echo "Creating arr config volume..."
incus storage volume create default $ARR_CONFIG_VOLUME_NAME 2>/dev/null || true

# Launch the incus container with security isolation for Docker
echo "Launching incus container: $CONTAINER_NAME"
incus launch images:debian/13 $CONTAINER_NAME \
    -c security.nesting=true \
    -c security.syscalls.intercept.mknod=true \
    -c security.syscalls.intercept.setxattr=true

# Create dedicated network for arr <-> torrent communication
# echo "Creating arr-net network for inter-container communication..."
# incus network create arr-net ipv4.address=10.10.10.1/24 2>/dev/null || true
# sleep 5
#
# # Add both containers to arr-net with static IPs
# echo "Adding torrent container to arr-net..."
# incus config device add torrent arr-link nic network=arr-net ipv4.address=10.10.10.10 2>/dev/null || true
#
# echo "Adding arr container to arr-net..."
# incus config device add $CONTAINER_NAME arr-link nic network=arr-net ipv4.address=10.10.10.11

# Mount the config volume
echo "Mounting arr config volume..."
incus config device add $CONTAINER_NAME $ARR_CONFIG_VOLUME_NAME disk \
    pool=default source=$ARR_CONFIG_VOLUME_NAME path=/home/arruser/config

# Make sure host directories are created with proper permissions
# echo "Setting up media access permissions on host..."
# mkdir /mnt/extension-drive/media
# sudo chown 1000:1000 /mnt/extension-drive/media
# sudo chmod 755 /mnt/extension-drive/media        # Owner: read/write/execute, Others: read/execute

# Mount torrent downloads directory (read-write for import/hardlink)
# echo "Mounting torrent downloads directory..."
# incus config device add $CONTAINER_NAME downloads disk \
#     source=/mnt/extension-drive/torrents path=/downloads shift=true
#
# # Mount organized media library directory (read-write for Radarr/Sonarr to organize)
# echo "Mounting media library directory..."
# incus config device add $CONTAINER_NAME media disk \
#     source=/mnt/extension-drive/media path=/media shift=true

incus config device add $CONTAINER_NAME data disk source=/mnt/extension-drive path=/data shift=true

# Copy setup files to container
echo "Copying setup files to container..."
incus file push $SCRIPT_DIR/arr/*.sh "$CONTAINER_NAME/opt/setup/" --create-dirs
incus file push $SCRIPT_DIR/arr/*.yaml "$CONTAINER_NAME/opt/setup/"
incus file push $SCRIPT_DIR/common/*.sh "$CONTAINER_NAME/opt/setup/"

# Setup the container environment
echo "Setting up container environment..."
sleep 5
incus exec $CONTAINER_NAME -- bash /opt/setup/configure-container.sh

# Configure container snapshots
incus config set $CONTAINER_NAME snapshots.schedule "0 7 * * *" # Daily at 7 AM
incus config set $CONTAINER_NAME snapshots.pattern "auto%d"
incus config set $CONTAINER_NAME snapshots.expiry "30d"

# Configure volume snapshots
incus storage volume set default $ARR_CONFIG_VOLUME_NAME snapshots.schedule "0 7 * * *" # Daily at 7 AM
incus storage volume set default $ARR_CONFIG_VOLUME_NAME snapshots.pattern "auto%d"
incus storage volume set default $ARR_CONFIG_VOLUME_NAME snapshots.expiry "30d"

echo "Setup complete!"
echo "Container '$CONTAINER_NAME' is ready."
echo ""
echo "Web UI access:"
echo "  - Prowlarr: http://<container-ip>:9696"
echo "  - Radarr:   http://<container-ip>:7878"
echo "  - Sonarr:   http://<container-ip>:8989"
echo ""
echo "Next steps:"
echo "1. Configure Radarr/Sonarr to connect to qBittorrent at 10.10.10.10:8080 (via arr-net)"
echo "2. Configure Prowlarr with your preferred indexers"
echo "3. Link Prowlarr to Radarr/Sonarr using their API keys"
echo "4. Set up root folders: /movies for Radarr, /tv for Sonarr"
echo ""
echo "Storage layout:"
echo "  /downloads - qBittorrent downloads (shared with torrent container)"
echo "  /media/movies - Radarr organized library"
echo "  /media/tvshows - Sonarr organized library"
