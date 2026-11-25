#!/usr/bin/env python3
"""WireGuard menu safety tests. No containers deployed."""

import os
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLKIT = ROOT / "toolkit.sh"


class WireGuardMenuTests(unittest.TestCase):

    def test_bash_syntax(self):
        result = subprocess.run(
            ["bash", "-n", str(TOOLKIT)],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_menu_lists_wireguard(self):
        result = subprocess.run(
            [str(TOOLKIT)],
            input="7\n",
            capture_output=True,
            text=True,
            timeout=10,
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn("5. Deploy WireGuard", result.stdout)

    @unittest.skipIf(
        os.geteuid() == 0,
        "Non-root test requires an unprivileged user",
    )
    def test_non_root_deployment_blocked(self):
        result = subprocess.run(
            [str(TOOLKIT)],
            input="5\n7\n",
            capture_output=True,
            text=True,
            timeout=10,
        )

        self.assertEqual(result.returncode, 0)
        self.assertIn(
            "[BLOCKED] Use sudo to deploy WireGuard.",
            result.stdout,
        )
        self.assertIn(
            "[ERROR] Action failed with exit code 2.",
            result.stdout,
        )
        self.assertNotIn(
            "Type DEPLOY WIREGUARD",
            result.stdout,
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
