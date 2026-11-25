#!/usr/bin/env python3
"""Test WireGuard deployment decisions without accessing Docker."""

import os
import shlex
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLKIT = ROOT / "toolkit.sh"

source = TOOLKIT.read_text()
start = source.index("wireguard_deploy() {")
end = source.index("\ndocker_install_menu() {", start)
function = source[start:end]

# Bypass the root check ONLY in this isolated test harness.
# Never modify the real toolkit's privilege check.
root_check = "if (( EUID != 0 )); then"
assert function.count(root_check) == 1
function = function.replace(root_check, "if false; then", 1)


class WireGuardDeploymentTests(unittest.TestCase):

    def execute(self, existing=False, user_input=""):
        with tempfile.TemporaryDirectory() as directory:
            log = Path(directory) / "docker.log"

            harness = f"""
set -euo pipefail

ROOT={shlex.quote(str(ROOT))}
WIREGUARD={shlex.quote(str(ROOT / "compose/wireguard/compose.yaml"))}

docker() {{
    printf '%s\\n' "$*" >> "$MOCK_LOG"

    if [[ "$*" == "info" ]]; then
        return 0
    fi

    if [[ "$*" == *" ps -a -q" ]]; then
        if [[ "$MOCK_EXISTING" == "1" ]]; then
            echo "mock-container-id"
        fi
        return 0
    fi

    return 0
}}

python3() {{
    return 0
}}

{function}

wireguard_deploy
"""

            env = os.environ.copy()
            env["MOCK_LOG"] = str(log)
            env["MOCK_EXISTING"] = "1" if existing else "0"

            result = subprocess.run(
                ["bash", "-c", harness],
                input=user_input,
                capture_output=True,
                text=True,
                env=env,
                timeout=10,
            )

            commands = log.read_text() if log.exists() else ""
            return result, commands

    def test_existing_installation_is_skipped(self):
        result, commands = self.execute(existing=True)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(
            "[SKIP] Toolkit WireGuard project already exists.",
            result.stdout,
        )
        self.assertIn("ps -a -q", commands)
        self.assertNotIn("up -d", commands)
        self.assertNotIn("config --quiet", commands)
        self.assertNotIn("Type DEPLOY WIREGUARD", result.stdout)

    def test_cancelled_installation_does_not_deploy(self):
        result, commands = self.execute(
            existing=False,
            user_input="192.168.4.82\nNO\n",
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(
            "[CANCELLED] No deployment performed.",
            result.stdout,
        )
        self.assertIn("config --quiet", commands)
        self.assertNotIn("up -d", commands)


if __name__ == "__main__":
    unittest.main(verbosity=2)
