# Version 2.0 Release Validation Checklist

HBTECHSOLUTIONS Infrastructure Deployment Toolkit

Status: PENDING CLEAN-HOST VALIDATION

## Test Environment

Record before testing:

- Date:
- Tester:
- Ubuntu version:
- Kernel version:
- CPU architecture:
- VM CPU / RAM / disk:
- Repository commit:
- Docker Engine version:
- Docker Compose version:
- Host LAN IP:

Use a disposable VM or an approved test host with
an understood backup and recovery plan.

Never perform destructive testing on a machine hosting
unrelated workloads or irreplaceable data.

## 1. Fresh Host Assessment

- [ ] Confirm Ubuntu is freshly installed
- [ ] Record baseline disk, memory, and networking
- [ ] Verify Docker is initially absent
- [ ] Clone the repository
- [ ] Switch to development/v2
- [ ] Run host readiness assessment
- [ ] Confirm Docker installer reports FRESH_CANDIDATE
- [ ] Confirm no unintended host changes

## 2. Docker Installation

- [ ] Select menu option 2
- [ ] Review installation plan
- [ ] Confirm installation explicitly
- [ ] Verify Docker Engine starts
- [ ] Verify Docker Compose and Buildx
- [ ] Run hello-world successfully
- [ ] Repeat option 2
- [ ] Verify existing installation is skipped

## 3. Portainer

- [ ] Select menu option 3
- [ ] Review Docker socket security
- [ ] Confirm deployment explicitly
- [ ] Verify container is running
- [ ] Verify HTTPS on localhost port 9443
- [ ] Verify administrator setup
- [ ] Verify setup-token retrieval when required
- [ ] Recreate container without removing volumes
- [ ] Verify configuration persists
- [ ] Repeat menu option 3
- [ ] Verify installation is skipped

## 4. Pi-hole

- [ ] Select menu option 4
- [ ] Confirm deployment explicitly
- [ ] Verify container health
- [ ] Verify TCP and UDP DNS on localhost port 5353
- [ ] Verify web interface on localhost port 8088
- [ ] Verify an ordinary DNS lookup
- [ ] Verify blocking of a test domain
- [ ] Recreate container without deleting volumes
- [ ] Verify DNS settings and blocklist persist
- [ ] Repeat menu option 4
- [ ] Verify installation is skipped
- [ ] Confirm host and router DNS remain unchanged

## 5. WireGuard

- [ ] Confirm kernel WireGuard support
- [ ] Confirm UDP port 51821 is available
- [ ] Confirm VPN subnet does not conflict
- [ ] Select menu option 5
- [ ] Supply the approved server LAN IPv4 address
- [ ] Confirm deployment explicitly
- [ ] Verify local .env is created with mode 600
- [ ] Verify .env is ignored by Git
- [ ] Verify container starts and wg0 is active
- [ ] Verify server and peer configurations are generated
- [ ] Import peer configuration into a trusted client
- [ ] Verify authenticated handshake
- [ ] Verify client can reach 10.77.77.1
- [ ] Verify prohibited forwarding is blocked
- [ ] Verify forwarding DROP counters increase
- [ ] Restore narrow client AllowedIPs
- [ ] Recreate container without deleting volumes
- [ ] Verify server identity and peer connectivity persist
- [ ] Repeat menu option 5
- [ ] Verify existing installation is skipped

Do not publish private keys, peer configuration files,
QR codes, or sensitive VPN diagnostics.

## 6. Safety and Recovery

- [ ] Verify non-root deployment attempts are blocked
- [ ] Verify declined confirmations make no changes
- [ ] Verify occupied ports prevent new deployments
- [ ] Verify existing projects are never overwritten
- [ ] Verify persistent volumes are retained
- [ ] Test an interrupted installation in a disposable lab
- [ ] Verify failed WireGuard .env recovery is documented
- [ ] Verify no unintended router or host DNS changes
- [ ] Verify no unrelated container modifications

## 7. Automated Regression Tests

Run the tests from the repository root:

    python3 tests/test-preflight-ports.py
    ./tests/test-toolkit-menu.sh
    ./tests/test-docker-decision.sh
    ./tests/test-install-docker.sh
    ./tests/test-portainer-compose.sh
    ./tests/test-portainer-postinstall.sh
    python3 tests/test-portainer-conflicts.py
    python3 tests/test-pihole-compose.py
    python3 tests/test-pihole-conflicts.py
    python3 tests/test-wireguard-compose.py
    python3 tests/test-wireguard-isolation.py
    python3 tests/test-wireguard-conflicts.py
    python3 tests/test-wireguard-menu.py
    python3 tests/test-wireguard-deployment.py
    python3 tests/test-wireguard-env.py

- [ ] All applicable tests pass
- [ ] No unexpected failures or skipped critical tests
- [ ] Git whitespace validation passes
- [ ] No secrets or generated keys are staged

## 8. Release Review

- [ ] README reflects implemented functionality
- [ ] Installation guide matches tested steps
- [ ] Security boundaries and limitations are documented
- [ ] Service guides match observed deployments
- [ ] Container image digests are reviewed
- [ ] Supported platforms are accurately described
- [ ] Known issues and recovery limitations are recorded
- [ ] Development branch is clean
- [ ] Release commit is identified
- [ ] Main branch merge is approved
- [ ] Release tag and GitHub release notes are prepared

## Final Result

- Result: PENDING
- Date:
- Validated commit:
- Known limitations:
- Outstanding issues:
- Release decision: HOLD

Do not mark the release approved until all required
checks pass or exceptions are explicitly documented.

## Compatibility Test — Ubuntu 26.04.1 LTS

Date: 2026-11-25
Environment: Proxmox travel-kit VM, x86_64
Host address: 192.168.8.199
Repository commit: 2075502

Results:

- PASS: Git repository cloned successfully
- PASS: Host readiness assessment completed
- PASS: No pre-existing Docker installation detected
- PASS: Docker decision reported FRESH_CANDIDATE
- PASS: Installation authorization correctly blocked
- PASS: No software installed by toolkit assessment

Findings:

- Ubuntu 26.04 is not currently enabled for automated installation.
- Preflight still contains legacy wg-easy port descriptions.
- Fresh-host end-to-end deployment remains untested.

Decision: PASS for unsupported-release safety behavior.
Ubuntu 26.04 deployment support remains unvalidated.

## Clean-Host Acceptance Results — Ubuntu 26.04

Date: November 25, 2026
Platform: Ubuntu Server 26.04.1 LTS, AMD64
Environment: Proxmox travel-kit VM
Host: v2testing
Baseline commit: 466492c
Updated during testing through: 64cc580

### Docker Engine — PASS

- Installed using the interactive toolkit
- Docker Engine 29.10.1
- Docker Compose 5.8.0
- Buildx 0.39.1
- hello-world completed successfully
- Elevated repeat-run assessment returned SKIP_INSTALL

### Portainer — PASS

- Deployed using the interactive toolkit
- HTTPS returned HTTP 200
- Management bound to localhost:9443
- Initial administrator setup completed
- Persistent settings survived container recreation
- Repeat-run installation returned SKIP
- Setup-token guidance added during acceptance testing

### Pi-hole — PASS

- Deployed using the interactive toolkit
- Container reported healthy
- UDP and TCP DNS resolution succeeded
- Test domain was blocked with response 0.0.0.0
- Denylist persisted after container recreation
- Repeat-run installation returned SKIP
- Temporary test-domain entry removed

### WireGuard — PASS

- Deployed using the interactive toolkit
- Endpoint: 192.168.8.199:51821/UDP
- Tunnel: 10.77.77.0/24
- Windows client completed authenticated handshake
- Tunnel ping succeeded with zero packet loss
- Forwarding isolation confirmed using DROP counters
- Server public key persisted across recreation
- INPUT and FORWARD restrictions remained present
- Repeat-run installation returned SKIP
- Temporary server-side peer export removed

### Observations

- Ubuntu 26.04 installation required extending the
  guarded Docker installation allowlist.
- Non-root Docker assessment returned MANUAL_REVIEW
  because daemon access required elevated permissions.
- WireGuard interface initialization was briefly delayed
  immediately after container recreation.
- Preflight output retains legacy wg-easy port descriptions.
- Full regression review and release approval remain pending.

Functional deployment result: PASS
Final release decision: PENDING
