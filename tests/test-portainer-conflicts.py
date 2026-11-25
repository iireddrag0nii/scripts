#!/usr/bin/env python3
"""Safe mocked tests for Portainer host-port detection."""

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHECKER = ROOT / "scripts/check-portainer-conflicts.sh"

MOCK_DOCKER = """#!/usr/bin/env python3
import os
import sys

args = sys.argv[1:]

if args == ["info"]:
    sys.exit(int(os.environ.get("MOCK_DOCKER_FAIL", "0")))

if args == ["container", "ls", "-aq"]:
    print(os.environ.get("MOCK_IDS", ""))
    sys.exit(0)

if args and args[0] == "inspect":
    print(os.environ.get("MOCK_INSPECT", "[]"))
    sys.exit(0)

sys.exit(1)
"""

MOCK_SS = """#!/usr/bin/env python3
import os
print(os.environ.get("MOCK_SS", ""), end="")
"""


class PortainerConflictTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)

        directory = Path(self.temp.name)

        for name, contents in {
            "docker": MOCK_DOCKER,
            "ss": MOCK_SS,
        }.items():
            executable = directory / name
            executable.write_text(contents)
            executable.chmod(0o755)

        self.env = os.environ.copy()
        self.env["PATH"] = (
            str(directory) + os.pathsep + self.env["PATH"]
        )
        self.env.update({
            "MOCK_IDS": "",
            "MOCK_INSPECT": "[]",
            "MOCK_SS": "",
            "MOCK_DOCKER_FAIL": "0",
        })

    def run_checker(self):
        return subprocess.run(
            ["bash", str(CHECKER)],
            env=self.env,
            text=True,
            capture_output=True,
            timeout=15,
        )

    def container(self, internal_port, host_port):
        self.env["MOCK_IDS"] = "abc123"
        self.env["MOCK_INSPECT"] = json.dumps([{
            "Name": "/test-container",
            "HostConfig": {
                "PortBindings": {
                    internal_port: [{
                        "HostIp": "0.0.0.0",
                        "HostPort": str(host_port),
                    }]
                }
            },
        }])

    def test_free_port(self):
        result = self.run_checker()
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("[PASS]", result.stdout)

    def test_direct_port_conflict(self):
        self.container("9443/tcp", 9443)
        result = self.run_checker()
        self.assertEqual(result.returncode, 2)
        self.assertIn("/test-container", result.stdout)

    def test_remapped_port_conflict(self):
        self.container("8443/tcp", 9443)
        result = self.run_checker()
        self.assertEqual(result.returncode, 2)
        self.assertIn("/test-container", result.stdout)

    def test_udp_does_not_block_tcp(self):
        self.container("9443/udp", 9443)
        result = self.run_checker()
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_host_listener_conflict(self):
        self.env["MOCK_SS"] = (
            "LISTEN 0 4096 127.0.0.1:9443 0.0.0.0:*\n"
        )
        result = self.run_checker()
        self.assertEqual(result.returncode, 2)
        self.assertIn("already listening", result.stdout)

    def test_inaccessible_docker(self):
        self.env["MOCK_DOCKER_FAIL"] = "1"
        result = self.run_checker()
        self.assertEqual(result.returncode, 2)
        self.assertIn("daemon inaccessible", result.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)
