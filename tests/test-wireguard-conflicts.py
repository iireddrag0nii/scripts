#!/usr/bin/env python3
"""Mocked WireGuard prerequisite tests. No host changes."""

import importlib.util
import json
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/check-wireguard-conflicts.py"

spec = importlib.util.spec_from_file_location("wg_checker", SCRIPT)
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)


class WireGuardConflictTests(unittest.TestCase):
    def setUp(self):
        self.addresses = [{
            "ifname": "ens18",
            "addr_info": [{"local": "192.168.4.82"}]
        }]
        self.routes = [
            {"dst": "192.168.4.0/22"},
            {"dst": "172.17.0.0/16"}
        ]
        self.containers = []
        self.listeners = ""
        self.docker_available = True

    def mock_run(self, *args):
        if args[:3] == ("ip", "-j", "-4"):
            if args[3] == "addr":
                return json.dumps(self.addresses)
            return json.dumps(self.routes)

        if args[:2] == ("docker", "info"):
            if not self.docker_available:
                raise RuntimeError("Docker daemon inaccessible")
            return "29.10.1"

        if args[:3] == ("docker", "container", "ls"):
            return "abc123" if self.containers else ""

        if args[:2] == ("docker", "inspect"):
            return json.dumps(self.containers)

        if args[0] == "ss":
            return self.listeners

        raise AssertionError(f"Unexpected command: {args}")

    def execute(self):
        with patch.object(checker, "run", self.mock_run):
            checker.check("192.168.4.82")

    def test_valid_host(self):
        self.execute()

    def test_invalid_bind_ip(self):
        with patch.object(checker, "run", self.mock_run):
            with self.assertRaisesRegex(
                ValueError, "not assigned"
            ):
                checker.check("192.168.4.99")

    def test_subnet_overlap(self):
        self.routes.append({"dst": "10.77.77.0/24"})
        with self.assertRaisesRegex(ValueError, "overlaps"):
            self.execute()

    def test_docker_udp_conflict(self):
        self.containers = [{
            "Name": "/existing-vpn",
            "HostConfig": {
                "PortBindings": {
                    "51820/udp": [{
                        "HostIp": "0.0.0.0",
                        "HostPort": "51821"
                    }]
                }
            }
        }]
        with self.assertRaisesRegex(ValueError, "reserves"):
            self.execute()

    def test_host_udp_listener(self):
        self.listeners = (
            "UNCONN 0 0 0.0.0.0:51821 0.0.0.0:*\n"
        )
        with self.assertRaisesRegex(ValueError, "bound"):
            self.execute()

    def test_docker_unavailable(self):
        self.docker_available = False
        with self.assertRaisesRegex(
            RuntimeError, "inaccessible"
        ):
            self.execute()


if __name__ == "__main__":
    unittest.main(verbosity=2)
