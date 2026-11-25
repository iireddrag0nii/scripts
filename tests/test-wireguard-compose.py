#!/usr/bin/env python3
"""Validate WireGuard Compose configuration without deploying."""

import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMPOSE = ROOT / "compose/wireguard/compose.yaml"

env = os.environ.copy()
env["WG_BIND_IP"] = "192.0.2.10"
env["WG_SERVER_URL"] = "192.0.2.10"

def check(condition, description):
    if not condition:
        print("[FAIL]", description)
        sys.exit(1)
    print("[PASS]", description)

result = subprocess.run(
    ["docker", "compose", "-f", str(COMPOSE),
     "config", "--format", "json"],
    env=env,
    capture_output=True,
    text=True,
    check=True,
)

config = json.loads(result.stdout)
service = config["services"]["wireguard"]

ports = service.get("ports", [])

check(
    len(ports) == 1
    and ports[0].get("host_ip") == "192.0.2.10"
    and str(ports[0].get("published")) == "51821"
    and ports[0].get("target") == 51820
    and ports[0].get("protocol") == "udp",
    "Only the configured UDP host port is published"
)

check(
    service.get("cap_add") == ["NET_ADMIN"]
    and not service.get("privileged", False),
    "NET_ADMIN is the only elevated capability"
)

check(
    any(
        volume.get("type") == "volume"
        and volume.get("target") == "/config"
        for volume in service.get("volumes", [])
    ),
    "Persistent WireGuard configuration volume"
)

environment = service.get("environment", {})

check(
    environment.get("SERVERPORT") == "51821"
    and environment.get("SERVERURL") == "192.0.2.10",
    "Peer endpoint configuration matches published port"
)

check(
    environment.get("ALLOWEDIPS") == "10.77.77.1/32"
    and environment.get("INTERNAL_SUBNET") == "10.77.77.0",
    "Lab-only peer routes and subnet configured"
)

check(
    environment.get("LOG_CONFS") == "false",
    "Peer configuration logging disabled"
)

check(
    config.get("name") == "hbtech-wireguard",
    "Isolated Compose project name"
)

print("All WireGuard Compose tests passed.")
