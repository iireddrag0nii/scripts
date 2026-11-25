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

## Docker Installation Decision

The toolkit includes a read-only Docker installation planner.

Run:

    ./scripts/install-docker.sh --plan

For Docker daemon inspection when administrative access is required:

    sudo ./scripts/install-docker.sh --plan

Possible decisions:

- SKIP_INSTALL: An existing Docker installation is operational.
- MANUAL_REVIEW: The environment is unsupported, incomplete, conflicting, or cannot be verified.
- FRESH_CANDIDATE: No recognized Docker installation was found on an eligible Ubuntu host.

The decision engine checks installed packages, Docker and Compose availability,
supported Ubuntu releases, CPU architecture, and selected alternative runtimes.

Alternative runtime detection includes Snap Docker, Podman, nerdctl,
standalone containerd, and unmanaged Docker executables.

Detection is not exhaustive. Rootless installations, custom service configurations,
and installations outside the inspected locations may require additional investigation.

FRESH_CANDIDATE is an advisory result, not authorization to install.

The --install option is enabled with safety gates and interactive confirmation.

No software is installed or modified by the planner.

## Docker Endpoint Detection

The decision engine also checks for:

- Nonstandard DOCKER_HOST configurations
- Active Docker services for the current user
- Docker sockets under /run/user/<UID>/docker.sock

These conditions trigger MANUAL_REVIEW.

The standard system Docker socket does not independently
trigger a conflict warning.

Detection covers the executing account, not every account
on the machine.

Current-user socket detection has not yet received a
dedicated automated socket-fixture test.

Rootless and custom installations may require additional
manual inspection.

## Validated Docker Installation

The guarded Docker Engine installation workflow has
completed its first successful lab validation on
Ubuntu Server 22.04 AMD64.

The installer supports these modes:

    ./scripts/install-docker.sh --plan
    ./scripts/install-docker.sh --dry-run
    sudo ./scripts/install-docker.sh --install

Installation mode modifies the host and requires explicit
interactive confirmation. Use it only on an approved test
system with a verified recovery snapshot.

The installer refuses to install when the decision engine
reports SKIP_INSTALL or MANUAL_REVIEW.

See [Docker Installation Validation](DOCKER-VALIDATION.md)
for the full first-deployment record and limitations.

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
