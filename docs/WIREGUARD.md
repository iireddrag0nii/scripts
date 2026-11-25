# WireGuard Deployment Guide

HBTECHSOLUTIONS Infrastructure Deployment Toolkit v2.0

## Overview

The WireGuard module deploys a containerized VPN server
using LinuxServer.io's WireGuard image.

The default configuration is intended for an isolated,
LAN-accessible engineering lab, not a production VPN.

The initial configuration permits clients to reach the
WireGuard tunnel endpoint while blocking forwarded traffic.

## Default configuration

| Setting | Value |
|---|---|
| Compose project | hbtech-wireguard |
| Host UDP port | 51821 |
| Container UDP port | 51820 |
| VPN subnet | 10.77.77.0/24 |
| Server tunnel IP | 10.77.77.1 |
| First client IP | 10.77.77.2 |
| Client AllowedIPs | 10.77.77.1/32 |
| DNS override | None |
| Persistent volume | hbtech-wireguard_wireguard_config |

The server bind address is supplied during deployment.
No router port forwarding is configured automatically.

## Prerequisites

- Supported Linux host with WireGuard kernel support
- Operational Docker Engine and Compose
- Root or sudo privileges for deployment
- Available UDP port 51821
- Nonconflicting VPN subnet
- Network access to the selected server LAN address

## Deploy using the toolkit

Run:

    sudo ./toolkit.sh

Choose:

    5. Deploy WireGuard

The toolkit will:

1. Check Docker availability.
2. Detect and skip an existing toolkit WireGuard project.
3. Request the server LAN IPv4 address.
4. Check host addressing, routing, and port reservations.
5. Validate the Compose configuration.
6. Request the exact confirmation DEPLOY WIREGUARD.
7. Create the container, network, and persistent volume.

Canceling the confirmation leaves deployment unchanged.

## Direct Compose administration

Set the endpoint variables in the current shell:

    export WG_BIND_IP=192.168.4.82
    export WG_SERVER_URL=192.168.4.82

Replace these example values with your host's LAN address.

Run administrative Compose commands with:

    sudo -E docker compose -f compose/wireguard/compose.yaml ps

    sudo -E docker compose -f compose/wireguard/compose.yaml logs --tail=40

The variables must be supplied whenever Compose evaluates
this file. The toolkit handles them during initial deployment.

## Verify the server

Check the container:

    sudo docker ps --filter name=hbtech-wireguard

Check the WireGuard interface:

    sudo docker exec hbtech-wireguard-wireguard-1 wg show interfaces

Expected:

    wg0

Check the active forwarding rules:

    sudo docker exec hbtech-wireguard-wireguard-1 iptables -S FORWARD

The lab configuration should contain DROP rules for
forwarded traffic entering or leaving wg0.

## Client configuration

WireGuard peer configuration files are generated within
the persistent Docker volume, under /config/peer1/.

The file peer1.conf contains sensitive private keys.

Never upload client configurations, private keys, or
peer QR codes to GitHub or public support discussions.

For a trusted client, transfer the configuration using
an authenticated, encrypted channel such as SSH/SCP.

Protect any temporary exported copies and remove them
after importing the configuration into the client.

For Windows, import the configuration into the official
WireGuard client and activate the tunnel.

## Connectivity validation

After connecting a client:

    ping 10.77.77.1

On the server:

    sudo docker exec hbtech-wireguard-wireguard-1 wg show

Confirm a recent handshake and nonzero data transfer.

The default client route only includes 10.77.77.1/32.

## Network isolation validation

The custom server template adds container-level
firewall restrictions for the wg0 interface.

To verify blocked forwarding, temporarily add specific
test destination routes to the client AllowedIPs:

    10.77.77.1/32, 172.18.0.1/32, 172.19.0.1/32

These bridge addresses are examples from the validation
environment. Verify actual addresses on your host.

The server endpoint should remain reachable while
forwarding to these destinations is blocked.

Inspect firewall counters inside the container:

    sudo docker exec hbtech-wireguard-wireguard-1 iptables -nvL FORWARD

Confirm that the relevant DROP packet counter increases.

Restore AllowedIPs to 10.77.77.1/32 after testing.

IMPORTANT: Client AllowedIPs is a routing setting, not
an access-control rule. Validate server-side filtering.

The INPUT policy still allows traffic to the container's
tunnel address. Additional service-level restrictions are
required for environments with stricter security needs.

## Persistence testing

Record the server public key without exposing private keys:

    BEFORE=$(sudo docker exec hbtech-wireguard-wireguard-1 wg show wg0 public-key)

Recreate the container:

    sudo -E docker compose -f compose/wireguard/compose.yaml up -d --force-recreate

Compare the server identity:

    AFTER=$(sudo docker exec hbtech-wireguard-wireguard-1 wg show wg0 public-key)

    test -n "$BEFORE" && test "$BEFORE" = "$AFTER"

Verify the interface, firewall rules, and peer handshake
again after recreation.

Never use docker compose down -v unless intentionally
destroying stored VPN configuration and keys.

## Troubleshooting

### Compose reports missing environment variables

Supply WG_BIND_IP and WG_SERVER_URL, or use the guarded
toolkit deployment workflow.

### Container starts but no tunnel is available

Inspect sanitized container logs and confirm host
WireGuard kernel support.

### Client cannot connect

Verify UDP 51821 is reachable at the selected host
LAN address and the endpoint matches the peer config.

### Tunnel connects but traffic is blocked

The default server deliberately blocks forwarding.
Only the server tunnel endpoint is intended to be reached.

### An existing installation is detected

The toolkit skips deployment to preserve existing
containers and configuration. Review status manually.

## Security boundaries

- Intended for authorized lab deployments
- No automatic router port forwarding
- No automatic host DNS changes
- No full-tunnel internet routing
- No default VPN forwarding to LAN or Docker networks
- Private keys remain in persistent configuration storage
- No private peer QR codes printed in container logs

The current Compose image uses a moving latest tag.
Pin to a reviewed release or digest before production use.

This configuration is not production-hardened and does not
replace network segmentation, access-control review, or
operational monitoring.

## Validation record

Validated on Ubuntu 22.04.2 LTS, Linux kernel 5.15,
Docker Engine 29, and Docker Compose 5.

Observed successful:

- Container initialization and configuration generation
- WireGuard kernel interface activation
- Windows client handshake and tunnel endpoint ping
- Blocked forwarding to test Docker bridge destinations
- Firewall DROP counter increments
- Persistent server identity after container recreation
- Existing-installation skip through menu option 5
