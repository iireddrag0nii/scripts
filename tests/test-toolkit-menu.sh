#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLKIT="$ROOT/toolkit.sh"
pass=0
fail=0

check() {
    local description="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$actual" == *"$expected"* ]]; then
        echo "[PASS] $description"
        ((pass+=1))
    else
        echo "[FAIL] $description"
        ((fail+=1))
    fi
}

bash -n "$TOOLKIT"
echo "[PASS] Bash syntax"
((pass+=1))

output="$(bash "$TOOLKIT" --help)"
check "Help available" "Usage:" "$output"

output="$(bash "$TOOLKIT" --plan-portainer)"
check "Portainer plan available" \
    "[PASS] Compose configuration valid." "$output"

output="$(printf '7\n' | bash "$TOOLKIT")"
check "Interactive exit works" \
    "Exiting toolkit." "$output"

output="$(printf '4\n5\n7\n' | bash "$TOOLKIT")"
count="$(grep -c 'Not implemented. No changes made.' <<< "$output" || true)"

if [[ "$count" == "2" ]]; then
    echo "[PASS] Unimplemented services disabled"
    ((pass+=1))
else
    echo "[FAIL] Unimplemented services disabled"
    ((fail+=1))
fi

if (( EUID != 0 )); then
    output="$(printf '3\n7\n' | bash "$TOOLKIT")"
    check "Non-root deployment blocked" \
        "[BLOCKED] Use sudo to deploy." "$output"
else
    echo "[INFO] Non-root check requires an unprivileged user"
fi

echo
echo "Results: PASS=$pass FAIL=$fail"
((fail==0))
