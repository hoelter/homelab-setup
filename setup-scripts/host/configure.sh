#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

echo "Starting host configuration..."
sudo apt update && sudo apt full-upgrade -y

echo "Installing dependencies..."
sudo apt install -y openssh-server incus restic cron

echo "Adding user to incus-admin group"
sudo adduser $USER incus-admin 2>/dev/null

if incus info >/dev/null 2>&1; then
    echo "Incus is already initialized"
else
    echo "Incus needs initialization"
    sudo incus admin init --minimal
fi

# Read multi-line input until EOF
if ! sudo test -f /root/.restic_env; then
    echo "Please paste the restic environment file content below."
    echo "End your input with a line containing only 'EOF':"
    echo ""
    env_content=""
    while IFS= read -r line; do
        if [[ "$line" == "EOF" ]]; then
            break
        fi
        env_content+="$line"$'\n'
    done
    echo "Creating environment file in /root"
    echo -n "$env_content" | sudo install -m 600 -o root -g root /dev/stdin /root/.restic_env
fi

sudo install -m 600 -o root -g root $SCRIPT_DIR/source-restic-env.sh /root/source-restic-env.sh

echo "Initializing restic"
sudo $SCRIPT_DIR/init-restic.sh

# Edit the /etc/ssh/sshd_config file and enable key only access
# Run the tailscale install manually if desired
# Set the nextdns_link_url
