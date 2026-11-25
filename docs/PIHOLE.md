# Pi-hole Deployment and Validation

## Overview

HBTECHSOLUTIONS Infrastructure Deployment Toolkit v2.0
provides an optional Pi-hole deployment through its
interactive installation menu.

## Test Environment

- Ubuntu Server 22.04.2 LTS
- Docker Engine 29.10.1
- Docker Compose 5.8.0
- Architecture: AMD64
- Git branch: development/v2
- Initial implementation: 435bd56

## Deployment Configuration

- Compose project: hbtech-pihole
- DNS TCP: 127.0.0.1:5353
- DNS UDP: 127.0.0.1:5353
- Web administration: 127.0.0.1:8088
- Persistent volume: hbtech-pihole_pihole_data
- DHCP: Not enabled
- Host DNS settings: Unchanged

This configuration is intended for isolated lab testing,
not direct network-wide DNS deployment.

## Deployment Procedure

Run:

    sudo ./toolkit.sh

Select:

    4. Deploy Pi-hole

The toolkit validates the Compose configuration,
checks existing deployments and port conflicts,
and requires explicit deployment confirmation.

## Validation

The following tests were completed successfully:

1. Pi-hole deployed through the interactive menu.
2. Docker container started successfully.
3. Web administration interface was accessible.
4. DNS queries resolved through port 5353.
5. A manually denied domain returned 0.0.0.0.
6. DNS response included EDE 15 (Blocked).
7. Container recreation succeeded.
8. Configuration and denylist persisted after recreation.

## DNS Validation Commands

Normal resolution:

    dig @127.0.0.1 -p 5353 example.com A +short

Blocking test:

    dig @127.0.0.1 -p 5353 \
      hbtech-block-test.example.com A \
      +noall +comments +answer

The blocking test requires adding the test domain
to Pi-hole's denylist before executing the query.

Remove the temporary denylist entry after testing.

## Persistence

Configuration is stored in a named Docker volume.

Recreate the container using:

    sudo docker compose \
      -f compose/pihole/compose.yaml \
      up -d --force-recreate

Recreation retains the existing configuration volume.

## Security Considerations

- DNS and web management are localhost-bound.
- Administrative access requires an authentication password.
- No router DNS settings are changed automatically.
- No Ubuntu DNS resolver settings are modified.
- The initial image uses a floating tag and must be pinned
  to a tested release or digest before stable release.
- Docker administrative operations require appropriate privileges.

## Future Enhancements

- Configurable DNS and web interface bindings
- Secure initial password provisioning
- Optional network-wide DNS deployment
- Improved deployment status reporting
- Additional compatibility testing

## Conclusion

The Pi-hole module passed its initial runtime and
configuration-persistence validation on Ubuntu 22.04 AMD64.

Additional platform and failure-recovery testing remains
necessary before declaring the module production-ready.
