# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Architecture

This is a homelab infrastructure setup repository that automates the deployment and configuration of services using Incus containers. The architecture follows a layered approach:

- **Host Layer**: Scripts that configure the physical host with Incus, backup systems, and base services
- **Container Layer**: Individual service containers (Git, NAS, Paperless, Jellyfin, Torrent) with isolated storage volumes
- **Service Layer**: Application-specific configurations and Docker Compose deployments

### Directory Structure

- `setup-scripts/host/`: Host-level configuration scripts for the physical server
- `setup-scripts/common/`: Shared utilities (Docker, Tailscale installation)
- `setup-scripts/{service}/`: Service-specific container setup (git, nas, paperless, jellyfin, torrent)
- Root-level scripts: Deployment and testing orchestration

### Container Pattern

Each service follows a consistent pattern:
1. `create-container.sh`: Creates Incus container with volumes and network config
2. `configure-container.sh`: Installs dependencies and configures the service inside the container
3. Service-specific configs (docker-compose.yaml, smb.conf, etc.)

## Key Commands

### Deployment Commands
- `./deploy-host-setup.sh` - Deploy all setup scripts to production host via SSH (uses "incus-host" alias)
- `./setup-host-test-env.sh` - Create test VM environment for development (uses "real-incus-host" alias)
- `setup-scripts/host/setup-fresh-containers.sh` - Deploy all service containers (git, paperless, nas, torrent, jellyfin)
- `setup-scripts/host/configure.sh` - Initial host setup (installs incus, restic, configures environment)

### Service Management
- `incus list` - View all containers and their status
- `incus exec {container-name} -- bash` - Access container shell
- `incus storage volume list default` - View storage volumes
- `incus network list` - View network configurations
- `incus config device add {container} eth0 nic network=homebr0` - Add container to macvlan network

### Container Operations
- `incus launch images:debian/13 {container-name}` - Create new Debian container
- `incus delete {container-name} --force` - Force delete container
- `incus file push {local-file} {container}/path/` - Copy files to container
- `incus snapshot create {container} {snapshot-name}` - Manual snapshot creation

### Backup Operations
- `setup-scripts/host/restic-backup.sh` - Run backup to remote repository
- `setup-scripts/host/restic-restore.sh` - Restore from backup
- `setup-scripts/host/restic-check-weekly.sh` - Verify backup integrity weekly
- `setup-scripts/host/restic-check-monthly.sh` - Verify backup integrity monthly
- `setup-scripts/host/init-restic.sh` - Initialize restic repository

### Service-Specific Commands
- `setup-scripts/paperless/export-files.sh` - Export Paperless data from container
- `setup-scripts/paperless/import-files.sh` - Import Paperless data to container
- `setup-scripts/paperless/update-paperless.sh` - Update Paperless container and services
- `setup-scripts/git/init-git-repo.sh` - Initialize new git repository on git container

## Development Workflow

### Testing Changes
1. Use `setup-host-test-env.sh` to create isolated test environment
2. Deploy scripts to test VM before production
3. Container snapshots are automatically configured (daily at 7 AM, 30-day retention)

### Adding New Services
1. Create directory under `setup-scripts/{service-name}/`
2. Implement `create-container.sh` following existing pattern
3. Add `configure-container.sh` for service-specific setup
4. Update `setup-fresh-containers.sh` to include new service

### Network Configuration
- Containers use macvlan network (homebr0) for direct network access
- SSH access via authorized keys, not passwords
- Services expose ports directly to network (e.g., Paperless on port 8000, Jellyfin on port 8096, qBittorrent on port 8080)
- Test environment uses parent interface `enp1s0` for macvlan bridge

## Important Configuration Details

### Storage Volumes
- Each service has dedicated Incus storage volumes for data persistence
- Paperless uses bind mounts to host directories (`/srv/paperless-consume`, `/srv/paperless-export`)
- Volume snapshots configured with same schedule as containers (daily 7 AM, 30-day retention)
- Git repositories stored in `/srv/git-repos` volume
- NAS files stored on custom incus volume with samba sharing
- Jellyfin config stored in dedicated `jellyfin-config` volume
- Torrent downloads stored at `/srv/torrents` (external to Incus, not backed up)

### Container Configuration
- All containers use Debian 13 base image (`images:debian/13`)
- Paperless and Torrent containers require security nesting and syscall interception for Docker Compose
- All containers run with non-root user mapping (UID 1000)
- SSH key-only authentication enforced across all services

### Environment Setup
- Host requires: openssh-server, incus, restic, cron
- SSH aliases: `incus-host` (production), `real-incus-host` (for test VM creation)
- Restic environment variables must be configured in `/root/.restic_env`
- User must be added to `incus-admin` group for container management

### Service Details
- **Paperless**: Uses Docker Compose with PostgreSQL, Redis, Gotenberg, and Tika services
- **Git**: Custom git shell with repository creation commands, locked-down SSH access
- **NAS**: Samba file sharing with macOS-optimized configuration
- **Jellyfin**: Media server with direct Jellyfin installation, accesses torrent media read-only
- **Torrent**: qBittorrent with Gluetun VPN (ProtonVPN WireGuard) and automatic port forwarding
- All services configured with automatic snapshots and backup integration

### Torrent Security Configuration
- **VPN Killswitch**: All torrent traffic routed through ProtonVPN WireGuard with killswitch
- **Traffic Isolation**: qBittorrent has no direct network access, only through Gluetun VPN container
- **DNS Protection**: All DNS requests go through VPN to prevent leaks
- **Automatic Port Forwarding**: Gluetun requests ports from ProtonVPN and updates qBittorrent
- **External Storage**: Downloads stored outside Incus directory structure (not backed up)
- **VPN Config**: Requires ProtonVPN WireGuard config at `/srv/torrents/config/protonvpn.conf`

### Media Integration
- **Jellyfin-Torrent**: Jellyfin container mounts `/srv/torrents` as read-only `/media`
- **Shared Storage**: Media files downloaded by torrent container are immediately available to Jellyfin
- **Security**: Jellyfin has read-only access to prevent accidental modification of downloads

### Backup Strategy
- Restic used for encrypted remote backups to S3-compatible storage
- Environment variables stored in `/root/.restic_env`
- Multiple backup verification scripts (weekly/monthly)
- Entire incus storage volume backed up, ensuring complete system recovery capability
- **Note**: `/srv/torrents` intentionally excluded from backups (external storage for large media files)