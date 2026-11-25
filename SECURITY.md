# Security Policy

## Development Status

HBTECHSOLUTIONS Infrastructure Deployment Toolkit v2.0
is under active development.

Individual deployment modules have been lab-validated.
Full clean-host release validation remains pending.

The original scripts in legacy/ are preserved for
historical reference and should not be used in production.

## Credentials and Secrets

Never commit:

- Passwords or reusable password hashes
- API keys or access tokens
- SSH or VPN private keys
- Production environment files
- Recovery credentials
- Sensitive configuration backups

Use example configuration files containing placeholders.

The repository excludes common secret files through
.gitignore, but exclusions are not a security boundary.

Always inspect staged changes before committing.

## Docker Security

Docker daemon access is highly privileged and can provide
root-level control of the host.

Do not add users to the Docker group simply to avoid sudo.

Review container capabilities, volume mounts, network
configuration, and published ports before deployment.

The current service images use pinned registry digests.
Review these periodically for security updates.
Pinning prevents automatic updates; it does not ensure
an image remains secure indefinitely.

## Network Security

Administrative interfaces should be accessible only
through trusted networks and authorized access methods.

Pay particular attention to:

- Portainer administration
- WireGuard peer configuration and tunnel access
- Pi-hole DNS and administration
- Firewall rules
- Router port forwarding
- Docker-published ports

Do not expose management interfaces directly to the
internet without an intentional security design.

## Current Service Security Boundaries

### Portainer

The management interface is published to localhost.

Access to the Docker socket grants significant control
over the host. Restrict administrative access.

### Pi-hole

DNS and web management ports are bound to localhost.

No host or router DNS changes are performed automatically.

### WireGuard

The default deployment publishes UDP port 51821 on an
explicitly selected server LAN IPv4 address.

The server uses custom forwarding DROP rules to restrict
traffic from the VPN tunnel into other networks.

These rules were verified using a Windows VPN client
and controlled Docker bridge connectivity tests.

Client AllowedIPs controls routing, not authorization.

Traffic to the WireGuard container's tunnel endpoint
is permitted by the current default INPUT policy.

This is a limited engineering lab configuration,
not a production remote-access security policy.

VPN private keys and peer configuration files reside
in persistent Docker storage.

New deployments also create a local endpoint .env file
with permissions 600, excluded from version control.

Do not publish peer configurations or private keys.

### Container image updates

Review security advisories and upstream releases before
changing any pinned image digest.

Validate updated images in a test environment before
deploying them to existing infrastructure.

## Deployment Safety

The preflight assessment is designed to be read-only.

Installation and deployment must require explicit
operator action.

Review installation commands and package dependencies
before applying changes to an existing host.

Do not automatically remove containers or modify
firewall rules to resolve port conflicts.

## Backup and Recovery

Before changing production infrastructure:

1. Back up persistent data and configurations.
2. Record current port mappings and running services.
3. Document recovery procedures.
4. Test restoration in an appropriate lab environment.

## Reporting Security Issues

Do not publish credentials, private configuration, or
sensitive diagnostic information in public GitHub issues.

Report potential vulnerabilities privately using the
contact information at:

https://www.hbtechsolutions.com

## Authorized Use

This toolkit is intended for systems you own or have
explicit authorization to administer.
