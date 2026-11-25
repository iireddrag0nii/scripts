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
