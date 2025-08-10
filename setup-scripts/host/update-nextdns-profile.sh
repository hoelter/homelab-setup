#!/usr/bin/env bash

set -e

echo 'Calling nextdns to update linked IP'
echo "$(date '+%Y-%m-%d %H:%M:%S') - Calling nextdns to update linked IP..."
curl ${NEXTDNS_LINK_URL}
echo "\n"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Done calling nextdns to update linked IP"
