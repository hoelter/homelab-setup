#!/usr/bin/env bash

set -e

source /root/source-restic-env.sh

echo "$(date '+%Y-%m-%d %H:%M:%S') - Performing monthly full data verification..."

restic check --read-data

echo "$(date '+%Y-%m-%d %H:%M:%S') - Full data verification completed"
