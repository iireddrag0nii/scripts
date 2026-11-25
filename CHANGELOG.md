# Changelog

All notable changes to the HBTECHSOLUTIONS Infrastructure
Deployment Toolkit will be documented here.

## Unreleased - Version 2.0 Development

### Added

- Development branch for version 2.0
- Legacy installation-script archive
- Read-only host readiness assessment
- Operating system and architecture detection
- Docker CLI and Compose availability checks
- Disk-space assessment
- TCP and UDP listener inspection
- Basic Docker published-port inventory
- Project documentation and security guidance

### Docker Installation Safety

- Added a read-only Docker readiness assessment
- Added Docker installation decision engine
- Added a non-destructive installation planner
- Added Ubuntu release and CPU architecture checks
- Added installed runtime package inventory
- Added alternative runtime detection for Snap Docker, Podman, nerdctl, and standalone containerd
- Added detection for Docker executables without recognized packages
- Added automated decision and installer safety tests
- Verified existing Docker CE installation is not selected for installation

### Docker Endpoint Safety

- Added detection for nonstandard DOCKER_HOST endpoints
- Added current-user Docker service detection
- Added current-user Docker socket detection
- Added automated tests for custom endpoints and user-level services
- Verified standard Docker CE remains classified as SKIP_INSTALL
- Kept all installation operations disabled

### First Real Docker Installation Validation

- Validated guarded installation on Ubuntu Server 22.04 AMD64
- Verified FRESH_CANDIDATE on an initially Docker-free VM
- Installed Docker Engine 29.10.1 from Docker's official APT repository
- Verified Docker Compose 5.8.0 and Buildx 0.39.1
- Verified containerd 2.4.2
- Successfully executed the Docker hello-world container
- Verified a second installer execution returned SKIP_INSTALL
- Confirmed the installer left general Ubuntu package upgrades outside its scope

Validation remains limited to one fresh Ubuntu 22.04 AMD64 VM.
Other operating systems, architectures, and recovery scenarios require testing.

### Fixed

- Corrected local listening port detection in ss output
- Corrected Docker inventory line formatting

### Known Limitations

- Docker inventory and port conflict checks are separate
- Docker container ownership is not included in port warnings
- Interface-specific conflict detection is incomplete
- Docker inventory requires appropriate daemon permissions
- Automated service installation is not implemented
- Compose deployment stacks are not yet available

### Planned

- Integrated Docker port ownership detection
- Docker installation and validation workflow
- Independent Portainer deployment
- Independent WireGuard / wg-easy deployment
- Independent Pi-hole deployment
- Automated deployment validation
- Expanded testing and troubleshooting documentation

## Version 1 - Historical Scripts

The original repository contained scripts for:

- Docker installation
- Portainer deployment
- WireGuard / wg-easy installation
- Pi-hole installation
- Password-generation assistance

These scripts are preserved in the legacy directory.

They are unmaintained and are not recommended
for use on current production systems.
