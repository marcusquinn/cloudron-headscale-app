# Publish the Cloudron package

## Release authority

Pull requests run static package checks, ShellCheck and a dry run of the real
Cloudron CLI. Merging is not publication. The catalog workflow publishes from
`main` only after the operator sets the repository variable
`CLOUDRON_PUBLICATION_ENABLED=true`; setting it is standing authorization for
that workflow's image and catalog publication.

Before enabling it:

1. Keep this repository public. The store reads `iconUrl` and `mediaLinks`
   from `raw.githubusercontent.com`, and Cloudron servers fetch the catalog
   from there.
2. While `main` has no push protection that blocks it, the workflow's
   `GITHUB_TOKEN` pushes the generated catalog commit and tag. Otherwise add
   the repository secret `CLOUDRON_RELEASE_PAT`, scoped to push past those
   rules; the workflow then uses it instead. Never put it in Git or an issue.
   GHCR pushes always use `GITHUB_TOKEN`.

## Pipeline

1. In a PR: bump `version` in `CloudronManifest.json` and add the version's
   section to both `CHANGELOG` (store format, `[X.Y.Z]`) and `CHANGELOG.md`.
   To move to a newer Headscale, update `HEADSCALE_VERSION` and
   `HEADSCALE_SHA256` in the `Dockerfile` from the upstream release's
   `checksums.txt` (`headscale_<version>_linux_amd64`), and `upstreamVersion`,
   always together. Read the upstream changelog for configuration changes.
   A package-only release, such as a manifest or listing change, keeps the
   pin; say so in the changelog.
2. Qualify the build on a test install (below), review, and merge with a merge
   commit. A package-only release that leaves the `Dockerfile` and scripts
   unchanged needs only the PR checks.
3. The catalog workflow builds `linux/amd64`, pushes
   `ghcr.io/marcusquinn/cloudron-headscale-app:<version>` and attests the image
   digest with GitHub keyless provenance.
4. After the first push, make the GHCR package public. Cloudron pulls
   anonymously, and the workflow refuses to publish an image it cannot pull
   anonymously; rerun the failed workflow after changing visibility.
5. The pinned Cloudron CLI (8.2.6, registry integrity checked) adds the version
   as `testing` with the digest-pinned image, promotes it to `published` and
   verifies the catalog. Never hand-edit `CloudronVersions.json`.
6. The workflow attests the catalog in a read-only job. A separate job, the
   only one that can write to the repository, verifies that attestation,
   commits only that file with a skip-CI marker and pushes `main` and the
   `vX.Y.Z` tag atomically.
7. The release job creates the GitHub release from the tag after checking the
   tag is on `main`, the image pulls anonymously and the catalog carries this
   workflow's provenance. Notes come from the version's `CHANGELOG` section.

Published versions are append-only: never rebuild or overwrite one; revoke and
ship a new version instead. Only the catalog commit may carry the skip-CI
marker; describe it in prose elsewhere, because GitHub skips runs whose head
commit message contains it anywhere.

Verify provenance with:

```sh
gh attestation verify oci://ghcr.io/marcusquinn/cloudron-headscale-app@sha256:<digest> --repo marcusquinn/cloudron-headscale-app
gh attestation verify CloudronVersions.json --repo marcusquinn/cloudron-headscale-app
```

## Qualification on a test install

`cloudron install --location <test-location> -p STUN_PORT=3480` from a checkout
builds the image on the server; `cloudron update --app <test-location>`
rebuilds. Check:

- `/health` returns `{"status":"pass"}` and the log shows the expected
  Headscale version and `stun server started`.
- In the Terminal, `headscale users create` and `headscale preauthkeys create`
  work.
- Two Tailscale clients register with a pre-auth key and ping each other
  directly. Disposable clients work: the `tailscale/tailscale` image with
  `TS_USERSPACE=true`, `TS_AUTHKEY` and
  `TS_EXTRA_ARGS=--login-server=https://<test-location>`.
- With `TS_DEBUG_ALWAYS_USE_DERP=true` on both clients and only the embedded
  region in `derp.urls`, `tailscale ping` replies `via DERP(headscale)`.
  Restore `derp.urls` afterwards.
- `tailscale up --login-server https://<test-location>` on a real device opens
  the Cloudron login and the device joins after sign-in.
- Restart, then back up, change state, restore: users and the Noise and DERP
  private keys are unchanged.

To test an update from the catalog, install the previous version with
`cloudron install --versions-url <catalog-url>`, then update and confirm that
`cloudron status --app <app>` reports the new image and devices reconnect.

## Store listing

Catalog URL:
`https://raw.githubusercontent.com/marcusquinn/cloudron-headscale-app/main/CloudronVersions.json`

The CLI copies the manifest into each catalog entry, so a listing shows
`DESCRIPTION.md`, `POSTINSTALL.md`, that version's `CHANGELOG` section, the icon
and `mediaLinks` as they were when published. `iconUrl` and `mediaLinks` are
pinned to commits so published entries never change. Regenerate slides with
`scripts/render-store-media.sh` after editing `media/src/slide.html`. Before
release, check each URL returns HTTPS 200 with an image content type:

```sh
jq -r '.iconUrl, .mediaLinks[]' CloudronManifest.json | xargs -n1 curl -sS -o /dev/null -w '%{http_code} %{content_type} %{url_effective}\n'
```

To list the app on [Cloudron Community Apps](https://ca.cloudron.io), sign in,
add the catalog URL, and check the imported title, icon, screenshots, changelog
and install link. Then post an announcement in the forum's
[Community Packages](https://forum.cloudron.io/category/220/community-packages)
category, record it in [ANNOUNCEMENT.md](ANNOUNCEMENT.md), and set the
manifest's `forumUrl` to the topic. Both are publication actions for the
maintainer; the `forumUrl` reaches the store listing with the next package
release.
