# Installation and Prerequisites

## Development Status

Infrastructure Deployment Toolkit v2.0 is under development.

The currently available component is the read-only host
readiness assessment. Automated installation and deployment
are not yet implemented.

## Intended Environment

The initial development target is Ubuntu Linux on x86_64
and ARM64 systems.

Initial validation environment:

- Ubuntu 22.04.5 LTS
- x86_64 architecture
- Docker Engine 29.10.0
- Docker Compose 5.8.0

These are test-environment details, not minimum supported
versions or a complete compatibility matrix.

## Prerequisites

- Linux host with administrative access
- Adequate available storage
- Network connectivity for software installation
- Understanding of existing network services and ports
- Backup or snapshot before modifying existing infrastructure

Use a disposable virtual machine for deployment testing.

## Docker Engine

Follow the official Ubuntu installation documentation:

https://docs.docker.com/engine/install/ubuntu/

Review existing Docker installations and package conflicts
before changing a host that already runs containers.

## Docker Compose

Official Compose installation documentation:

https://docs.docker.com/compose/install/linux/

Verify installation:

    docker --version
    docker compose version

## Run the Preflight Assessment

From the repository root:

    bash -n scripts/preflight.sh
    ./scripts/preflight.sh

For a more complete Docker inventory when daemon access
requires administrative privileges:

    sudo ./scripts/preflight.sh

The script does not install software or modify services.

## Current Checks

- Operating system identification
- CPU architecture
- Docker CLI availability
- Docker Compose availability
- Available disk space
- Selected TCP and UDP listeners
- Basic Docker published-port inventory

## Understanding Results

PASS indicates a check succeeded under the current logic.

WARN indicates a possible conflict or unavailable information.

FAIL indicates a required assessment could not complete.

Port ownership and interface-aware conflict detection
are still planned improvements.

A successful assessment does not guarantee that a
deployment will work.

## Troubleshooting

Inspect host listeners:

    sudo ss -lntup

Inspect Docker-published ports:

    sudo docker ps --format 'table {{.Names}}\t{{.Ports}}'

Verify the Docker daemon:

    sudo docker info

Do not stop or remove existing services merely to
make a readiness assessment pass.

## Deployment

The Docker installation workflow and independent Compose
stacks for Portainer, wg-easy, and Pi-hole will be added
after implementation and validation.

Do not use the archived scripts in legacy/ as current
production installers.
