#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTAINER="$ROOT/compose/portainer/compose.yaml"

header() {
    echo
    echo "=========================================="
    echo " HBTECHSOLUTIONS Infrastructure Toolkit"
    echo "                  v2.0"
    echo "=========================================="
}

portainer_plan() {
    echo
    echo "=== Portainer Deployment Plan ==="
    echo "Compose project: hbtech-portainer"
    echo "Image: portainer/portainer-ce:lts"
    echo "HTTPS: 127.0.0.1:9443"
    echo "Storage: persistent named volume"
    echo "Docker socket: privileged host access"
    echo "Edge Agent port: not published"
    echo

    docker compose -f "$PORTAINER" config --quiet
    echo "[PASS] Compose configuration valid."
}

portainer_deploy() {
    portainer_plan

    if (( EUID != 0 )); then
        echo "[BLOCKED] Use sudo to deploy."
        return 2
    fi

    if ! docker info >/dev/null 2>&1; then
        echo "[BLOCKED] Docker daemon unavailable."
        return 2
    fi

    local existing
    existing="$(docker compose -f "$PORTAINER" ps -a -q)" || {
        echo "[BLOCKED] Cannot inspect existing Portainer project."
        return 2
    }

    if [[ -n "$existing" ]]; then
        echo "[SKIP] Toolkit Portainer project already exists."
        echo "Review its status before making changes."
        return 0
    fi

    if ! bash "$ROOT/scripts/check-portainer-conflicts.sh"; then
        echo "[BLOCKED] Portainer deployment failed safety checks."
        return 2
    fi

    echo
    echo "This will pull an image and create a container,"
    echo "Docker network, and persistent volume."
    read -r -p "Type DEPLOY PORTAINER to continue: " answer

    if [[ "$answer" != "DEPLOY PORTAINER" ]]; then
        echo "[CANCELLED] No deployment performed."
        return 0
    fi

    docker compose -f "$PORTAINER" up -d
    docker compose -f "$PORTAINER" ps
}

status() {
    echo
    echo "=== Docker Status ==="
    if ! docker info >/dev/null 2>&1; then
        echo "[INFO] Docker unavailable or insufficient permissions."
        return 0
    fi
    docker version --format 'Engine: {{.Server.Version}}'
    docker compose -f "$PORTAINER" ps
}

run_menu_action() {
    local result=0

    "$@" || result=$?

    if (( result != 0 )); then
        echo "[ERROR] Action failed with exit code $result."
    fi

    return 0
}

menu() {
    while true; do
        header
        echo "1. Check host readiness"
        echo "2. Plan Docker installation"
        echo "3. Deploy Portainer"
        echo "4. Deploy Pi-hole (coming soon)"
        echo "5. Deploy WireGuard (coming soon)"
        echo "6. View deployment status"
        echo "7. Exit"
        echo
        read -r -p "Select an option [1-7]: " choice || return 0

        case "$choice" in
            1) run_menu_action bash "$ROOT/scripts/preflight.sh" ;;
            2) run_menu_action bash "$ROOT/scripts/install-docker.sh" --plan ;;
            3) run_menu_action portainer_deploy ;;
            4|5) echo "[INFO] Not implemented. No changes made." ;;
            6) status ;;
            7) echo "Exiting toolkit."; return 0 ;;
            *) echo "[ERROR] Invalid selection." ;;
        esac
    done
}

case "${1:-}" in
    "") menu ;;
    --help)
        echo "Usage: $0 [--help|--status|--plan-portainer|--deploy-portainer]"
        ;;
    --status) status ;;
    --deploy-portainer) portainer_deploy ;;
    --plan-portainer) header; portainer_plan ;;
    *) echo "[ERROR] Unknown option."; exit 2 ;;
esac
