#!/usr/bin/env bash

set -e

echo "Installing tailscale"

apt install -y curl

curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list
apt update && apt install -y tailscale

echo "Run 'tailscale up' to initialize, 'tailscale cert' to generate https certs"
