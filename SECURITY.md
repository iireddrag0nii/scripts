# Security Policy

## Development Status

HBTECHSOLUTIONS Infrastructure Deployment Toolkit v2.0
is under active development.

Deployment components have not yet completed release validation.

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

Prefer tested, versioned container images over floating
tags such as latest.

## Network Security

Administrative interfaces should be accessible only
through trusted networks and authorized access methods.

Pay particular attention to:

- Portainer administration
- wg-easy management
- Pi-hole DNS and administration
- Firewall rules
- Router port forwarding
- Docker-published ports

Do not expose management interfaces directly to the
internet without an intentional security design.

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
