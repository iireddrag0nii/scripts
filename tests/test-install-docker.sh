#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/scripts/install-docker.sh"

pass=0
fail=0

check() {
    local name="$1" expected_code="$2" expected_text="$3"
    shift 3

    local output status=0
    output=$(DOCKER_HOST=unix:///tmp/hbtech-test-do-not-connect.sock \
        "$SCRIPT" "$@" 2>&1) || status=$?

    if [[ "$status" -eq "$expected_code" ]] &&
       [[ "$output" == *"$expected_text"* ]]; then
        echo "[PASS] $name"
        ((pass+=1))
    else
        echo "[FAIL] $name"
        echo "Expected exit: $expected_code"
        echo "Actual exit: $status"
        printf '%s\n' "$output"
        ((fail+=1))
    fi
}

check "Installation blocked" 2 \
    "[BLOCKED]" --install

check "Help available" 0 \
    "Usage:" --help

check "Unknown option rejected" 2 \
    "Usage:" --invalid

echo
printf 'Results: PASS=%d FAIL=%d\n' "$pass" "$fail"

[[ "$fail" -eq 0 ]]
