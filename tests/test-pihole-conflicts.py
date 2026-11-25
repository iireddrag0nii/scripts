#!/usr/bin/env python3
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHECKER = ROOT / "scripts/check-pihole-conflicts.sh"

DOCKER_MOCK = """#!/usr/bin/env python3
import os, sys
args = sys.argv[1:]
if args == ["info"]:
    sys.exit(int(os.environ.get("FAIL_DOCKER", "0")))
if args == ["container", "ls", "-aq"]:
    print(os.environ.get("MOCK_IDS", ""))
    sys.exit(0)
if args and args[0] == "inspect":
    print(os.environ.get("MOCK_INSPECT", "[]"))
    sys.exit(0)
sys.exit(1)
"""

SS_MOCK = """#!/usr/bin/env python3
import os, sys
args = " ".join(sys.argv[1:])
if "-lun" in args and ":5353" in args:
    print(os.environ.get("UDP_5353", ""), end="")
elif "-ltn" in args and ":5353" in args:
    print(os.environ.get("TCP_5353", ""), end="")
elif "-ltn" in args and ":8088" in args:
    print(os.environ.get("TCP_8088", ""), end="")
"""


class PiHoleConflictTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        directory = Path(self.temp.name)

        for name, content in {
            "docker": DOCKER_MOCK,
            "ss": SS_MOCK,
        }.items():
            path = directory / name
            path.write_text(content)
            path.chmod(0o755)

        self.env = os.environ.copy()
        self.env["PATH"] = str(directory) + ":" + self.env["PATH"]
        self.env.update({
            "MOCK_IDS": "",
            "MOCK_INSPECT": "[]",
            "FAIL_DOCKER": "0",
            "UDP_5353": "",
            "TCP_5353": "",
            "TCP_8088": "",
        })

    def run_checker(self):
        return subprocess.run(
            ["bash", str(CHECKER)],
            env=self.env,
            capture_output=True,
            text=True,
            timeout=15,
        )

    def reserve(self, internal, host_port):
        self.env["MOCK_IDS"] = "abc123"
        self.env["MOCK_INSPECT"] = json.dumps([{
            "Name": "/conflicting-service",
            "HostConfig": {
                "PortBindings": {
                    internal: [{
                        "HostIp": "0.0.0.0",
                        "HostPort": str(host_port)
                    }]
                }
            }
        }])

    def test_free_ports(self):
        self.assertEqual(self.run_checker().returncode, 0)

    def test_dns_tcp_conflict(self):
        self.reserve("53/tcp", 5353)
        self.assertEqual(self.run_checker().returncode, 2)

    def test_dns_udp_conflict(self):
        self.reserve("53/udp", 5353)
        self.assertEqual(self.run_checker().returncode, 2)

    def test_web_port_conflict(self):
        self.reserve("80/tcp", 8088)
        self.assertEqual(self.run_checker().returncode, 2)

    def test_remapped_port_conflict(self):
        self.reserve("8053/tcp", 5353)
        self.assertEqual(self.run_checker().returncode, 2)

    def test_tcp_listener(self):
        self.env["TCP_8088"] = "LISTEN 0 128 0.0.0.0:8088\n"
        self.assertEqual(self.run_checker().returncode, 2)

    def test_udp_listener(self):
        self.env["UDP_5353"] = "UNCONN 0 0 0.0.0.0:5353\n"
        self.assertEqual(self.run_checker().returncode, 2)

    def test_docker_unavailable(self):
        self.env["FAIL_DOCKER"] = "1"
        self.assertEqual(self.run_checker().returncode, 2)


if __name__ == "__main__":
    unittest.main(verbosity=2)
