Headscale is an open-source, self-hosted implementation of the Tailscale
control server. Devices run the official Tailscale apps and join a private
WireGuard mesh (a "tailnet") that your Cloudron coordinates, instead of
Tailscale's hosted service.

### Features

* **Official Tailscale clients** on Linux, macOS, Windows, iOS and Android,
  pointed at your server with `--login-server`.
* **Direct WireGuard connections** between devices, with NAT traversal.
* **Embedded DERP relay** for devices that cannot connect directly. Tailscale's
  public relays stay available as a fallback.
* **MagicDNS** names for every device, plus ACL policies, tags, subnet routers
  and exit nodes.
* **Pre-auth keys** for servers and devices that cannot open a browser.

### Cloudron integration

* **Single sign-on:** `tailscale up` opens a Cloudron login. The app's access
  control decides who can add devices.
* **One HTTPS address:** control traffic, the Noise protocol and the DERP relay
  all use the app's HTTPS domain. One extra UDP port carries STUN.
* **Backups:** the SQLite database, keys and `config.yaml` in `/app/data` are
  in Cloudron backups.

Headscale has no web interface. Manage users, devices, keys and routes with the
`headscale` command in the app's Terminal.

[Headscale](https://github.com/juanfont/headscale) is open source under the
BSD-3-Clause licence. This package is maintained independently of the
Headscale project and is not affiliated with Tailscale Inc.
