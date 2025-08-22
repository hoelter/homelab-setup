# Server Scripts

Scripts used to configure and run my homelab.

These setup a debian host machine with incus, a few services running in debian incus containers, and restic backing up the entire incus volume encrypted to a remote s3 compatible bucket.
Services are meant to be exposed to clients using tailscale. These services generally have their core data placed on custom incus volumes so that the containers can be recreated at will. 

## Services

### Paperless

Runs [paperless-ngx](https://github.com/paperless-ngx/paperless-ngx) using their docker compose file with slight modifications inside an incus container.
There are scripts included to export/import data via the attached incus volume for portability of the contained files. If the container needs to be re-created
from scratch, export the data, recreate the container, then re-import the data from that export volume which should get automatically attached.

### Nas

This sets up a container running a samba share. Desired password for the drive is prompted at time of container creation. It has some samba config settings that optimize
access from macos clients. All files are stored on a custom incus volume that will survive container re-creation.

## Git

This is a container meant to be used as a remote git repository. It's locked down to run git commands and has a custom git-shell-command to create new empty repositories.
All repositories are stored on a custom incus volume that will survive container re-creation.

## Torrent

This runs qbittorrent in docker compose. It's setup to funnel network traffic through gluetun which manages the vpn connection and acts as a killswitch if the vpn goes down.
