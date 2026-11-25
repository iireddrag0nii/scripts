#!/usr/bin/env bash
# HBTECHSOLUTIONS Docker Installation Decision
# Read-only. Never installs or removes software.

set -u

echo "=== Docker Installation Decision ==="

os_id="unknown"
os_version="unknown"

if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    os_id="${ID:-unknown}"
    os_version="${VERSION_ID:-unknown}"
fi

docker_cli=0
compose=0
daemon=0
packages=0
service=0

command -v docker >/dev/null 2>&1 && docker_cli=1

if (( docker_cli )); then
    docker compose version >/dev/null 2>&1 && compose=1
    docker info >/dev/null 2>&1 && daemon=1
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl is-active --quiet docker && service=1
fi

installed_packages=()
review_packages=()

if command -v dpkg-query >/dev/null 2>&1; then
    for pkg in docker-ce docker-ce-cli docker.io \
               docker-compose-plugin docker-compose-v2 \
               docker-compose containerd.io containerd \
               runc podman-docker; do

        if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null |
            grep -qx 'install ok installed'; then

            packages=1
            installed_packages+=("$pkg")

            case "$pkg" in
                docker.io|docker-compose-v2|docker-compose|containerd|runc|podman-docker)
                    review_packages+=("$pkg")
                    ;;
            esac
        fi
    done
fi

echo "Installed runtime packages:"
if (( ${#installed_packages[@]} )); then
    printf '  - %s\n' "${installed_packages[@]}"
else
    echo "  None detected by dpkg"
fi

if (( ${#review_packages[@]} )); then
    echo "Packages requiring installation-path review:"
    printf '  - %s\n' "${review_packages[@]}"
fi

arch="$(uname -m 2>/dev/null || printf 'unknown')"
printf 'Architecture: %s\n' "$arch"
printf 'OS: %s %s\n' "$os_id" "$os_version"
printf 'Docker CLI: %s | Compose: %s\n' "$docker_cli" "$compose"
printf 'Daemon accessible: %s | Service active: %s\n' "$daemon" "$service"
printf 'Known runtime packages detected: %s\n' "$packages"
echo

if [[ "$os_id" != "ubuntu" ]]; then
    echo "DECISION: MANUAL_REVIEW"
    echo "Reason: This workflow currently targets Ubuntu."
elif [[ ! " 22.04 24.04 26.04 26.10 " =~ " $os_version " ]]; then
    echo "DECISION: MANUAL_REVIEW"
    echo "Reason: Ubuntu release has not been approved for this workflow."
elif [[ "$arch" != "x86_64" && "$arch" != "aarch64" ]]; then
    echo "DECISION: MANUAL_REVIEW"
    echo "Reason: CPU architecture has not been validated."
elif (( ${#review_packages[@]} > 0 )); then
    echo "DECISION: MANUAL_REVIEW"
    echo "Reason: Existing runtime packages require installation-path review."
elif (( docker_cli && compose && daemon && service )); then
    echo "DECISION: SKIP_INSTALL"
    echo "Reason: Docker Engine and Compose are functioning."
elif (( !docker_cli && !compose && !daemon && !packages && !service )) &&
     command -v apt-get >/dev/null 2>&1; then
    echo "DECISION: FRESH_CANDIDATE"
    echo "Reason: No known Docker installation detected."
    echo "Review OS support and host prerequisites before installation."
else
    echo "DECISION: MANUAL_REVIEW"
    echo "Reason: Docker is partially installed or cannot be verified."
    echo "Do not install or remove packages automatically."
fi

echo
echo "Assessment only. No system changes performed."
