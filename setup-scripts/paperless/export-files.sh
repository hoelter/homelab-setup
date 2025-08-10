#!/usr/bin/env bash

set -e

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting Paperless export..."

incus exec paperless -- bash -c 'rm -rf /srv/paperless-export/*'
incus exec paperless -- su - paperlessuser -c 'cd /home/paperlessuser && docker compose exec -T webserver document_exporter ../export'

echo "$(date '+%Y-%m-%d %H:%M:%S') - Paperless export completed successfully"
