#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE="$ROOT/compose/portainer/compose.yaml"

if ! command -v docker >/dev/null 2>&1; then
    echo "[FAIL] Docker CLI unavailable"
    exit 1
fi

echo "=== Portainer Compose Validation ==="

docker compose -f "$COMPOSE" config --quiet
echo "[PASS] Compose syntax"

docker compose -f "$COMPOSE" config --format json |
python3 -c '
import json
import sys

config = json.load(sys.stdin)
service = config["services"]["portainer"]

def check(condition, description):
    if not condition:
        print("[FAIL]", description)
        sys.exit(1)
    print("[PASS]", description)

ports = service.get("ports", [])

check(
    len(ports) == 1 and
    ports[0].get("host_ip") == "127.0.0.1" and
    str(ports[0].get("published")) == "9443" and
    ports[0].get("target") == 9443 and
    ports[0].get("protocol") == "tcp",
    "HTTPS published to localhost only"
)

volumes = service.get("volumes", [])

check(
    any(
        v.get("type") == "volume" and
        v.get("target") == "/data"
        for v in volumes
    ),
    "Persistent Portainer data volume"
)

check(
    any(
        v.get("source") == "/var/run/docker.sock" and
        v.get("target") == "/var/run/docker.sock"
        for v in volumes
    ),
    "Docker socket mount explicitly configured"
)

check(
    service.get("restart") == "unless-stopped",
    "Restart policy configured"
)

check(
    config.get("name") == "hbtech-portainer",
    "Isolated Compose project name"
)

print("All Portainer configuration tests passed.")
'
