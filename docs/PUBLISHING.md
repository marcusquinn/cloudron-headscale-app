# Cloudron community publishing

The release workflow is the only writer of `CloudronVersions.json`; do not hand-commit catalog entries or image digests.

Before the first release, add a repository secret named `CLOUDRON_RELEASE_PAT` with repository-scoped Contents read/write access. Merge the completed package change, then let the catalog workflow build and publish the immutable GHCR image and catalog entry.

Qualify the release with `cloudron install --versions-url <PUBLIC_VERSIONS_URL> --location headscale-test`. Check fresh install, upgrade, restart, and backup/restore before submitting the public versions URL to [Cloudron Community Apps](https://ca.cloudron.io).
