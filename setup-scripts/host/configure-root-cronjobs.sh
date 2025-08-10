#!/usr/bin/env bash

set -e

echo "Setting up root crontab"
sudo systemctl stop cron

cat > /tmp/root-crontab << 'EOF'
# Restic backup every day at 2 am
0 2 * * * /home/chris/setup-scripts/host/restic-backup.sh >> /var/log/restic-backup.log 2>&1
# Weekly restic repository check every Sunday at 4 AM
0 4 * * 0 /home/chris/setup-scripts/host/restic-check-weekly.sh >> /var/log/restic-check-weekly.log 2>&1
# Monthly restic repository check on first Sunday at 6 AM
0 6 1-7 * 0 /home/chris/setup-scripts/host/restic-check-monthly.sh >> /var/log/restic-check-monthly.log 2>&1
# Update nextdns profile ip at 1am
0 1 * * * /home/chris/setup-scripts/host/update-nextdns-profile.sh >> /var/log/update-nextdns-profile.log 2>&1
EOF

sudo crontab /tmp/root-crontab
rm /tmp/root-crontab

echo "Starting cron service"
sudo systemctl enable cron
sudo systemctl start cron

echo "Creating log files with proper permissions"
touch /var/log/restic-backup.log
chown root:root /var/log/restic-backup.log
chmod 644 /var/log/restic-backup.log

touch /var/log/restic-check-weekly.log
chown root:root /var/log/restic-check-weekly.log
chmod 644 /var/log/restic-check-weekly.log

touch /var/log/restic-check-monthly.log
chown root:root /var/log/restic-check-monthly.log
chmod 644 /var/log/restic-check-monthly.log

touch /var/log/update-nextdns-profile.log
chown root:root /var/log/update-nextdns-profile.log
chmod 644 /var/log/update-nextdns-profile.log
