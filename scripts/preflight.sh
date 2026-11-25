#!/usr/bin/env bash
# HBTECHSOLUTIONS Infrastructure Toolkit v2
# Read-only host readiness assessment.

set -u

PASS=0
WARN=0
FAIL=0

report() {
    local status="$1" message="$2"
    printf '[%-4s] %s\n' "$status" "$message"
    case "$status" in
        PASS) ((PASS+=1)) ;;
        WARN) ((WARN+=1)) ;;
        FAIL) ((FAIL+=1)) ;;
    esac
}

check_port() {
    local port="$1" proto="$2" service="$3"
    local result="" docker_ports="" owner=""
    local occupied=0 docker_verified=0
    local container mappings mapping_re

    if ! command -v ss >/dev/null 2>&1; then
        report WARN "$service: cannot inspect $port/$proto (ss unavailable)"
        return
    fi

    if [[ "$proto" == "tcp" ]]; then
        if ! result=$(ss -H -ltn 2>/dev/null); then
            report WARN "$service: TCP listener inspection failed"
            return
        fi
    else
        if ! result=$(ss -H -lun 2>/dev/null); then
            report WARN "$service: UDP listener inspection failed"
            return
        fi
    fi

    if awk -v port="$port" '
        $4 ~ (":" port "$") { found=1 }
        END { exit !found }
    ' <<< "$result"; then
        occupied=1
    fi

    if command -v docker >/dev/null 2>&1; then
        if docker_ports=$(docker ps --format \
            '{{.Names}}|{{.Ports}}' 2>/dev/null); then
            docker_verified=1

            mapping_re="(^|[[:space:],])[^,[:space:]]*:${port}->[^,[:space:]]+/${proto}([[:space:],]|$)"

            while IFS='|' read -r container mappings; do
                if [[ "$mappings" =~ $mapping_re ]]; then
                    owner="${owner:+$owner, }$container"
                    occupied=1
                fi
            done <<< "$docker_ports"
        fi
    fi

    if (( occupied )); then
        report WARN "$service: $port/$proto is occupied"
        if [[ -n "$owner" ]]; then
            printf '       Docker owner: %s\n' "$owner"
        elif (( ! docker_verified )); then
            echo "       Docker ownership could not be verified"
        else
            echo "       Host listener detected; inspect with ss"
        fi
    elif (( ! docker_verified )); then
        report WARN "$service: $port/$proto has no detected host listener; Docker unverified"
    else
        report PASS "$service: $port/$proto has no detected host listener or Docker mapping"
    fi
}

echo "============================================"
echo " HBTECHSOLUTIONS Infrastructure Toolkit v2"
echo " Host Readiness Assessment"
echo "============================================"
echo

# Operating system
if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo "Operating system: ${PRETTY_NAME:-Unknown}"

    if [[ "${ID:-}" == "ubuntu" ]]; then
        report PASS "Ubuntu detected"
    else
        report WARN "Non-Ubuntu OS: compatibility not validated"
    fi
else
    report FAIL "Cannot identify operating system"
fi

# Architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|aarch64)
        report PASS "Supported architecture candidate: $ARCH"
        ;;
    *)
        report WARN "Architecture requires compatibility review: $ARCH"
        ;;
esac

# Docker
if command -v docker >/dev/null 2>&1; then
    report PASS "Docker CLI installed: $(docker --version)"
else
    report WARN "Docker CLI not installed"
fi

# Compose
if command -v docker >/dev/null 2>&1 &&
   docker compose version >/dev/null 2>&1; then
    report PASS "Docker Compose: $(docker compose version --short)"
else
    report WARN "Docker Compose plugin not available"
fi

# Disk space on current filesystem
AVAILABLE_KB=$(df -Pk . | awk 'NR==2 {print $4}')

if [[ "$AVAILABLE_KB" =~ ^[0-9]+$ ]]; then
    AVAILABLE_GB=$((AVAILABLE_KB / 1024 / 1024))

    if (( AVAILABLE_GB >= 5 )); then
        report PASS "Available disk space: approximately ${AVAILABLE_GB} GB"
    else
        report WARN "Less than 5 GB available on current filesystem"
    fi
else
    report WARN "Unable to determine disk capacity"
fi

echo
echo "=== Port availability ==="

check_port 9443 tcp "Portainer HTTPS"
check_port 51820 udp "WireGuard tunnel"
check_port 51821 tcp "wg-easy management"
check_port 53 tcp "Pi-hole DNS"
check_port 53 udp "Pi-hole DNS"
check_port 80 tcp "Web interface"
check_port 443 tcp "HTTPS"

echo
echo "=== Docker Published Ports ==="

if ! command -v docker >/dev/null 2>&1; then
    report WARN "Docker inventory unavailable: Docker CLI not installed"
elif docker ps --format '{{.Names}}|{{.Ports}}' >/dev/null 2>&1; then
    report PASS "Docker daemon accessible"

    docker ps --format '{{.Names}}|{{.Ports}}' |
        while IFS='|' read -r container ports; do
            [[ -z "$ports" ]] && continue
            [[ "$ports" != *"->"* ]] && continue
            printf '  %-30s %s\n' "$container" "$ports"
        done
else
    report WARN "Docker inventory unavailable: insufficient permissions or daemon offline"
    echo "  Re-run with sudo for a complete Docker port inventory."
fi

echo
echo "=== Assessment Summary ==="
printf 'PASS: %d | WARN: %d | FAIL: %d\n' "$PASS" "$WARN" "$FAIL"

echo
echo "No changes were made to this host."
echo "Port warnings require review before deployment."
echo "A free port does not guarantee deployment compatibility."

if (( FAIL > 0 )); then
    exit 1
fi

exit 0
