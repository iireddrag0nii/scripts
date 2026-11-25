#!/usr/bin/env python3
import json
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
compose = root / "compose/pihole/compose.yaml"

result = subprocess.run(
    ["docker", "compose", "-f", str(compose),
     "config", "--format", "json"],
    capture_output=True,
    text=True,
    check=True
)

config = json.loads(result.stdout)
service = config["services"]["pihole"]

def check(condition, message):
    if not condition:
        print("[FAIL]", message)
        sys.exit(1)
    print("[PASS]", message)

ports = {
    (
        str(p.get("host_ip")),
        str(p.get("published")),
        str(p.get("target")),
        str(p.get("protocol"))
    )
    for p in service.get("ports", [])
}

expected = {
    ("127.0.0.1", "5353", "53", "tcp"),
    ("127.0.0.1", "5353", "53", "udp"),
    ("127.0.0.1", "8088", "80", "tcp"),
}

check(ports == expected,
      "Only expected localhost ports published")

check(
    any(
        v.get("target") == "/etc/pihole"
        and v.get("type") == "volume"
        for v in service.get("volumes", [])
    ),
    "Persistent Pi-hole configuration volume"
)

env = service.get("environment", {})

check(
    env.get("FTLCONF_dns_listeningMode") == "ALL",
    "Docker bridge DNS listening mode configured"
)

check(
    "FTLCONF_webserver_api_password" not in env,
    "No hardcoded administrator password"
)

check(
    not service.get("privileged", False)
    and not service.get("cap_add"),
    "No unnecessary elevated capabilities"
)

check(
    config.get("name") == "hbtech-pihole",
    "Isolated Compose project name"
)

print("All Pi-hole configuration tests passed.")
