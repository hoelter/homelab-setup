#!/usr/bin/env bash

set -e

echo "Starting host udpates..."
sudo apt update && sudo apt full-upgrade -y

echo "Starting container udpates..."
incus exec git -- sh -c "apt update && apt full-upgrade -y"
incus exec nas -- sh -c "apt update && apt full-upgrade -y"
incus exec paperless -- sh -c "apt update && apt full-upgrade -y"
incus exec jellyfin -- sh -c "apt update && apt full-upgrade -y"
incus exec torrent -- sh -c "apt update && apt full-upgrade -y"
