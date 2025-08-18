#!/usr/bin/env bash

set -e

echo "$(date '+%Y-%m-%d %H:%M:%S') - Updating paperless images..."

incus exec paperless -- su - paperlessuser -c 'cd /home/paperlessuser && docker compose pull && docker compose build --no-cache && docker compose up -d'

echo "$(date '+%Y-%m-%d %H:%M:%S') - Paperless compose restarted"
