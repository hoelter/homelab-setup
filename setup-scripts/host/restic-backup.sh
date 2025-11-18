#!/usr/bin/env bash

set -e

systemctl stop incus.service incus.socket

source /root/source-restic-env.sh

# Paths to backup
BACKUP_PATHS="/var/lib/incus /etc/subuid /etc/subgid"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
HOSTNAME=$(hostname)

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting restic backup..."

# Create backup
restic backup $BACKUP_PATHS \
    --tag "auto-backup" \
    --tag "$TIMESTAMP" \
    --host "$HOSTNAME" \
    --exclude-caches \
    --one-file-system \
    --ignore-inode --ignore-ctime \
    --compression max

# Forget old snapshots
restic forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 12

sudo systemctl start incus.socket incus.service

echo "$(date '+%Y-%m-%d %H:%M:%S') - restic backup completed"
