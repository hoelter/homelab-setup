#!/usr/bin/env bash

set -e

TIMESTAMP=$(date +"%Y-%m-%d-%H%M")

echo "Starting container udpates..."

incus snapshot create git "updateall-$TIMESTAMP"
incus exec git -- sh -c "apt update && apt full-upgrade -y"

incus snapshot create nas "updateall-$TIMESTAMP"
incus exec nas -- sh -c "apt update && apt full-upgrade -y"

incus snapshot create paperless "updateall-$TIMESTAMP"
incus exec paperless -- sh -c "apt update && apt full-upgrade -y"

incus snapshot create jellyfin "updateall-$TIMESTAMP"
incus exec jellyfin -- sh -c "apt update && apt full-upgrade -y"

incus snapshot create torrent "updateall-$TIMESTAMP"
incus exec torrent -- sh -c "apt update && apt full-upgrade -y"

echo "Starting host updates..."
sudo apt update && sudo apt full-upgrade -y

