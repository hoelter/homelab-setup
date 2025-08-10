#!/usr/bin/env bash

set -e

SSH_ALIAS="incus-host"
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")/setup-scripts

echo "Deploying all setup scripts to incus host..."

ssh $SSH_ALIAS "mkdir -p /home/chris/setup-scripts/"
scp -r $SCRIPT_DIR/* "$SSH_ALIAS:/home/chris/setup-scripts/"

# Uncomment to immediately start configuration
# ssh $SSH_ALIAS "/home/chris/setup-scripts/host/configure.sh"

echo "Host deploy complete!"
