# Forum announcement

Posted on 2026-10-18 as
[topic 16152](https://forum.cloudron.io/topic/16152/headscale-self-hosted-tailscale-control-server-with-cloudron-sso-and-a-built-in-derp-relay)
in the Cloudron forum's
[Community Packages](https://forum.cloudron.io/category/220/community-packages)
category. The manifest's `forumUrl` points there. Kept as the record of the
original post.

---

**Title:** Headscale – self-hosted Tailscale control server with Cloudron SSO and a built-in DERP relay

I've packaged [Headscale](https://github.com/juanfont/headscale), the
open-source, self-hosted Tailscale control server, as a community app. Your
devices keep using the official Tailscale apps (Linux, macOS, Windows, iOS,
Android), but join a private WireGuard mesh coordinated by your Cloudron
instead of Tailscale's hosted service.

![Headscale on Cloudron](https://raw.githubusercontent.com/marcusquinn/cloudron-headscale-app/b0613489b549c49621f682067a06b0619277a094/media/listing-1-devices.png)

**Install:** add this catalog under *Settings → Community apps*, then install
Headscale from the App Store:

```text
https://raw.githubusercontent.com/marcusquinn/cloudron-headscale-app/main/CloudronVersions.json
```

or `cloudron install --versions-url <that URL> --location headscale.example.com`.

**What fits in with Cloudron**

- **Single sign-on:** `tailscale up --login-server https://headscale.example.com`
  opens a Cloudron login. The app's access control decides who can add
  devices, and Headscale creates a user for each person on first sign-in.
- **Pre-auth keys** for servers and headless devices, created with the
  `headscale` CLI in the app's Terminal.
- **One HTTPS domain** carries the control protocol, Noise and the embedded
  DERP relay through Cloudron's reverse proxy. The only extra port is STUN on
  UDP **3480** by default (3478 is Cloudron's TURN port, and the NetBird
  package's optional STUN port defaults to 3479).
- **Backups:** the SQLite database, server keys and `config.yaml` live in
  `/app/data`, so a restore brings back the same server identity and enrolled
  devices keep working.

**Good to know**

- Headscale has no web interface. You manage users, devices, routes and exit
  nodes with `headscale` in the Terminal; the README has the common commands.
- A sign-in link only works while `tailscale up` is still waiting, and
  Headscale replaces it every 15 minutes. If you see "Gone: Your session has
  expired", run `tailscale up` again.
- Devices connect directly where they can and fall back to the embedded relay.
  Tailscale's public relays stay in the config as a second fallback; you can
  remove them to rely only on your server. Disabling the STUN port disables
  the embedded relay.
- `config.yaml` is yours to edit (DNS, ACL policy, relays). The package
  reapplies only the keys it owns: server URL, listeners, the relay switch and
  the SSO block.
- The image uses the checksum-verified upstream release binary on a
  digest-pinned Cloudron base image. Images and the catalog carry GitHub build
  provenance.

**Tested** on Cloudron 9.1 with Tailscale 1.104.1 clients: enrolment by SSO
and pre-auth key, direct connections, relay-only connections through the
embedded DERP server, restart, backup and restore, and an update between
builds.

**Links**

- Package, setup guide and issues: <https://github.com/marcusquinn/cloudron-headscale-app>
- Headscale docs: <https://headscale.net/stable/>

This is a first release, so feedback is welcome, especially from people
running it with many devices, subnet routers or exit nodes. I maintain the
package independently of the Headscale project and I'm not affiliated with
Tailscale Inc.; please report packaging problems on the package repo rather
than upstream.
