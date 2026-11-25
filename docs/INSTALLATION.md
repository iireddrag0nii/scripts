# Installation and Prerequisites

## Development Status

Version 2.0 is in pre-release validation.

The toolkit includes guarded, interactive deployment for
Docker Engine, Portainer, Pi-hole, and WireGuard.

Each module has been validated individually on an Ubuntu
Server 22.04 AMD64 laboratory VM.

Final clean-host end-to-end testing remains pending.

## Intended Environment

The initial development target is Ubuntu Linux on x86_64
and ARM64 systems.

Initial validation environment:

- Ubuntu 22.04.5 LTS
- x86_64 architecture
- Docker Engine 29.10.1
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
interactive confirmation. Use it only on an approved system after reviewing
backups, recovery options, and installation risks.

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

Clone the repository and select the development branch:

    git clone https://github.com/iireddrag0nii/scripts.git
    cd scripts
    git switch development/v2

Run the read-only preflight assessment:

    ./scripts/preflight.sh

Launch the interactive toolkit:

    sudo ./toolkit.sh

The menu provides these deployment actions:

1. Check host readiness
2. Install Docker Engine
3. Deploy Portainer
4. Deploy Pi-hole
5. Deploy WireGuard
6. View deployment status
7. Exit

Deploy Docker Engine before the containerized services.

### Portainer

Portainer publishes HTTPS on localhost port 9443.

See [Portainer Deployment](PORTAINER.md).

### Pi-hole

Pi-hole publishes DNS on localhost port 5353
(TCP and UDP) and its web interface on port 8088.

The toolkit does not change host or router DNS settings.

See [Pi-hole Deployment](PIHOLE.md).

### WireGuard

WireGuard uses a configurable LAN bind address and
UDP port 51821.

The default tunnel subnet is 10.77.77.0/24.

The server restricts forwarding to other networks.
This is a tunnel-only laboratory configuration.

New deployments generate a local configuration file:

    compose/wireguard/.env

This file is excluded from Git and created with
restrictive permissions.

See [WireGuard Deployment](WIREGUARD.md).

### Repeat-run behavior

The toolkit detects existing service projects and
skips their installation rather than automatically
recreating containers or deleting persistent volumes.

Review the individual deployment guides before making
changes to an existing installation.

## Current validation limitations

- Full clean-host sequential deployment remains pending.
- Initial runtime testing used Ubuntu Server 22.04 AMD64.
- Other architectures require additional runtime testing.
- Recovery from interrupted installations requires review.
- WireGuard's default configuration is not a full-access VPN.
- Pinned images require scheduled security review.

The archived scripts under legacy/ are unmaintained
and should not be used as current production installers.
