#!/usr/bin/env bash

set -e

PRIV_USER="chris"
SAMBA_USER="sambauser"

echo "Starting nas container configuration..."
timedatectl set-timezone America/Chicago
apt update && apt full-upgrade -y

echo "Installing dependencies..."
apt install -y \
    samba \
    samba-common-bin

echo "Installing Tailscale..."
/opt/setup/install-tailscale.sh

echo "Configuring samba directories and ownership"
mkdir -p /srv/nas/private
mkdir -p /srv/paperless-consume

# Create dedicated samba service user with UID 1000
useradd -u 1000 -m -G sambashare -s /bin/bash $SAMBA_USER

# Add chris as regular user for SMB access
useradd -u 1001 -m -G sambashare -s /bin/bash $PRIV_USER

echo "Please enter the SMB password for user $PRIV_USER:"
read -r -s SMB_PASSWORD
echo "Please confirm the SMB password:"
read -r -s SMB_PASSWORD_CONFIRM

if [ "$SMB_PASSWORD" != "$SMB_PASSWORD_CONFIRM" ]; then
    echo "Passwords do not match. Exiting."
    exit 1
fi

echo "$SMB_PASSWORD" > /tmp/smbpass
echo "$SMB_PASSWORD" >> /tmp/smbpass
# Set up SMB accounts for both users
smbpasswd -a $PRIV_USER < /tmp/smbpass
smbpasswd -a $SAMBA_USER < /tmp/smbpass
rm /tmp/smbpass
echo "SMB password set successfully for $PRIV_USER and $SAMBA_USER"

# Set permissions for nas directories (owned by sambauser UID 1000)
chown -R $SAMBA_USER:sambashare /srv/nas
chmod -R 2775 /srv/nas  # Sticky bit for group inheritance

# Set permissions for paperless consume directory
chown -R $SAMBA_USER:sambashare /srv/paperless-consume
chmod -R 2775 /srv/paperless-consume

echo "Cleaning up setup files..."
rm -rf /opt/setup


