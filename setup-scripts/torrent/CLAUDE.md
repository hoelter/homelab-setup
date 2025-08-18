# Torrent Container Setup

This directory contains the setup for a secure torrenting container using qBittorrent with ProtonVPN integration via Gluetun.

## Architecture

The torrent container uses a Docker Compose setup with three services:
- **Gluetun**: VPN container providing ProtonVPN WireGuard connection with killswitch
- **qBittorrent**: Torrent client routing all traffic through Gluetun
- **Port Updater**: Automatically configures qBittorrent with VPN-forwarded ports

## Security Features

- **VPN Killswitch**: No network access possible without active VPN connection
- **Traffic Isolation**: All torrent traffic encrypted and routed through ProtonVPN
- **DNS Protection**: All DNS requests go through VPN to prevent leaks
- **Network Isolation**: qBittorrent has no direct network access, only through Gluetun
- **Automatic Port Forwarding**: Gluetun requests ports from ProtonVPN and updates qBittorrent

## Storage Setup

- **External Storage**: `/srv/torrents` mounted outside Incus directory (won't be backed up)
- **Downloads**: Saved to `/srv/torrents/downloads`
- **Config**: qBittorrent and Gluetun configs in `/srv/torrents/config/`
- **VPN Config**: ProtonVPN WireGuard config at `/srv/torrents/config/protonvpn.conf`

## Network Configuration

- **Container Network**: Uses homebr0 macvlan (same as NAS container)
- **Web UI Access**: qBittorrent accessible on port 8080 from local network
- **VPN Traffic**: All torrent traffic routed through ProtonVPN servers
- **Port Forwarding**: Automatic port detection and qBittorrent configuration

## Files

- `create-container.sh`: Creates Incus container with external storage mounting
- `configure-container.sh`: Installs Docker and sets up container environment
- `docker-compose.yaml`: Defines Gluetun, qBittorrent, and port updater services

## Setup Process

1. Run `create-container.sh` to create container with external storage
2. Download ProtonVPN WireGuard config from dashboard
3. Replace `/srv/torrents/config/protonvpn.conf` with actual config
4. Restart services: `docker compose down && docker compose up -d`
5. Access web UI at container IP on port 8080 (default: admin/adminadmin)

## Benefits Over Proxy

- Complete traffic encryption vs proxy's lack of encryption
- DNS leak protection vs common proxy DNS leaks
- Legal protection through plausible deniability
- ISP cannot detect torrenting activity vs proxy where ISP sees torrent traffic
- Automatic killswitch prevents accidental exposure
- Port forwarding improves download performance and connectivity

## Container Integration

The torrent container is included in `setup-fresh-containers.sh` for automated deployment with other homelab services.