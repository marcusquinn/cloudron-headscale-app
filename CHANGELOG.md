# Changelog

All notable changes to this package are documented in this file. The store
changelog is `CHANGELOG`.

## [0.1.0] - 2026-10-18

### Added

- Initial Cloudron package for Headscale 0.29.5 (checksum-verified upstream
  binary on the digest-pinned `cloudron/base:6.0.0` image).
- Cloudron OIDC sign-in for interactive device enrolment, with the callback at
  `/oidc/callback`; pre-auth keys for headless devices.
- Embedded DERP relay over the app's HTTPS domain and STUN on UDP 3480 by
  default (3478 is Cloudron's TURN port). Disabling the port disables the
  embedded relay.
- SQLite state, keys and `config.yaml` in `/app/data`; the database is copied
  before a Headscale version change.
- Store listing: description, post-install guide, icon and slides.
- Gated catalog publication: `CLOUDRON_PUBLICATION_ENABLED` opt-in, attested
  image and catalog, atomic catalog commit and tag, GitHub release.
