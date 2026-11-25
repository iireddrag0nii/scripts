#!/usr/bin/env python3
"""Static checks for the restricted WireGuard server template."""

import json
import os
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "compose/wireguard/server.conf"
COMPOSE = ROOT / "compose/wireguard/compose.yaml"


class WireGuardIsolationTests(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.template = TEMPLATE.read_text()

        env = os.environ.copy()
        env["WG_BIND_IP"] = "192.0.2.10"
        env["WG_SERVER_URL"] = "192.0.2.10"

        result = subprocess.run(
            [
                "docker", "compose",
                "-f", str(COMPOSE),
                "config", "--format", "json"
            ],
            env=env,
            capture_output=True,
            text=True,
            check=True
        )

        cls.service = json.loads(
            result.stdout
        )["services"]["wireguard"]

    def test_template_exists(self):
        self.assertTrue(TEMPLATE.is_file())

    def test_forwarding_is_denied(self):
        self.assertIn(
            "iptables -I FORWARD -i %i -j DROP",
            self.template
        )
        self.assertIn(
            "iptables -I FORWARD -o %i -j DROP",
            self.template
        )

    def test_no_forwarding_accept_rules(self):
        for line in self.template.splitlines():
            if line.startswith(("PostUp =", "PostDown =")):
                self.assertNotIn(
                    "-j ACCEPT", line
                )

    def test_no_masquerade(self):
        self.assertNotIn(
            "MASQUERADE", self.template.upper()
        )

    def test_input_restriction(self):
        self.assertIn(
            "iptables -I INPUT -i %i ! -d ${INTERFACE}.1 -j DROP",
            self.template
        )

    def test_cleanup_rules(self):
        self.assertIn(
            "iptables -D INPUT",
            self.template
        )
        self.assertIn(
            "iptables -D FORWARD",
            self.template
        )

    def test_template_read_only_mount(self):
        mounts = self.service.get("volumes", [])
        matching = [
            mount for mount in mounts
            if mount.get("target")
            == "/config/templates/server.conf"
        ]
        self.assertEqual(len(matching), 1)
        self.assertTrue(matching[0].get("read_only"))

    def test_peer_template_has_no_dns_override(self):
        peer = (ROOT / "compose/wireguard/peer.conf").read_text()
        self.assertNotIn("DNS =", peer)
        self.assertIn("AllowedIPs = ${ALLOWEDIPS}", peer)
        self.assertIn("Endpoint = ${SERVERURL}:${SERVERPORT}", peer)

    def test_peer_template_read_only_mount(self):
        mounts = self.service.get("volumes", [])
        matching = [
            mount for mount in mounts
            if mount.get("target") == "/config/templates/peer.conf"
        ]
        self.assertEqual(len(matching), 1)
        self.assertTrue(matching[0].get("read_only"))

    def test_no_privileged_container(self):
        self.assertFalse(
            self.service.get("privileged", False)
        )
        self.assertEqual(
            self.service.get("cap_add"),
            ["NET_ADMIN"]
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
