#!/usr/bin/env bash

set -e

systemctl stop incus.service incus.socket
trap 'systemctl start incus.socket incus.service' EXIT

# shellcheck source=/dev/null
source /root/source-restic-env.sh

# Clear any stale locks left over from a prior interrupted run
restic unlock

# Paths to backup
BACKUP_PATHS=(
  "/var/lib/incus"
  "/etc/subuid"
  "/etc/subgid"
)

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
HOSTNAME=$(hostname)

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting restic backup..."

# Create backup
restic backup "${BACKUP_PATHS[@]}" \
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

echo "$(date '+%Y-%m-%d %H:%M:%S') - restic backup completed"
