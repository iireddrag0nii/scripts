#!/usr/bin/env bash
# HBTECHSOLUTIONS Infrastructure Toolkit v2
# Docker installation planner
# No package modifications are implemented yet.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DECISION_SCRIPT="$ROOT/scripts/docker-decision.sh"

usage() {
    echo "Usage: $0 [--plan | --install | --help]"
}

case "${1:---plan}" in
    --plan)
        ;;
    --install)
        echo "[BLOCKED] Installation is not implemented."
        echo "Use --plan to review host readiness."
        exit 2
        ;;
    --help)
        usage
        exit 0
        ;;
    *)
        usage
        exit 2
        ;;
esac

echo "============================================"
echo " HBTECHSOLUTIONS Docker Installation Planner"
echo "============================================"
echo

if [[ ! -f "$DECISION_SCRIPT" ]]; then
    echo "[ERROR] Docker decision engine not found."
    exit 1
fi

assessment="$(bash "$DECISION_SCRIPT")"
printf '%s\n' "$assessment"

decision="$(printf '%s\n' "$assessment" |
    awk '/^DECISION: / { print $2 }')"

echo
echo "=== Installation Recommendation ==="

case "$decision" in
    SKIP_INSTALL)
        echo "[SKIP] Docker is already operational."
        echo "No installation is necessary."
        ;;
    FRESH_CANDIDATE)
        echo "[CANDIDATE] Fresh installation may be appropriate."
        echo "Review host architecture, repositories, and backups."
        echo
        echo "Official Docker installation documentation:"
        echo "https://docs.docker.com/engine/install/ubuntu/"
        ;;
    MANUAL_REVIEW)
        echo "[BLOCKED] Existing or unsupported environment."
        echo "Resolve the reported conditions before installation."
        ;;
    *)
        echo "[ERROR] Unknown assessment result."
        exit 1
        ;;
esac

echo
echo "Planner mode only. No system changes performed."
