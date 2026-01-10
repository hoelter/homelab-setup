#!/usr/bin/env bash

set -e

echo "Installing docker dependencies..."
apt install -y \
    ca-certificates \
    curl \
    gnupg \
    sudo \
    cron

# https://docs.docker.com/engine/install/debian/
echo "Installing docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo "Adding docker repository to Apt sources"
# shellcheck disable=SC1091
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Updating packages again..."
apt update

echo "Installing docker..."
# Specific containerd version to avoid newer bug with incus
apt install -y containerd.io=1.7.28-1~debian.13~trixie
apt-mark hold containerd.io
apt install -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin
