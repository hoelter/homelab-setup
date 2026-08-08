#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TIMESTAMP=$(date +"%Y-%m-%d-%H%M")

echo "Starting host updates..."
sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y

echo "Starting container udpates..."

incus snapshot create git "updateall-$TIMESTAMP"
incus exec git -- sh -c "apt update && apt full-upgrade -y && apt autoremove -y"

incus snapshot create nas "updateall-$TIMESTAMP"
incus exec nas -- sh -c "apt update && apt full-upgrade -y && apt autoremove -y"

incus snapshot create paperless "updateall-$TIMESTAMP"
incus exec paperless -- sh -c "apt update && apt full-upgrade -y && apt autoremove -y"
incus file push "$SCRIPT_DIR/../paperless/docker-compose.yaml" paperless/home/paperlessuser/docker-compose.yaml --uid 1000 --gid 1000
incus exec paperless -- su - paperlessuser -c 'cd /home/paperlessuser && docker compose pull && docker compose up -d && docker image prune -af'

incus snapshot create jellyfin "updateall-$TIMESTAMP"
incus exec jellyfin -- sh -c "apt update && apt full-upgrade -y && apt autoremove -y"

incus snapshot create torrent "updateall-$TIMESTAMP"
incus exec torrent -- sh -c "apt update && apt full-upgrade -y && apt autoremove -y"

incus snapshot create arr "updateall-$TIMESTAMP"
incus exec arr -- sh -c "apt update && apt full-upgrade -y && apt autoremove -y"
incus file push "$SCRIPT_DIR/../arr/docker-compose.yaml" arr/home/arruser/docker-compose.yaml --uid 1000 --gid 1000
incus exec arr -- su - arruser -c 'cd /home/arruser && docker compose pull && docker compose up -d && docker image prune -af'

# To rollback run commands like:
# incus stop paperless
# incus snapshot list paperless
# incus snapshot restore paperless updateall-2026-01-06-2325
# incus start paperless
