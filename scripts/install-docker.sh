#!/usr/bin/env bash
# HBTECHSOLUTIONS Infrastructure Toolkit v2
# Guarded Docker Engine installer - Ubuntu lab validation
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DECISION="$ROOT/scripts/docker-decision.sh"
DOCS="https://docs.docker.com/engine/install/ubuntu/"

usage() {
    echo "Usage: $0 [--plan | --dry-run | --install | --help]"
}

mode="${1:---plan}"
if (( $# > 1 )); then
    usage
    exit 2
fi

case "$mode" in
    --plan|--dry-run|--install) ;;
    --help) usage; exit 0 ;;
    *) usage; exit 2 ;;
esac

echo "============================================"
echo " HBTECHSOLUTIONS Docker Installer v2"
echo "============================================"
echo

[[ -f "$DECISION" ]] || {
    echo "[ERROR] Decision engine missing."
    exit 1
}

assessment="$(bash "$DECISION")"
printf '%s\n' "$assessment"

decision="$(printf '%s\n' "$assessment" |
    awk '/^DECISION: / {print $2}')"

echo
echo "=== Installation Gate ==="

case "$decision" in
    SKIP_INSTALL)
        echo "[SKIP] Docker already operational."
        echo "No installation performed."
        exit 0
        ;;
    MANUAL_REVIEW)
        echo "[BLOCKED] Host requires manual review."
        exit 2
        ;;
    FRESH_CANDIDATE)
        echo "[CANDIDATE] Fresh Docker installation."
        ;;
    *)
        echo "[ERROR] Unknown installation decision."
        exit 1
        ;;
esac

. /etc/os-release
codename="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
arch="$(dpkg --print-architecture)"

[[ -n "$codename" ]] || {
    echo "[BLOCKED] Ubuntu codename unavailable."
    exit 2
}

# Limit initial installation validation to tested targets.
case "${VERSION_ID:-}:$arch" in
    22.04:amd64|24.04:amd64|26.04:amd64|22.04:arm64|24.04:arm64|26.04:arm64) ;;
    *)
        echo "[BLOCKED] Release/architecture not enabled for installation."
        exit 2
        ;;
esac

echo
echo "=== Installation Plan ==="
echo "Ubuntu: ${VERSION_ID:-unknown} ($codename)"
echo "Architecture: $arch"
echo "Repository: https://download.docker.com/linux/ubuntu"
echo "Packages:"
echo "  docker-ce"
echo "  docker-ce-cli"
echo "  containerd.io"
echo "  docker-buildx-plugin"
echo "  docker-compose-plugin"
echo
echo "No Docker packages will be removed."
echo "Docker may modify firewall and networking rules."
echo "Review: $DOCS"

if [[ "$mode" != "--install" ]]; then
    echo
    echo "[DRY RUN] No system changes made."
    echo "Installation requires --install and interactive confirmation."
    exit 0
fi

if (( EUID != 0 )); then
    echo "[BLOCKED] Installation requires sudo."
    exit 2
fi

# Never overwrite evidence of a previous Docker repository setup.
for existing in \
    /etc/apt/sources.list.d/docker.sources \
    /etc/apt/sources.list.d/docker.list \
    /etc/apt/keyrings/docker.asc \
    /etc/apt/keyrings/docker.gpg; do
    if [[ -e "$existing" ]]; then
        echo "[BLOCKED] Existing Docker repository configuration:"
        echo "  $existing"
        exit 2
    fi
done

# Additional conflicts covered by official Docker prerequisites.
for pkg in docker-doc docker-buildx docker-compose \
           docker-compose-v2 docker.io podman-docker \
           containerd runc; do
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null |
       grep -qx 'install ok installed'; then
        echo "[BLOCKED] Conflicting package: $pkg"
        exit 2
    fi
done

if [[ -S /run/docker.sock || -S /var/run/docker.sock ]]; then
    echo "[BLOCKED] Existing system Docker socket detected."
    exit 2
fi

if [[ ! -t 0 ]]; then
    echo "[BLOCKED] Interactive terminal required."
    exit 2
fi

echo
echo "LAB INSTALLATION ONLY."
echo "Confirm the VM snapshot exists before proceeding."
read -r -p "Type INSTALL DOCKER ON LAB VM to proceed: " answer

if [[ "$answer" != "INSTALL DOCKER ON LAB VM" ]]; then
    echo "[CANCELLED] Confirmation did not match."
    exit 2
fi

echo
echo "[INSTALL] Preparing Docker repository..."

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl

install -m 0755 -d /etc/apt/keyrings
key_tmp="$(mktemp /etc/apt/keyrings/docker.asc.XXXXXX)"
trap 'rm -f "$key_tmp"' EXIT

curl -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    -o "$key_tmp"

install -m 0644 "$key_tmp" /etc/apt/keyrings/docker.asc

printf 'Types: deb\nURIs: https://download.docker.com/linux/ubuntu\nSuites: %s\nComponents: stable\nArchitectures: %s\nSigned-By: /etc/apt/keyrings/docker.asc\n' \
    "$codename" "$arch" > /etc/apt/sources.list.d/docker.sources

echo "[INSTALL] Updating Docker repository metadata..."
apt-get update

echo "[INSTALL] Installing Docker components..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

echo
echo "=== Post-install Verification ==="
docker --version
docker compose version
docker buildx version

systemctl is-active --quiet docker || {
    echo "[ERROR] Docker service is not active."
    exit 1
}

docker info >/dev/null || {
    echo "[ERROR] Docker daemon is not responding."
    exit 1
}

echo "[PASS] Docker Engine is operational."
echo "[PASS] Docker Compose and Buildx available."
echo "No existing containers were intentionally modified."
