#!/usr/bin/env bash

set -e

echo "Starting git container configuration..."
timedatectl set-timezone America/Chicago
apt update && apt full-upgrade -y

echo "Installing dependencies..."
apt install -y \
    openssh-server \
    git \
    sudo

echo "Creating git user for repository hosting..."
useradd -r -m -c "Git Version Control" -d /home/gituser -s /usr/bin/git-shell gituser

echo "Setting up git user environment..."
sudo -u gituser mkdir -p /home/gituser/git-shell-commands

echo "Creating git-shell-commands helpers..."
cat > /home/gituser/git-shell-commands/no-interactive-login << 'EOF'
#!/bin/sh
printf '%s\n' "Hi $USER! You've successfully authenticated, but I do not"
printf '%s\n' "provide interactive shell access."
exit 128
EOF
chmod +x /home/gituser/git-shell-commands/no-interactive-login

# Copy init-git-repo.sh as create-repo command
cp /opt/setup/init-git-repo.sh /home/gituser/git-shell-commands/create-repo
chmod +x /home/gituser/git-shell-commands/create-repo

echo "Setting up SSH access for git user..."
sudo -u gituser mkdir -p /home/gituser/.ssh
cp /opt/setup/authorized_keys /home/gituser/.ssh/authorized_keys

echo "Setting correct ownership and permissions..."
chown -R gituser:gituser /home/gituser /srv/git-repos
chmod 700 /home/gituser/.ssh
chmod 600 /home/gituser/.ssh/authorized_keys
chmod 755 /home/gituser/git-shell-commands
chmod 755 /srv/git-repos

echo "Installing Tailscale..."
/opt/setup/install-tailscale.sh

echo "Starting SSH service..."
systemctl enable ssh
systemctl start ssh

echo "Git container configuration complete!"
echo "Repository directory: /srv/git-repos"
echo "Git user home: /home/gituser"
echo "To create repositories, use the init-git-repo.sh script"

echo "Cleaning up setup files..."
rm -rf /opt/setup

