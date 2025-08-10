#!/usr/bin/env bash

set -e

source /root/source-restic-env.sh

echo "$(date '+%Y-%m-%d %H:%M:%S') - Performing weekly repository check (5% data subset)..."

restic check --read-data-subset=5%

echo "$(date '+%Y-%m-%d %H:%M:%S') - Weekly repository check completed"
