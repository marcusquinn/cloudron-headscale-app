Headscale is running. It has no web interface; devices connect with the
Tailscale app and you manage it from the app's Terminal.

<sso>
**Add a device:** run

    tailscale up --login-server https://$CLOUDRON-APP-FQDN

and sign in with your Cloudron account in the browser that opens. Every
Cloudron user allowed by this app's access control can add devices. On macOS,
iOS and Windows, set the server under the app's alternate coordination server
option; see `https://$CLOUDRON-APP-FQDN/apple` and `/windows`.
</sso>

<nosso>
**Add a device:** in the Terminal, create a user and a pre-auth key:

    headscale users create alice
    headscale preauthkeys create --user 1 --expiration 1h

then on the device run
`tailscale up --login-server https://$CLOUDRON-APP-FQDN --authkey <key>`.
</nosso>

**Servers and headless devices:** use a pre-auth key as above. List devices
with `headscale nodes list`.

**STUN port:** if your server sits behind a provider firewall, allow the UDP
port shown under *Location*, so devices can find direct paths and use the
embedded relay.

Settings live in `/app/data/config.yaml`; restart after editing. Setup guide:
[README](https://github.com/marcusquinn/cloudron-headscale-app/blob/main/README.md).
