#!/usr/bin/env bash
set -euo pipefail

echo "=== Pi-hole Port Conflict Check ==="

command -v docker >/dev/null 2>&1 || {
    echo "[BLOCKED] Docker CLI unavailable."
    exit 2
}

docker info >/dev/null 2>&1 || {
    echo "[BLOCKED] Docker daemon inaccessible."
    exit 2
}

command -v ss >/dev/null 2>&1 || {
    echo "[BLOCKED] ss utility unavailable."
    exit 2
}

command -v python3 >/dev/null 2>&1 || {
    echo "[BLOCKED] Python unavailable."
    exit 2
}

ids="$(docker container ls -aq)" || {
    echo "[BLOCKED] Cannot enumerate Docker containers."
    exit 2
}

if [[ -n "$ids" ]]; then
    # Docker IDs are hexadecimal; splitting is intentional.
    if ! docker inspect $ids | python3 -c '
import json
import sys

wanted = {
    ("5353", "tcp"),
    ("5353", "udp"),
    ("8088", "tcp"),
}

try:
    containers = json.load(sys.stdin)
except (ValueError, TypeError):
    print("[BLOCKED] Invalid Docker inspection data.")
    sys.exit(2)

conflicts = []

for container in containers:
    bindings = (
        container.get("HostConfig", {})
        .get("PortBindings") or {}
    )

    for internal, published in bindings.items():
        if "/" not in internal:
            continue

        protocol = internal.rsplit("/", 1)[1]

        for binding in published or []:
            port = str(binding.get("HostPort", ""))
            if (port, protocol) in wanted:
                name = container.get("Name", "unknown")
                conflicts.append((name, port, protocol))

if conflicts:
    for name, port, protocol in conflicts:
        print(
            f"[BLOCKED] {name} reserves "
            f"{port}/{protocol}"
        )
    sys.exit(2)
'; then
        exit 2
    fi
fi

for port in 5353 8088; do
    if ! listeners="$(ss -H -ltn "( sport = :$port )")"; then
        echo "[BLOCKED] TCP listener inspection failed."
        exit 2
    fi

    if [[ -n "$listeners" ]]; then
        echo "[BLOCKED] TCP $port is already listening."
        exit 2
    fi
done

if ! listeners="$(ss -H -lun '( sport = :5353 )')"; then
    echo "[BLOCKED] UDP listener inspection failed."
    exit 2
fi

if [[ -n "$listeners" ]]; then
    echo "[BLOCKED] UDP 5353 is already bound."
    exit 2
fi

echo "[PASS] No detected Pi-hole port conflicts."
