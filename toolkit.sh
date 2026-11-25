#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTAINER="$ROOT/compose/portainer/compose.yaml"
PIHOLE="$ROOT/compose/pihole/compose.yaml"

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

pihole_deploy() {
    echo
    echo "=== Pi-hole Deployment Plan ==="
    echo "Project: hbtech-pihole"
    echo "DNS: 127.0.0.1:5353 TCP/UDP"
    echo "Web: 127.0.0.1:8088"
    echo "Persistent configuration: enabled"
    echo "DHCP: disabled"
    echo "Host DNS configuration: unchanged"
    echo

    if ! docker compose -f "$PIHOLE" config --quiet; then
        echo "[BLOCKED] Invalid Pi-hole Compose configuration."
        return 2
    fi

    echo "[PASS] Compose configuration valid."

    if (( EUID != 0 )); then
        echo "[BLOCKED] Use sudo to deploy Pi-hole."
        return 2
    fi

    if ! docker info >/dev/null 2>&1; then
        echo "[BLOCKED] Docker daemon unavailable."
        return 2
    fi

    local existing
    existing="$(docker compose -f "$PIHOLE" ps -a -q)" || {
        echo "[BLOCKED] Cannot inspect existing Pi-hole project."
        return 2
    }

    if [[ -n "$existing" ]]; then
        echo "[SKIP] Toolkit Pi-hole project already exists."
        echo "Review its status before making changes."
        return 0
    fi

    if ! bash "$ROOT/scripts/check-pihole-conflicts.sh"; then
        echo "[BLOCKED] Pi-hole port safety checks failed."
        return 2
    fi

    echo
    echo "This will deploy Pi-hole and create persistent storage."
    echo "No host DNS settings or router settings will be changed."

    local answer
    read -r -p "Type DEPLOY PIHOLE to continue: " answer || {
        echo "[CANCELLED] No deployment performed."
        return 2
    }

    if [[ "$answer" != "DEPLOY PIHOLE" ]]; then
        echo "[CANCELLED] No deployment performed."
        return 0
    fi

    if ! docker compose -f "$PIHOLE" up -d; then
        echo "[ERROR] Pi-hole deployment failed."
        return 1
    fi

    docker compose -f "$PIHOLE" ps
    echo "[INFO] Verify Pi-hole health and DNS functionality."
}

docker_install_menu() {
    echo
    echo "=== Docker Engine Installation ==="

    local plan decision
    local plan_status=0
    plan="$(bash "$ROOT/scripts/install-docker.sh" --plan 2>&1)" || plan_status=$?
    printf '%s\n' "$plan"

    if (( plan_status != 0 )); then
        echo "[BLOCKED] Docker assessment returned exit code $plan_status."
        return "$plan_status"
    fi

    decision="$(printf '%s\n' "$plan" |
        awk '/^DECISION: / {print $2}')"

    case "$decision" in
        SKIP_INSTALL)
            echo "[SKIP] Docker is already operational."
            return 0
            ;;
        MANUAL_REVIEW)
            echo "[BLOCKED] Docker installation requires manual review."
            return 2
            ;;
        FRESH_CANDIDATE)
            ;;
        *)
            echo "[ERROR] Unexpected Docker installation decision."
            return 2
            ;;
    esac

    if (( EUID != 0 )); then
        echo "[BLOCKED] Launch the toolkit with sudo to install Docker."
        return 2
    fi

    echo
    read -r -p "Proceed to guarded Docker installation? [y/N]: " answer

    case "$answer" in
        y|Y|yes|YES)
            bash "$ROOT/scripts/install-docker.sh" --install
            ;;
        *)
            echo "[CANCELLED] No installation requested."
            ;;
    esac
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
        echo "2. Install Docker Engine"
        echo "3. Deploy Portainer"
        echo "4. Deploy Pi-hole"
        echo "5. Deploy WireGuard (coming soon)"
        echo "6. View deployment status"
        echo "7. Exit"
        echo
        read -r -p "Select an option [1-7]: " choice || return 0

        case "$choice" in
            1) run_menu_action bash "$ROOT/scripts/preflight.sh" ;;
            2) run_menu_action docker_install_menu ;;
            3) run_menu_action portainer_deploy ;;
            4) run_menu_action pihole_deploy ;;
            5) echo "[INFO] Not implemented. No changes made." ;;
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
