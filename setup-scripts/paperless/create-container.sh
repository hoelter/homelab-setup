#!/usr/bin/env bash

set -e

SCRIPT_DIR="/home/chris/setup-scripts"
CONTAINER_NAME="paperless"
PAPERLESS_CONSUME_VOLUME_NAME="paperless-consume"
PAPERLESS_EXPORT_VOLUME_NAME="paperless-export"

echo "Starting Paperless incus container setup..."

echo "Creating paperless volumes..."
incus storage volume create default $PAPERLESS_EXPORT_VOLUME_NAME 2>/dev/null || true
incus storage volume create default $PAPERLESS_CONSUME_VOLUME_NAME 2>/dev/null || true

# Launch the incus container
echo "Launching incus container: $CONTAINER_NAME"
incus launch images:debian/13 $CONTAINER_NAME \
    -c security.nesting=true \
    -c security.syscalls.intercept.mknod=true \
    -c security.syscalls.intercept.setxattr=true

# Mount the shared volumes
echo "Mounting shared volumes..."
incus config device add $CONTAINER_NAME $PAPERLESS_CONSUME_VOLUME_NAME disk \
    pool=default source=$PAPERLESS_CONSUME_VOLUME_NAME path=/srv/paperless-consume

incus config device add $CONTAINER_NAME $PAPERLESS_EXPORT_VOLUME_NAME disk \
    pool=default source=$PAPERLESS_EXPORT_VOLUME_NAME path=/srv/paperless-export

# Copy setup files to container
echo "Copying setup files to container..."
incus file push $SCRIPT_DIR/paperless/*.sh "$CONTAINER_NAME/opt/setup/" --create-dirs
incus file push $SCRIPT_DIR/paperless/*.yaml "$CONTAINER_NAME/opt/setup/"
incus file push $SCRIPT_DIR/common/*.sh "$CONTAINER_NAME/opt/setup/"

# Setup the container environment
echo "Setting up container environment..."
sleep 5
incus exec $CONTAINER_NAME -- bash /opt/setup/configure-container.sh

incus config set $CONTAINER_NAME snapshots.schedule "0 7 * * *" # Daily at 7 AM
incus config set $CONTAINER_NAME snapshots.pattern "auto%d"
incus config set $CONTAINER_NAME snapshots.expiry "30d"

echo "Setup complete!"
echo "Container '$CONTAINER_NAME' is ready with Docker and your compose file."
