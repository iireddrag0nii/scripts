#!/usr/bin/env bash
set -euo pipefail

echo "=== Portainer Port Conflict Check ==="

if ! command -v docker >/dev/null 2>&1; then
    echo "[BLOCKED] Docker CLI unavailable."
    exit 2
fi

if ! docker info >/dev/null 2>&1; then
    echo "[BLOCKED] Docker daemon inaccessible."
    exit 2
fi

# Check all Docker containers, including stopped containers.
if ! ids="$(docker container ls -aq)"; then
    echo "[BLOCKED] Cannot enumerate Docker containers."
    exit 2
fi

if [[ -n "$ids" ]]; then
    # Word splitting is intentional for container IDs.
    if ! docker inspect $ids |
        python3 -c '
import json
import sys

containers = json.load(sys.stdin)
conflicts = []

for container in containers:
    bindings = container.get("HostConfig", {}).get("PortBindings") or {}

    for container_port, published in bindings.items():
        if not container_port.endswith("/tcp"):
            continue
        for binding in published or []:
            if binding.get("HostPort") == "9443":
                conflicts.append(container.get("Name", "unknown"))

if conflicts:
    for name in conflicts:
        print("[BLOCKED] Docker container reserves TCP 9443:", name)
    sys.exit(2)
'; then
        exit 2
    fi
fi

# Also check host processes that may not be Docker containers.
if ! command -v ss >/dev/null 2>&1; then
    echo "[BLOCKED] ss utility unavailable."
    exit 2
fi

if ! listeners="$(ss -H -ltn '( sport = :9443 )')"; then
    echo "[BLOCKED] Unable to inspect TCP listeners."
    exit 2
fi

if [[ -n "$listeners" ]]; then
    echo "[BLOCKED] Host TCP port 9443 already listening."
    exit 2
fi

echo "[PASS] No detected TCP 9443 conflicts."
