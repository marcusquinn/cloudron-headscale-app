# Packaging notes

Headscale listens on Cloudron's HTTP port 8080. Its Noise (`/ts2021`) and
embedded DERP (`/derp`) HTTP upgrades use the same HTTPS origin through
Cloudron's reverse proxy. Headscale logs `listening without TLS but ServerURL
does not start with http://` at startup; that is expected, because Cloudron
terminates TLS.

The embedded DERP server is enabled only while Cloudron supplies `STUN_PORT`.
The manifest defaults it to UDP 3480: Cloudron's TURN service uses 3478, and
the NetBird package's optional STUN port defaults to 3479. When an operator disables
the port, Headscale starts without embedded DERP or STUN instead of binding an
undeclared port, and devices use Tailscale's public relays from `derp.urls`.

`/app/data` holds `config.yaml`, the SQLite database and Headscale-generated
Noise and DERP private keys. Headscale migrates the schema at startup; before a
Headscale version change, `start.sh` copies the database to
`db.sqlite.bak-<previous-version>`. Restore through Cloudron backup and restore
rather than replacing individual database files.

`start.sh` reapplies the Cloudron-owned keys at every start: `server_url`, the
listener addresses, the embedded DERP switch and STUN address, and the OIDC
block between `# Cloudron OIDC start` and `# Cloudron OIDC end`. Other settings
in `config.yaml`, such as DNS, ACL policy and `derp.urls`, are left alone.

With SSO enabled at install, Cloudron supplies OIDC credentials and an
interactive `tailscale up` redirects to the Cloudron login, with the callback at
`/oidc/callback`. Cloudron's app access control decides who can sign in;
Headscale creates a user for each person on first sign-in. Pre-auth keys work
with or without SSO.

The root URL serves an empty page. `/apple` and `/windows` are Headscale's
client setup pages.
