# t8: docs: make SECURITY.md supported versions release-independent

- **Issue:** GH#40

## What

`SECURITY.md:7` lists only package 0.1.0 / Headscale 0.29.4 as supported. The current release is 0.1.3 / Headscale 0.29.7 (GH#37, PR #38). The table goes stale because the upstream-release brief's Files Scope (`CloudronManifest.json`, `Dockerfile`, `CHANGELOG`, `CHANGELOG.md`, `test/package-test.sh`) never includes `SECURITY.md`.

## Files Scope

- `SECURITY.md`

## How

Replace the per-version row with a policy that names no specific version:
- The latest published package version is supported.
- Older installs should update in Cloudron.
- The Headscale version in each release is recorded in `CHANGELOG.md` and in `upstreamVersion` in `CloudronManifest.json`.

Add a scope note that sends Headscale vulnerabilities upstream. Follow the Scope section of `SECURITY.md` in marcusquinn/cloudron-netbird-app.

## Acceptance criteria

- `SECURITY.md` names no specific package or Headscale version, so future upstream bumps cannot make it stale.
- Private reporting through the repository security advisory flow is preserved.

## Verification

- `bash test/package-test.sh` passes.
- The Markdown table renders correctly.
