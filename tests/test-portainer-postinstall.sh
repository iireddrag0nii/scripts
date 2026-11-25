#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n "$ROOT/toolkit.sh"

python3 - "$ROOT/toolkit.sh" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text()

start = source.index("portainer_deploy() {")
end = source.index("\nstatus() {", start)
func = source[start:end]

checks = {
    "Deployment success checked":
        'if ! docker compose -f "$PORTAINER" up -d; then',
    "Compose status checked":
        'if ! docker compose -f "$PORTAINER" ps; then',
    "Setup instructions present":
        "=== Initial Administrator Setup ===",
    "SSH tunnel documented":
        "ssh -L 9443:127.0.0.1:9443",
    "Token retrieval documented":
        "sudo docker logs hbtech-portainer-portainer-1",
    "Token search documented":
        "setup_token=",
    "Credential warning present":
        "Keep setup tokens and administrator credentials private.",
}

for label, value in checks.items():
    if value not in func:
        raise SystemExit(f"[FAIL] {label}")
    print(f"[PASS] {label}")

if func.index("=== Initial Administrator Setup ===") < \
   func.index('if ! docker compose -f "$PORTAINER" up -d; then'):
    raise SystemExit("[FAIL] Instructions appear before deployment")

print("[PASS] Portainer post-install source checks passed.")
PY
