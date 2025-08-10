#!/usr/bin/env bash

set -e

SCRIPT_DIR="/home/chris/setup-scripts"
CONTAINER_NAME="git"
GIT_VOLUME_NAME="git-repos"

echo "Starting $CONTAINER_NAME incus container setup..."

echo "Creating volumes..."
incus storage volume create default $GIT_VOLUME_NAME 2>/dev/null || true

echo "Launching incus container: $CONTAINER_NAME"
incus launch images:debian/13 $CONTAINER_NAME

echo "Mounting the shared volumes"
incus config device add $CONTAINER_NAME $GIT_VOLUME_NAME disk \
    pool=default source=$GIT_VOLUME_NAME path=/srv/git-repos

# Copy setup files to container
echo "Copying setup files to container..."
incus file push $SCRIPT_DIR/git/*.sh "$CONTAINER_NAME/opt/setup/" --create-dirs
incus file push $SCRIPT_DIR/common/*.sh "$CONTAINER_NAME/opt/setup/"
incus file push ~/.ssh/authorized_keys $CONTAINER_NAME/opt/setup/authorized_keys

echo "Setting up container environment..."
sleep 5
incus exec $CONTAINER_NAME -- bash /opt/setup/configure-container.sh

incus config set $CONTAINER_NAME snapshots.schedule "0 7 * * *" # Daily at 7 AM
incus config set $CONTAINER_NAME snapshots.pattern "auto%d"
incus config set $CONTAINER_NAME snapshots.expiry "30d"

incus storage volume set default $GIT_VOLUME_NAME snapshots.schedule "0 7 * * *" # Daily at 7 AM
incus storage volume set default $GIT_VOLUME_NAME snapshots.pattern "auto%d"
incus storage volume set default $GIT_VOLUME_NAME snapshots.expiry "30d"

echo "Setup complete!"
echo "Container '$CONTAINER_NAME' is ready."

