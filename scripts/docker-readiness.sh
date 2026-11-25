#!/usr/bin/env bash

# HBTECHSOLUTIONS Infrastructure Deployment Toolkit v2
# Docker installation readiness assessment
# Read-only: does not install, update, or remove software.

set -u

echo "============================================"
echo " HBTECHSOLUTIONS Docker Readiness Assessment"
echo "============================================"
echo

if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo "Operating system: ${PRETTY_NAME:-Unknown}"

    if [[ "${ID:-}" != "ubuntu" ]]; then
        echo "[WARN] Automated installation target is Ubuntu."
    fi
else
    echo "[WARN] Operating system could not be identified."
fi

echo
echo "=== Docker Engine ==="

if command -v docker >/dev/null 2>&1; then
    echo "[PASS] Docker CLI installed"
    docker --version
else
    echo "[INFO] Docker CLI not found"
fi

echo
echo "=== Docker Compose ==="

if command -v docker >/dev/null 2>&1 &&
   docker compose version >/dev/null 2>&1; then
    echo "[PASS] Docker Compose plugin available"
    docker compose version
else
    echo "[INFO] Docker Compose plugin not detected"
fi

echo
echo "=== Docker Service ==="

if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet docker; then
        echo "[PASS] Docker service is active"
    else
        echo "[INFO] Docker service is not active"
    fi
else
    echo "[INFO] systemctl unavailable"
fi

echo
echo "=== Docker Daemon Access ==="

if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        echo "[PASS] Docker daemon accessible"
    else
        echo "[WARN] Docker daemon inaccessible to this account"
        echo "       Check service state or permissions."
    fi
fi

echo
echo "=== Installed Docker Packages ==="

if command -v dpkg-query >/dev/null 2>&1; then
    for package in docker-ce docker-ce-cli \
                   containerd.io docker-compose-plugin \
                   docker.io docker-compose-v2; do
        if dpkg-query -W -f='${Status}' "$package" \
            2>/dev/null | grep -qx 'install ok installed'; then
            echo "[INSTALLED] $package"
        fi
    done
else
    echo "[INFO] dpkg-query unavailable"
fi

echo
echo "=== Assessment Complete ==="
echo "No software was installed, updated, or removed."
echo "Review results before attempting Docker installation."
