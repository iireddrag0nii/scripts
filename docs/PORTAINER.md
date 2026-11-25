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
