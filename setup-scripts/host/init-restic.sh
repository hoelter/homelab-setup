#!/usr/bin/env bash

source /home/chris/setup-scripts/host/source-restic-env.sh

echo "Initializing restic repository..."

# Check if repository exists, if not initialize it
if ! restic cat config >/dev/null 2>&1; then
    echo "Initializing repository (S3 API)..."
    restic init
    echo "repository initialized"
else
    echo "repository already exists"
fi
