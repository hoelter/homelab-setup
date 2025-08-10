#!/usr/bin/env bash

set -e

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting Paperless import..."

incus exec paperless -- su - paperlessuser -c 'cd /home/paperlessuser && docker compose exec -T webserver document_importer ../export'

echo "$(date '+%Y-%m-%d %H:%M:%S') - Paperless import completed successfully"
