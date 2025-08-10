#!/usr/bin/env bash

set -e

SCRIPT_DIR="/home/chris/setup-scripts"

$SCRIPT_DIR/paperless/create-container.sh
$SCRIPT_DIR/nas/create-container.sh

