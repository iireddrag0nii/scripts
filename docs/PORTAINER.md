# Portainer Community Edition Deployment

## Status

Initial Docker Compose implementation.

Configuration validation must pass before deployment.
Runtime validation is performed on a disposable lab VM.

## Components

- Portainer Community Edition
- Docker Compose project: hbtech-portainer
- Image channel: portainer/portainer-ce:lts
- HTTPS management: 127.0.0.1:9443
- Persistent volume: portainer_data

The image must be pinned to a tested version or digest
before a production-ready release.

## Security

Portainer accesses the Docker socket and therefore has
highly privileged control of the local Docker host.

The management interface binds to localhost by default.

Port 8000 is not published.

Do not expose the Docker socket over TCP.

## Validate

From the repository root:

    ./tests/test-portainer-compose.sh

## Deploy on a Lab VM

Deployment changes the Docker environment.

    sudo docker compose \
      -f compose/portainer/compose.yaml up -d

## Secure Remote Access

From Windows PowerShell, create an SSH tunnel:

    ssh -L 9443:127.0.0.1:9443 USER@VM_ADDRESS

Open:

    https://localhost:9443

The default self-signed certificate may produce a
browser certificate warning.

Complete initial administrator setup promptly.

## Verify

    sudo docker compose \
      -f compose/portainer/compose.yaml ps

    sudo docker compose \
      -f compose/portainer/compose.yaml logs --tail=50

    curl -kI https://127.0.0.1:9443

## Stop

    sudo docker compose \
      -f compose/portainer/compose.yaml down

This stops and removes the Compose-managed container
and network without deleting its named data volume.

Do not use down --volumes unless persistent data
deletion is explicitly intended.

## Limitations

Runtime deployment and persistence across recreation
must be validated before release.

Only deploy on systems you are authorized to administer.

## First Successful Runtime Validation

Test platform:
- Ubuntu Server 22.04.2 LTS
- AMD64
- Docker Engine 29.10.1
- Docker Compose 5.8.0
- Portainer Community Edition 2.45.4 LTS

Validation results:
- All six Compose configuration checks passed
- Portainer image downloaded successfully
- Container started successfully
- HTTPS endpoint returned HTTP 200
- Initial administrator setup completed
- Local Docker environment connected successfully
- Container recreation using --force-recreate succeeded
- Administrator configuration persisted
- Local Docker environment remained available
- HTTPS host binding remained localhost-only

Conclusion:

The Portainer Compose deployment passed its first end-to-end
runtime validation on the Ubuntu 22.04 AMD64 lab VM.

Additional operating systems, architectures, image versions,
and recovery scenarios remain untested.

## Interactive Toolkit Deployment Validation

Date: November 25, 2026
Platform: Ubuntu Server 22.04 AMD64
Toolkit revision: 627a01e

The existing Portainer Compose container was removed using
docker compose down. The persistent named volume was retained.

Portainer was redeployed using:

    sudo ./toolkit.sh

Menu selection:

    3. Deploy Portainer

Observed results:

- Compose configuration validation passed
- TCP 9443 conflict detection passed
- Explicit deployment confirmation was required
- Portainer container started successfully
- Existing named volume was preserved
- HTTPS remained bound to 127.0.0.1:9443
- HTTPS endpoint returned HTTP 200

New container creation time:

    2026-11-25T06:10:02Z

This validates the interactive deployment workflow using
an existing persistent data volume.

A completely fresh Portainer data-volume initialization
through the interactive menu remains untested.
