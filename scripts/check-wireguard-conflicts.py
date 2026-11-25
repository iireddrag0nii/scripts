#!/usr/bin/env python3
"""Read-only WireGuard host prerequisite checker."""

import argparse
import ipaddress
import json
import subprocess
import sys

PORT = "51821"
VPN_NETWORK = ipaddress.ip_network("10.77.77.0/24")


def run(*command):
    result = subprocess.run(
        command, capture_output=True, text=True
    )
    if result.returncode:
        raise RuntimeError(
            f"{' '.join(command)} failed: {result.stderr.strip()}"
        )
    return result.stdout


def check(bind_ip):
    addresses = json.loads(run("ip", "-j", "-4", "addr"))
    found = any(
        entry.get("local") == bind_ip
        for interface in addresses
        for entry in interface.get("addr_info", [])
    )
    if not found:
        raise ValueError(
            f"Bind address {bind_ip} is not assigned to this host"
        )

    routes = json.loads(
        run("ip", "-j", "-4", "route", "show", "table", "all")
    )
    for route in routes:
        destination = route.get("dst", "default")
        if destination == "default":
            continue
        try:
            network = ipaddress.ip_network(
                destination, strict=False
            )
        except ValueError:
            continue
        if network.overlaps(VPN_NETWORK):
            raise ValueError(
                f"VPN subnet overlaps existing route {network}"
            )

    run("docker", "info", "--format", "{{.ServerVersion}}")
    ids = run("docker", "container", "ls", "-aq").split()

    if ids:
        containers = json.loads(run("docker", "inspect", *ids))
        for container in containers:
            bindings = (
                container.get("HostConfig", {})
                .get("PortBindings") or {}
            )
            for internal, published in bindings.items():
                if not internal.endswith("/udp"):
                    continue
                for binding in published or []:
                    if str(binding.get("HostPort")) == PORT:
                        raise ValueError(
                            f"{container.get('Name')} reserves UDP {PORT}"
                        )

    listeners = run("ss", "-H", "-lun")
    for line in listeners.splitlines():
        columns = line.split()

        if len(columns) < 4:
            raise ValueError("Unexpected UDP listener output.")

        local = columns[3]

        if local.rsplit(":", 1)[-1] == PORT:
            raise ValueError(
                f"Host UDP {PORT} is already bound: {local}"
            )

    print("[PASS] WireGuard bind IP belongs to host.")
    print("[PASS] No detected VPN subnet route overlaps.")
    print(f"[PASS] No detected UDP {PORT} conflicts.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--bind-ip", required=True)
    args = parser.parse_args()

    try:
        bind_ip = ipaddress.ip_address(args.bind_ip)
        if bind_ip.version != 4 or bind_ip.is_unspecified:
            raise ValueError("A specific IPv4 bind address is required")
        check(str(bind_ip))
    except (RuntimeError, ValueError, OSError) as error:
        print(f"[BLOCKED] {error}")
        return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
