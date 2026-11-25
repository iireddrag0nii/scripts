#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/bin"

# Restrict PATH to controlled test commands.
ln -s "$(command -v grep)" "$TMP/bin/grep"

cat > "$TMP/bin/apt-get" <<'MOCK'
#!/bin/bash
exit 0
MOCK

cat > "$TMP/bin/systemctl" <<'MOCK'
#!/bin/bash
# User-level Docker service is separate from system Docker.
if [[ "${1:-}" == "--user" ]]; then
    if [[ "${SCENARIO:-}" == "rootless" ]]; then
        exit 0
    fi
    exit 1
fi

service="${@: -1}"

case "$service" in
    docker)
        case "${SCENARIO:-}" in
            fresh|packages_only|standalone_containerd) exit 1 ;;
            *) exit 0 ;;
        esac
        ;;
    podman)
        [[ "${SCENARIO:-}" == "podman" ]]
        ;;
    containerd)
        [[ "${SCENARIO:-}" == "standalone_containerd" ]]
        ;;
    *)
        exit 1
        ;;
esac
MOCK

cat > "$TMP/bin/dpkg-query" <<'MOCK'
#!/bin/bash
pkg="${@: -1}"

case "${SCENARIO:-}" in
    fresh|unmanaged|standalone_containerd)
        exit 1
        ;;
    packages_only)
        [[ "$pkg" == "docker.io" ]] || exit 1
        ;;
    mixed)
        case "$pkg" in
            docker-ce|docker-ce-cli|docker-compose-plugin|containerd.io|docker.io)
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
    *)
        case "$pkg" in
            docker-ce|docker-ce-cli|docker-compose-plugin|containerd.io)
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
esac

printf 'install ok installed'
MOCK

cat > "$TMP/bin/docker" <<'MOCK'
#!/bin/bash
case "${SCENARIO:-}" in
    partial)
        [[ "${1:-}" == "compose" ]] && exit 1
        ;;
    noaccess)
        [[ "${1:-}" == "info" ]] && exit 1
        ;;
esac
exit 0
MOCK

cat > "$TMP/bin/uname" <<'MOCK'
#!/bin/bash
if [[ "${1:-}" == "-m" ]]; then
    printf '%s\n' "${MOCK_ARCH:-x86_64}"
else
    exit 1
fi
MOCK

chmod +x "$TMP/bin/apt-get" "$TMP/bin/systemctl" "$TMP/bin/dpkg-query" "$TMP/bin/docker" "$TMP/bin/uname"

run_test() {
    local scenario="$1" expected="$2" arch="${3:-x86_64}"
    local bin="$TMP/bin" output

    # Exclude Docker entirely for these scenarios.
    if [[ "$scenario" == "fresh" ||
          "$scenario" == "packages_only" ||
          "$scenario" == "standalone_containerd" ]]; then
        bin="$TMP/no-docker"
        mkdir -p "$bin"

        for name in grep apt-get systemctl dpkg-query uname; do
            ln -sf "$TMP/bin/$name" "$bin/$name"
        done
    fi

    output=$(SCENARIO="$scenario" MOCK_ARCH="$arch" PATH="$bin" \
        /bin/bash "$ROOT/scripts/docker-decision.sh")

    if grep -Fxq "DECISION: $expected" <<< "$output"; then
        echo "[PASS] $scenario [$arch] -> $expected"
    else
        echo "[FAIL] $scenario [$arch] -> expected $expected"
        printf '%s\n' "$output"
        return 1
    fi
}

run_test installed SKIP_INSTALL
run_test noaccess MANUAL_REVIEW
run_test partial MANUAL_REVIEW
run_test packages_only MANUAL_REVIEW
run_test mixed MANUAL_REVIEW
run_test podman MANUAL_REVIEW
run_test standalone_containerd MANUAL_REVIEW
run_test unmanaged MANUAL_REVIEW

# Verify that the package inventory identifies the alternative runtime.
package_output=$(SCENARIO=packages_only PATH="$TMP/no-docker" \
    /bin/bash "$ROOT/scripts/docker-decision.sh")

if grep -Fxq "  - docker.io" <<< "$package_output" &&
   grep -Fq "Packages requiring installation-path review:" \
       <<< "$package_output"; then
    echo "[PASS] docker.io identified for installation-path review"
else
    echo "[FAIL] docker.io package review not reported"
    exit 1
fi
run_test fresh FRESH_CANDIDATE

echo
echo
echo "=== Operating system compatibility tests ==="

run_os_test() {
    local label="$1" os="$2" version="$3" expected="$4"
    local output

    printf 'ID=%s\nVERSION_ID="%s"\n' \
        "$os" "$version" > "$TMP/os-release"

    cp "$ROOT/scripts/docker-decision.sh" "$TMP/os-decision.sh"

    sed -i "s|/etc/os-release|$TMP/os-release|g" \
        "$TMP/os-decision.sh"

    output=$(SCENARIO=fresh PATH="$TMP/no-docker" \
        /bin/bash "$TMP/os-decision.sh")

    if grep -Fxq "DECISION: $expected" <<< "$output"; then
        echo "[PASS] $label -> $expected"
    else
        echo "[FAIL] $label"
        printf '%s\n' "$output"
        return 1
    fi
}

run_os_test "Ubuntu 20.04" ubuntu 20.04 MANUAL_REVIEW
run_os_test "Debian 12" debian 12 MANUAL_REVIEW
run_os_test "Ubuntu 24.04" ubuntu 24.04 FRESH_CANDIDATE

echo
echo
echo "=== Architecture compatibility tests ==="

run_test installed SKIP_INSTALL aarch64
run_test installed MANUAL_REVIEW armv7l

echo
echo
echo "=== Alternative runtime reason verification ==="

verify_reason() {
    local scenario="$1" expected_reason="$2" bin="$TMP/bin"
    local output

    if [[ "$scenario" == "standalone_containerd" ]]; then
        bin="$TMP/no-docker"
    fi

    output=$(SCENARIO="$scenario" MOCK_ARCH=x86_64 PATH="$bin" \
        /bin/bash "$ROOT/scripts/docker-decision.sh")

    if grep -Fq "$expected_reason" <<< "$output"; then
        echo "[PASS] $scenario reason verified"
    else
        echo "[FAIL] $scenario reason missing"
        printf '%s\n' "$output"
        return 1
    fi
}

verify_reason podman "Podman runtime detected"
verify_reason standalone_containerd "Standalone containerd service detected"
verify_reason unmanaged "Unmanaged Docker executable detected"

echo
echo
echo "=== Snap and nerdctl detection tests ==="

for runtime in snap nerdctl; do
    bin="$TMP/$runtime-bin"
    mkdir -p "$bin"

    for name in grep apt-get systemctl dpkg-query docker uname; do
        ln -s "$TMP/bin/$name" "$bin/$name"
    done

    if [[ "$runtime" == "snap" ]]; then
        cat > "$bin/snap" <<'MOCK'
#!/bin/bash
[[ "${1:-}" == "list" && "${2:-}" == "docker" ]]
MOCK
        expected_reason="Docker Snap installation detected"
    else
        cat > "$bin/nerdctl" <<'MOCK'
#!/bin/bash
exit 0
MOCK
        expected_reason="nerdctl executable detected"
    fi

    chmod +x "$bin/$runtime"

    output=$(SCENARIO=installed MOCK_ARCH=x86_64 PATH="$bin" \
        /bin/bash "$ROOT/scripts/docker-decision.sh")

    if grep -Fxq "DECISION: MANUAL_REVIEW" <<< "$output"; then
        echo "[PASS] $runtime -> MANUAL_REVIEW"
    else
        echo "[FAIL] $runtime decision"
        printf '%s\n' "$output"
        exit 1
    fi

    if grep -Fq "$expected_reason" <<< "$output"; then
        echo "[PASS] $runtime reason verified"
    else
        echo "[FAIL] $runtime reason"
        printf '%s\n' "$output"
        exit 1
    fi
done

echo
echo "All alternative runtime checks passed."

echo
echo "=== Docker endpoint detection tests ==="

verify_endpoint() {
    local label="$1" expected_reason="$2"
    local output

    if [[ "$label" == "custom_endpoint" ]]; then
        output=$(SCENARIO=installed MOCK_ARCH=x86_64 \
            DOCKER_HOST="unix:///tmp/custom-docker.sock" \
            PATH="$TMP/bin" \
            /bin/bash "$ROOT/scripts/docker-decision.sh")
    else
        output=$(SCENARIO=rootless MOCK_ARCH=x86_64 \
            DOCKER_HOST="" PATH="$TMP/bin" \
            /bin/bash "$ROOT/scripts/docker-decision.sh")
    fi

    if grep -Fxq "DECISION: MANUAL_REVIEW" <<< "$output" &&
       grep -Fq "$expected_reason" <<< "$output"; then
        echo "[PASS] $label -> MANUAL_REVIEW (reason verified)"
    else
        echo "[FAIL] $label"
        printf '%s\n' "$output"
        return 1
    fi
}

verify_endpoint custom_endpoint \
    "Nonstandard DOCKER_HOST endpoint configured"

verify_endpoint rootless \
    "User-level Docker service active"

echo
echo "All Docker endpoint tests passed."
