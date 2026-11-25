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

# Detect alternative installations without changing the host.
alternative_install=0
alternative_reasons=()

if command -v snap >/dev/null 2>&1; then
    if snap list docker >/dev/null 2>&1; then
        alternative_install=1
        alternative_reasons+=("Docker Snap installation detected")
    fi
fi

if command -v podman >/dev/null 2>&1 ||
   { command -v systemctl >/dev/null 2>&1 &&
     systemctl is-active --quiet podman; }; then
    alternative_install=1
    alternative_reasons+=("Podman runtime detected")
fi

if command -v nerdctl >/dev/null 2>&1; then
    alternative_install=1
    alternative_reasons+=("nerdctl executable detected")
fi

# Docker binaries without recognized packages need investigation.
if (( !packages )) &&
   { command -v docker >/dev/null 2>&1 ||
     command -v dockerd >/dev/null 2>&1; }; then
    alternative_install=1
    alternative_reasons+=("Unmanaged Docker executable detected")
fi

# An active containerd service is expected with Docker CE.
# Only flag it here when no recognized packages or Docker CLI exist.
if (( !packages && !docker_cli )) &&
   command -v systemctl >/dev/null 2>&1 &&
   systemctl is-active --quiet containerd; then
    alternative_install=1
    alternative_reasons+=("Standalone containerd service detected")
fi

if (( alternative_install )); then
    echo "Alternative runtime indicators:"
    printf '  - %s\n' "${alternative_reasons[@]}"
fi

# Detect nonstandard Docker endpoints and current-user
# rootless Docker installations.
rootless_review=0
rootless_reasons=()

if [[ -n "${DOCKER_HOST:-}" &&
      "${DOCKER_HOST}" != "unix:///var/run/docker.sock" &&
      "${DOCKER_HOST}" != "unix:///run/docker.sock" ]]; then
    rootless_review=1
    rootless_reasons+=("Nonstandard DOCKER_HOST endpoint configured")
fi

if command -v systemctl >/dev/null 2>&1 &&
   systemctl --user is-active --quiet docker 2>/dev/null; then
    rootless_review=1
    rootless_reasons+=("User-level Docker service active")
fi

if command -v id >/dev/null 2>&1; then
    current_uid="$(id -u)"

    if [[ "$current_uid" =~ ^[0-9]+$ ]]; then
        user_socket="/run/user/${current_uid}/docker.sock"

        if [[ -S "$user_socket" ]]; then
            rootless_review=1
            rootless_reasons+=("User-level Docker socket detected")
        fi
    fi
fi

if (( rootless_review )); then
    echo "Docker endpoint review indicators:"
    printf '  - %s\n' "${rootless_reasons[@]}"
fi

if [[ "$os_id" != "ubuntu" ]]; then
    echo "DECISION: MANUAL_REVIEW"
    echo "Reason: This workflow currently targets Ubuntu."
elif [[ ! " 22.04 24.04 26.04 26.10 " =~ " $os_version " ]]; then
    echo "DECISION: MANUAL_REVIEW"
    echo "Reason: Ubuntu release has not been approved for this workflow."
elif [[ "$arch" != "x86_64" && "$arch" != "aarch64" ]]; then
    echo "DECISION: MANUAL_REVIEW"
    echo "Reason: CPU architecture has not been validated."
elif (( rootless_review )); then
    echo "DECISION: MANUAL_REVIEW"
    echo "Reason: Docker endpoint or user-level installation requires review."
elif (( alternative_install )); then
    echo "DECISION: MANUAL_REVIEW"
    echo "Reason: Alternative container runtime or installation detected."
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
