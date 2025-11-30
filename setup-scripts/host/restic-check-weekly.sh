#!/usr/bin/env bash

set -e

# shellcheck source=/dev/null
source /root/source-restic-env.sh

echo "$(date '+%Y-%m-%d %H:%M:%S') - Performing weekly forgetting prune"

restic forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 12 \
    --prune

echo "$(date '+%Y-%m-%d %H:%M:%S') - Weekly forgetting complete"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Performing weekly cache cleanup"

restic cache --cleanup

echo "$(date '+%Y-%m-%d %H:%M:%S') - Weekly cache cleanup complete"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Performing weekly repository check (5% data subset)..."

restic check --read-data-subset=5%

echo "$(date '+%Y-%m-%d %H:%M:%S') - Weekly repository check completed"

