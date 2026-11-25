# Changelog

All notable changes to the HBTECHSOLUTIONS Infrastructure
Deployment Toolkit will be documented here.

## Version 2.0 Pre-Release Milestones

The four core deployment modules have been implemented
and individually validated on an Ubuntu Server 22.04
AMD64 laboratory virtual machine.

Final clean-host end-to-end validation remains pending.

### Infrastructure Deployment

- Implemented interactive deployment menu
- Added guarded Docker Engine installation
- Added independent Portainer Compose deployment
- Added independent Pi-hole Compose deployment
- Added restricted WireGuard VPN deployment
- Added existing-installation detection for each module
- Added explicit deployment confirmation
- Added persistent service configuration

### Security and Reliability

- Implemented TCP and UDP port-conflict checks
- Added Docker runtime and host readiness validation
- Restricted Portainer management access to localhost
- Restricted Pi-hole DNS and web ports to localhost
- Added WireGuard tunnel-only forwarding rules
- Added WireGuard LAN endpoint validation
- Added safeguards against overwriting VPN configuration
- Added local WireGuard endpoint configuration with
  restrictive file permissions and Git exclusion
- Pinned service images to reviewed immutable digests

### Runtime Validation

- Installed Docker Engine on a fresh Ubuntu VM
- Verified Docker repeat-run detection
- Validated Portainer HTTPS and persistent configuration
- Validated Pi-hole DNS resolution and filtering
- Established a Windows-to-WireGuard VPN handshake
- Verified WireGuard tunnel endpoint connectivity
- Verified blocked forwarding toward test Docker networks
- Verified WireGuard identity persistence after recreation
- Verified existing WireGuard deployment is skipped

### Automated Testing

- Added Docker installation and decision tests
- Added Portainer configuration and conflict tests
- Added Pi-hole configuration and conflict tests
- Added WireGuard configuration and isolation tests
- Added WireGuard deployment safeguard tests
- Added WireGuard endpoint-persistence tests
- Added menu regression tests

### Documentation

- Updated the README for the current v2.0 architecture
- Documented Docker installation and validation
- Documented Portainer deployment
- Documented Pi-hole deployment and DNS verification
- Documented WireGuard deployment and security boundaries
- Preserved the original scripts under legacy/

### Outstanding Release Validation

- Complete clean-host installation through the menu
- Verify all components together after fresh deployment
- Validate failed-installation recovery procedures
- Finalize supported platform and architecture claims
- Review security guidance and documentation
- Merge development/v2 into main after approval

The development history below is retained for reference.
Earlier statements describing service installation as
planned or disabled have been superseded by the
pre-release milestones above.

---

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
