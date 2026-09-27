# Packaging notes

Headscale listens on Cloudron's HTTP port 8080. Its Noise (`/ts2021`) and embedded DERP (`/derp`) HTTP upgrades use the same HTTPS origin through Cloudron's reverse proxy.

The embedded DERP server is enabled only while Cloudron supplies `STUN_PORT`; the manifest defaults it to UDP 3479 to avoid the standard NetBird 3478 conflict. When an operator disables this port, Headscale starts without embedded DERP/STUN rather than binding an undeclared port.

`/app/data` holds `config.yaml`, SQLite state, and Headscale-generated Noise and DERP private keys. Headscale performs schema migration during startup; restore through Cloudron backup/restore rather than manually replacing individual database files.

Cloudron-owned listener and URL fields are reapplied at startup. Operator policy settings in `config.yaml` remain intact. OIDC credentials are exposed by Cloudron; configure Headscale's OIDC callback as `/oidc/callback` during live qualification.
