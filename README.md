# HBTECHSOLUTIONS Infrastructure Deployment Toolkit

A modular infrastructure deployment toolkit for Linux
homelabs, engineering labs, and self-hosted environments.

**Version:** 2.0 (pre-release)
**Branch:** development/v2
**Status:** Four core modules implemented and lab-validated.
Final clean-host installation testing is pending.

## Overview

The HBTECHSOLUTIONS Infrastructure Deployment Toolkit
provides guarded, optional installation workflows for:

- Docker Engine and Docker Compose
- Portainer Community Edition
- Pi-hole DNS filtering
- WireGuard VPN

Each component is deployed independently through an
interactive Bash menu.

The toolkit focuses on deployment safety, persistent
configuration, repeat-run protection, and validation.

## Current Module Status

| Component | Status |
|---|---|
| Host readiness assessment | Implemented and tested |
| Docker Engine installation | Lab-validated |
| Portainer deployment | Lab-validated |
| Pi-hole deployment | Lab-validated |
| WireGuard deployment | Lab-validated |
| Automated regression tests | Implemented |
| Clean-host end-to-end testing | Pending |
| Public v2.0 release | Pending |

The individual modules have been tested on Ubuntu Server
22.04 AMD64. Additional distributions and architectures
have not yet received equivalent runtime validation.

## Quick Start

Clone the repository:

    git clone https://github.com/iireddrag0nii/scripts.git

Enter the repository and select the development branch:

    cd scripts
    git switch development/v2

Run a host readiness assessment:

    ./scripts/preflight.sh

Launch the interactive toolkit:

    ./toolkit.sh

Elevated privileges are required for service deployments:

    sudo ./toolkit.sh

### Interactive Menu

    1. Check host readiness
    2. Install Docker Engine
    3. Deploy Portainer
    4. Deploy Pi-hole
    5. Deploy WireGuard
    6. View deployment status
    7. Exit

Review deployment plans, prerequisites, port bindings,
and confirmation prompts before installing services.

Do not run the toolkit on a production host without
reviewing its configuration and security implications.

## Deployment Modules

### Docker Engine

Guarded installation through Docker's official Ubuntu
APT repository.

Includes runtime detection, compatibility checks,
manual-review decisions, and repeat-run protection.

### Portainer

Container-management interface with persistent storage.

The HTTPS management port is published to localhost.
Administrator access to the Docker socket is sensitive
and must be treated as host-level administrative access.

### Pi-hole

Containerized DNS filtering with persistent settings.

The default configuration publishes DNS and the web
dashboard to localhost only.

It does not automatically change host or router DNS.

### WireGuard

Containerized VPN server using LinuxServer.io's image.

The default lab configuration uses UDP port 51821,
persistent VPN keys, restricted forwarding, and
an explicit LAN bind address.

VPN client configuration and private keys must
never be committed to the repository.

## Container Image Management

Service images are pinned to immutable registry digests.

This prevents automatic image changes during deployment.

Pinned images must be periodically reviewed for
security updates. Updating a digest requires
validation of the replacement image.

## Security and Deployment Boundaries

- Review configurations before deployment
- No automatic router port forwarding
- No automatic host DNS changes
- Existing toolkit deployments are detected and skipped
- Persistent data volumes are retained
- WireGuard endpoint settings remain local to each host
- VPN private keys must not be publicly shared
- Service deployment requires explicit confirmation

The toolkit is intended for authorized infrastructure
administration, education, and controlled lab use.

It is not yet certified or hardened for production use.

## Documentation

- [Installation and prerequisites](docs/INSTALLATION.md)
- [Docker validation](docs/DOCKER-VALIDATION.md)
- [Portainer guide](docs/PORTAINER.md)
- [Pi-hole guide](docs/PIHOLE.md)
- [WireGuard guide](docs/WIREGUARD.md)
- [Release validation checklist](docs/RELEASE-VALIDATION.md)
- [Security guidance](SECURITY.md)
- [Changelog](CHANGELOG.md)
- [Legacy scripts](legacy/README.md)

## Legacy Scripts

The original repository scripts are preserved under
legacy/ for historical reference.

They are unmaintained and should not be used for
current production deployments.

## Release Validation

Before the public v2.0 release, the toolkit will undergo
a complete clean-host installation test covering:

1. Ubuntu readiness and Docker installation
2. Portainer deployment and persistence
3. Pi-hole DNS filtering and persistence
4. WireGuard VPN connectivity and isolation
5. Repeat-run behavior and deployment safeguards
6. Documentation and recovery procedures

The release will remain in development until
these checks are complete.

## Project Website

https://www.hbtechsolutions.com

## Disclaimer

Provided as-is for educational and authorized
infrastructure administration purposes.

Review all commands and security implications before use.
