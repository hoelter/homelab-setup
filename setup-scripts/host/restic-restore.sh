#!/usr/bin/env bash

set -e

systemctl stop incus.service incus.socket

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting restic restore..."

rm -rf /var/lib/incus
rm -f /etc/subuid /etc/subgid 2>/dev/null || true

source /root/source-restic-env.sh

restic restore latest --target / --include /var/lib/incus --include /etc/subuid --include /etc/subgid

systemctl start incus.socket incus.service

echo "$(date '+%Y-%m-%d %H:%M:%S') - restic restore completed"
