# HBTECHSOLUTIONS Infrastructure Deployment Toolkit

A modular deployment toolkit for Linux homelabs, infrastructure labs, and self-hosted environments.

**Version:** 2.0 (in development)  
**Status:** Pre-release — service deployment automation is not yet available.

## Overview

This project began as a collection of scripts designed to simplify installing Docker, Portainer, WireGuard, and Pi-hole.

Version 2.0 focuses on:

- Reproducible deployments
- Modular Docker Compose configurations
- Secure credential management
- Readiness assessments before installation
- Deployment validation and troubleshooting
- Documentation and recovery procedures

## Project Status

| Component | Status |
|---|---|
| Original scripts archive | Complete |
| Read-only preflight assessment | Initial version validated |
| Docker published-port inventory | Basic version implemented |
| Docker installation workflow | Planned |
| Portainer Compose deployment | Planned |
| WireGuard / wg-easy deployment | Planned |
| Pi-hole Compose deployment | Planned |
| Automated deployment validation | Planned |

**No production-ready service installer is included in v2 yet.**

## Quick Start

Clone the repository using:

`git clone https://github.com/iireddrag0nii/scripts.git`

Enter the repository:

`cd scripts`

Switch to the development branch when it has been published:

`git switch development/v2`

Check the preflight script's syntax:

`bash -n scripts/preflight.sh`

Run the read-only assessment:

`./scripts/preflight.sh`

To include the Docker container inventory when elevated permissions are required:

`sudo ./scripts/preflight.sh`

The script does not install software or modify running services.

A successful assessment does not guarantee deployment compatibility.

## Planned Components

### Docker Engine

Documented installation and verification workflow.

### Portainer

Independent container-management deployment.

### WireGuard / wg-easy

VPN deployment with configurable networking and restricted administration.

### Pi-hole

Containerized DNS filtering with persistent configuration.

Each deployment will be optional.

## Documentation

- [Installation and prerequisites](docs/INSTALLATION.md)
- [Security guidance](SECURITY.md)
- [Change history](CHANGELOG.md)
- [Original scripts](legacy/README.md)

## Legacy Scripts

The original installation scripts are preserved in the `legacy/` directory for historical reference.

They are unmaintained and should not be used for current production deployments.

## Development and Validation

Development uses isolated lab environments and read-only assessments of existing Linux systems.

All deployment components must be tested before being described as supported.

## Project Website

https://www.hbtechsolutions.com

## Disclaimer

This toolkit is provided for education and authorized infrastructure administration.

Review all commands, configurations, and security implications before use.
