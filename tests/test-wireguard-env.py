#!/usr/bin/env python3
"""Test WireGuard endpoint persistence without real Docker access."""

import os
import shlex
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

TOOLKIT = Path(__file__).resolve().parents[1] / "toolkit.sh"
source = TOOLKIT.read_text()

start = source.index("wireguard_deploy() {")
end = source.index("\ndocker_install_menu() {", start)
function = source[start:end]

root_guard = "if (( EUID != 0 )); then"
assert function.count(root_guard) == 1

# Disable privilege enforcement only in this isolated test.
function = function.replace(root_guard, "if false; then", 1)


class WireGuardEnvTests(unittest.TestCase):

    def execute(self, answers="", existing=False, preset=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config_dir = root / "compose/wireguard"
            config_dir.mkdir(parents=True)

            env_file = config_dir / ".env"
            mock_log = root / "docker.log"

            if preset == "existing":
                env_file.write_text("ORIGINAL=unchanged\n")
            elif preset == "symlink":
                target = root / "protected"
                target.write_text("PROTECTED\n")
                env_file.symlink_to(target)

            harness = f'''
set -euo pipefail
ROOT={shlex.quote(str(root))}
WIREGUARD="$ROOT/compose/wireguard/compose.yaml"

docker() {{
    printf '%s\\n' "$*" >> "$MOCK_LOG"

    if [[ "$*" == "info" ]]; then
        return 0
    fi

    if [[ "$*" == *" ps -a -q" ]]; then
        if [[ "$MOCK_EXISTING" == "1" ]]; then
            echo mock-container-id
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
'''

            environment = os.environ.copy()
            environment["MOCK_LOG"] = str(mock_log)
            environment["MOCK_EXISTING"] = "1" if existing else "0"

            result = subprocess.run(
                ["bash", "-c", harness],
                input=answers,
                capture_output=True,
                text=True,
                env=environment,
                timeout=10,
            )

            commands = mock_log.read_text() if mock_log.exists() else ""
            contents = env_file.read_text() if env_file.is_file() else None
            permissions = (
                stat.S_IMODE(env_file.stat().st_mode)
                if env_file.is_file() and not env_file.is_symlink()
                else None
            )

            protected = root / "protected"
            protected_contents = (
                protected.read_text() if protected.exists() else None
            )

            return result, commands, contents, permissions, protected_contents

    def test_confirmed_deployment_creates_env(self):
        result, commands, contents, permissions, _ = self.execute(
            "192.168.4.82\nDEPLOY WIREGUARD\n"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            contents,
            "WG_BIND_IP=192.168.4.82\n"
            "WG_SERVER_URL=192.168.4.82\n",
        )
        self.assertEqual(permissions, 0o600)
        self.assertIn("up -d", commands)
        self.assertIn("--env-file", commands)

    def test_cancellation_creates_no_env(self):
        result, commands, contents, _, _ = self.execute(
            "192.168.4.82\nNO\n"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIsNone(contents)
        self.assertNotIn("up -d", commands)

    def test_existing_env_is_not_overwritten(self):
        result, commands, contents, _, _ = self.execute(
            preset="existing"
        )
        self.assertEqual(result.returncode, 2)
        self.assertEqual(contents, "ORIGINAL=unchanged\n")
        self.assertIn("[BLOCKED]", result.stdout)
        self.assertNotIn("up -d", commands)

    def test_symlink_is_blocked(self):
        result, commands, _, _, protected = self.execute(
            preset="symlink"
        )
        self.assertEqual(result.returncode, 2)
        self.assertEqual(protected, "PROTECTED\n")
        self.assertNotIn("up -d", commands)

    def test_existing_container_skips_before_env_check(self):
        result, commands, contents, _, _ = self.execute(
            existing=True,
            preset="existing",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("[SKIP]", result.stdout)
        self.assertEqual(contents, "ORIGINAL=unchanged\n")
        self.assertNotIn("up -d", commands)


if __name__ == "__main__":
    unittest.main(verbosity=2)
