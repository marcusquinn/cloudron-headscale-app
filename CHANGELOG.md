# Changelog

All notable changes to this package are documented in this file. The store
changelog is `CHANGELOG`.

## [0.1.3] - 2026-10-31

### Changed

- Update Headscale to 0.29.7 using the checksum-verified upstream Linux amd64
  binary. This security release hardens registration and OIDC handling, bounds
  client reports and pending authentication, and fixes denial-of-service issues.
- Upgrade Tailscale clients separately to 1.104.4 or newer, especially SSH
  destination nodes before using `acceptEnv`. Updating Headscale alone does not
  apply the SSH forwarding, SSH session and Serve fixes in `tailscaled`.
- Minimum supported Tailscale client remains 1.80.0. The digest-pinned Cloudron
  base remains 6.0.1.

## [0.1.2] - 2026-10-25

### Changed

- Update Headscale to 0.29.6 using the checksum-verified upstream Linux amd64
  binary. This release includes Go certificate-chain protections, dependency
  security updates, peer-map optimizations, and map-stream/database error fixes.
- Update the digest-pinned Cloudron base to 6.0.1 with its patched CA bundle
  (the same base-image pin proposed in PR #29).
- Minimum supported Tailscale client remains 1.80.0.

## [0.1.1] - 2026-10-18

### Added

- `forumUrl` in the manifest, so the store links the
  [Cloudron forum topic](https://forum.cloudron.io/topic/16152/headscale-self-hosted-tailscale-control-server-with-cloudron-sso-and-a-built-in-derp-relay).
  No change to the app image contents; Headscale stays at 0.29.5.

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
