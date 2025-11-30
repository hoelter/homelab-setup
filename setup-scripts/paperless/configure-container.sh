#!/usr/bin/env bash

set -e

echo "Starting Paperless container configuration..."

# Prompt for PAPERLESS_URL
echo -n "Enter the Paperless URL (e.g., https://paperless.your-domain.com): "
read -r PAPERLESS_URL

# Validate URL is not empty
if [ -z "$PAPERLESS_URL" ]; then
    echo "Error: PAPERLESS_URL cannot be empty"
    exit 1
fi

echo "Using PAPERLESS_URL: $PAPERLESS_URL"
timedatectl set-timezone America/Chicago
apt update && apt full-upgrade -y

echo "Installing Docker..."
/opt/setup/install-docker.sh

echo "Installing Tailscale..."
/opt/setup/install-tailscale.sh

echo "Creating application user: paperlessuser"
useradd -u 1000 -m -s /bin/bash paperlessuser

echo "Adding paperlessuser to docker group"
usermod -aG docker paperlessuser

echo "Setting up Docker Compose..."
cp /opt/setup/docker-compose.yaml /home/paperlessuser/
chown paperlessuser:paperlessuser /home/paperlessuser/docker-compose.yaml

echo "Creating environment file..."
cat > /home/paperlessuser/.env << EOF
PAPERLESS_URL=$PAPERLESS_URL
EOF
chown paperlessuser:paperlessuser /home/paperlessuser/.env

echo "Cleaning up setup files..."
rm -rf /opt/setup

echo "Validating and starting Docker Compose stack..."
su - paperlessuser -c "
    cd /home/paperlessuser
    echo 'Validating compose file...'
    docker compose config --quiet
    echo 'Starting Docker Compose stack...'
    docker compose up -d --wait
"

echo "Paperless container configuration complete!"
echo "Docker Compose stack is running and ready"

# After running tailscale up and tailscale cert, reverse proxy the paperless port to 443
# tailscale serve --bg --https=443 http://127.0.0.1:8000
