#!/usr/bin/env bash

set -e

SCRIPT_DIR="/home/chris/setup-scripts"
CONTAINER_NAME="nas"
NAS_VOLUME_NAME="nas-files"
PAPERLESS_CONSUME_VOLUME_NAME="paperless-consume"

echo "Starting Nas incus container setup..."

echo "Creating volumes..."
incus storage volume create default $NAS_VOLUME_NAME 2>/dev/null || true
incus storage volume create default paperless-consume 2>/dev/null || true

echo "Launching incus container: $CONTAINER_NAME"
incus launch images:debian/13 $CONTAINER_NAME

echo "Mounting the shared volumes"
incus config device add $CONTAINER_NAME $NAS_VOLUME_NAME disk \
    pool=default source=$NAS_VOLUME_NAME path=/srv/nas

incus config device add $CONTAINER_NAME $PAPERLESS_CONSUME_VOLUME_NAME disk \
    pool=default source=$PAPERLESS_CONSUME_VOLUME_NAME path=/srv/paperless-consume

# Copy setup files to container
echo "Copying setup files to container..."
incus file push $SCRIPT_DIR/nas/*.sh "$CONTAINER_NAME/opt/setup/" --create-dirs
incus file push $SCRIPT_DIR/common/*.sh "$CONTAINER_NAME/opt/setup/"

echo "Setting up container environment..."
sleep 5
incus exec $CONTAINER_NAME -- bash /opt/setup/configure-container.sh

echo "Adding smb.conf file"
incus file push "${SCRIPT_DIR}/nas/smb.conf" $CONTAINER_NAME/etc/samba/smb.conf
incus exec $CONTAINER_NAME -- systemctl restart smbd

echo "Creating macvlan network"
incus network create homebr0 --type=macvlan parent=enp1s0 2>/dev/null || true

sleep 5
echo "Adding container to macvlan network"
incus config device add $CONTAINER_NAME eth0 nic network=homebr0

incus config set $CONTAINER_NAME snapshots.schedule "0 7 * * *" # Daily at 7 AM
incus config set $CONTAINER_NAME snapshots.pattern "auto%d"
incus config set $CONTAINER_NAME snapshots.expiry "30d"

incus storage volume set default $NAS_VOLUME_NAME snapshots.schedule "0 7 * * *" # Daily at 7 AM
incus storage volume set default $NAS_VOLUME_NAME snapshots.pattern "auto%d"
incus storage volume set default $NAS_VOLUME_NAME snapshots.expiry "30d"

echo "Setup complete!"
echo "Container '$CONTAINER_NAME' is ready."

