#!/usr/bin/env bash

set -e

source /root/source-restic-env.sh

echo "$(date '+%Y-%m-%d %H:%M:%S') - Performing monthly data verification..."

restic check --read-data-subset=25%

echo "$(date '+%Y-%m-%d %H:%M:%S') - Full data verification completed"

