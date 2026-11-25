#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTAINER="$ROOT/compose/portainer/compose.yaml"
PIHOLE="$ROOT/compose/pihole/compose.yaml"
WIREGUARD="$ROOT/compose/wireguard/compose.yaml"

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

wireguard_plan() {
    echo
    echo "=== WireGuard Deployment Plan ==="
    echo "Project: hbtech-wireguard"
    echo "UDP: 51821 -> 51820"
    echo "VPN subnet: 10.77.77.0/24"
    echo "Peers: 1"
    echo "Persistent configuration: enabled"
    echo "QR-code logging: disabled"
    echo

    WG_BIND_IP=192.0.2.10 WG_SERVER_URL=192.0.2.10 \
        docker compose -f "$WIREGUARD" config --quiet || {
        echo "[BLOCKED] Invalid WireGuard configuration."
        return 2
    }

    echo "[PASS] WireGuard Compose configuration valid."
    echo "[INFO] Planning only. No changes made."
    echo "[INFO] Deployment remains disabled pending network isolation validation."
}

wireguard_deploy() {
    echo
    echo "=== WireGuard Deployment ==="
    echo "Project: hbtech-wireguard"
    echo "Protocol: UDP 51821 -> 51820"
    echo "VPN subnet: 10.77.77.0/24"
    echo "Client routes: 10.77.77.1/32"
    echo "LAN routing: disabled"
    echo "Configuration: persistent Docker volume"
    echo "Router configuration: unchanged"
    echo

    if (( EUID != 0 )); then
        echo "[BLOCKED] Use sudo to deploy WireGuard."
        return 2
    fi

    if ! docker info >/dev/null 2>&1; then
        echo "[BLOCKED] Docker daemon unavailable."
        return 2
    fi

    local existing
    existing="$(
        WG_BIND_IP=192.0.2.10 WG_SERVER_URL=192.0.2.10 \
            docker compose -f "$WIREGUARD" ps -a -q
    )" || {
        echo "[BLOCKED] Cannot inspect existing WireGuard project."
        return 2
    }

    if [[ -n "$existing" ]]; then
        echo "[SKIP] Toolkit WireGuard project already exists."
        echo "Existing containers and VPN keys were not changed."
        echo "Review deployment status before making changes."
        return 0
    fi

    local env_file="$ROOT/compose/wireguard/.env"

    if [[ -e "$env_file" || -L "$env_file" ]]; then
        echo "[BLOCKED] Existing WireGuard .env file detected."
        echo "Review the configuration before retrying."
        return 2
    fi

    local bind_ip
    read -r -p "Enter the server LAN IPv4 address: " bind_ip || {
        echo "[CANCELLED] No deployment performed."
        return 2
    }

    if ! python3 "$ROOT/scripts/check-wireguard-conflicts.py" \
        --bind-ip "$bind_ip"; then
        echo "[BLOCKED] WireGuard prerequisite checks failed."
        return 2
    fi

    if ! WG_BIND_IP="$bind_ip" WG_SERVER_URL="$bind_ip" \
        docker compose -f "$WIREGUARD" config --quiet; then
        echo "[BLOCKED] Invalid WireGuard Compose configuration."
        return 2
    fi

    echo
    echo "WireGuard endpoint: $bind_ip:51821/UDP"
    echo "This will create a Docker network, container,"
    echo "persistent volume, and VPN server/client keys."
    echo "The endpoint will be reachable on the selected LAN IP."
    echo "No router forwarding or host DNS changes are made."
    echo

    local answer
    read -r -p "Type DEPLOY WIREGUARD to continue: " answer || {
        echo "[CANCELLED] No deployment performed."
        return 2
    }

    if [[ "$answer" != "DEPLOY WIREGUARD" ]]; then
        echo "[CANCELLED] No deployment performed."
        return 0
    fi

    # Create the local endpoint file without overwriting an existing file.
    if ! (
        umask 077
        set -C
        printf 'WG_BIND_IP=%s\nWG_SERVER_URL=%s\n' \
            "$bind_ip" "$bind_ip" > "$env_file"
    ); then
        echo "[BLOCKED] Cannot safely create WireGuard .env."
        return 2
    fi

    if ! docker compose \
        --env-file "$env_file" -f "$WIREGUARD" up -d; then
        echo "[ERROR] WireGuard deployment failed."
        return 1
    fi

    docker compose \
        --env-file "$env_file" -f "$WIREGUARD" ps

    echo "[INFO] Verify the tunnel, firewall and peer handshake."
    echo "[INFO] Never publish private keys or peer configs."
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
        echo "5. Deploy WireGuard"
        echo "6. View deployment status"
        echo "7. Exit"
        echo
        read -r -p "Select an option [1-7]: " choice || return 0

        case "$choice" in
            1) run_menu_action bash "$ROOT/scripts/preflight.sh" ;;
            2) run_menu_action docker_install_menu ;;
            3) run_menu_action portainer_deploy ;;
            4) run_menu_action pihole_deploy ;;
            5) run_menu_action wireguard_deploy ;;
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
