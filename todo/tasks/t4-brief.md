<!-- aidevops:brief-schema=v2 -->

# t4: Package Headscale as a Cloudron app through Community Apps submission

## Pre-flight (auto-populated by briefing workflow)

- [x] Memory recall: `aidevops init new repo cloudron app community directory publishing` → 0 hits — no relevant lessons
- [x] Discovery pass: 0 commits / 0 merged PRs / 0 open PRs touch target files (new repository; `gh search repos "cloudron headscale"` returned no existing package)
- [x] File refs verified: 9 refs checked in `marcusquinn/cloudron-netbird-app` and `marcusquinn/aidevops` at current `main`
- [x] Tier: `tier:standard` — design boundaries are decided below; the worker still composes a new package from a verified reference pattern
- [x] Seeded draft PR decision recorded: skipped — no package code exists yet and a seed would anchor unverified runtime choices

## Origin

- **Created:** 2026-09-27
- **Session:** opencode:ses_f1f59ba62ffeapMbfcXvy05cN5
- **Created by:** ai-interactive (Marcus Quinn session)
- **Parent task:** none
- **Blocked by:** none
- **Conversation context:** After deploying Nostr VPN and NetBird mesh remote workers, the maintainer wants self-hosted replacements for third-party coordination and relay services. Headscale gives Tailscale clients a control server we own, packaged like `cloudron-netbird-app`.

## What

A complete, publishable Cloudron app package for Headscale in this repository:

- Installs on Cloudron (minBoxVersion 9.1.0 or the lowest version the chosen features need) with the Headscale control plane at `https://<app domain>/` behind Cloudron TLS.
- Tailscale clients (`tailscale up --login-server https://<app domain>`) register, receive a mesh address, and reach each other.
- Embedded DERP relay enabled, with STUN on a manifest `udpPorts` entry whose default does **not** collide with the NetBird app's UDP 3478 on the same box (use 3479 by default).
- Optional Cloudron SSO through the `oidc` addon (`optionalSso: true`); pre-auth-key registration works when SSO is off.
- State (SQLite database, noise private key, DERP key, generated `config.yaml`) lives under `/app/data` and survives restart, update and backup/restore.
- A managed release pipeline identical in shape to `cloudron-netbird-app`: pull-request validation, GHCR image, `CloudronVersions.json` catalog publication, attestations, and a thin tag-triggered release caller.
- Operator documentation for install, first user/pre-auth key creation via `cloudron exec`, client enrolment, DERP/STUN ports, and backup/restore.

## Why

Mesh remote workers currently rely on NetBird (self-hosted) or Nostr VPN (third-party FIPS bootstrap peers). Tailscale clients are the most polished mobile/desktop mesh clients, but using them normally means Tailscale's hosted coordination server. A Headscale Cloudron app keeps coordination and relay traffic on infrastructure we control, matching the standing preference for self-hosted, private transport. No Cloudron package exists (`gh search repos "cloudron headscale"` returned `[]`).

## Tier

### Tier checklist (verify before assigning)

- [ ] **Exact execution contract supplied?** No — new package files are composed from a reference pattern.
- [x] **Targets and reference pattern verified?** Yes — `cloudron-netbird-app` layout and aidevops templates below.
- [ ] **No semantic or design decision remains?** Minor runtime choices (config generation details, health path confirmation) remain.
- [x] **Bounded, reversible, low-consequence impact?** New repository; nothing published until merge with a release secret present.
- [x] **No stateful coordination to invent?** Single container, SQLite.
- [x] **Focused verification and rollback are explicit?** Yes.
- [x] **No dispatch-path risk override?** Not an aidevops dispatch-path file.

**Selected tier:** `tier:standard`

**Tier rationale:** Architecture, ports, storage and SSO decisions are fixed in this brief; the worker composes a known package shape from a verified reference, with bounded local runtime choices.

## PR Conventions

Leaf task: the implementation PR uses `Resolves #<this issue>`.

## How (Approach)

### Progressive Context Plan

- **Read first:** `marcusquinn/cloudron-netbird-app` files `CloudronManifest.json`, `Dockerfile`, `start.sh`, `docs/PUBLISHING.md`, `.github/workflows/cloudron-catalog-publish.yml`, `scripts/publish-cloudron-catalog.sh` — package and publication shape to mirror.
- **Load only if:** `~/.aidevops/agents/tools/deployment/cloudron-app-packaging.md` and `cloudron-app-packaging-skill/manifest-ref/02-ports.md`, `03-addons.md`, `05-behavior.md` — when choosing manifest fields (`udpPorts`, `oidc`, `optionalSso`).
- **Load only if:** Headscale upstream `config-example.yaml` and reverse-proxy docs at the pinned release tag (`gh api repos/juanfont/headscale/contents/config-example.yaml?ref=v0.29.4`) — when generating `config.yaml`.
- **Why:** mirror a proven publication pipeline; only the Headscale runtime is new.
- **Stop when:** manifest, config template, start script and workflow adaptations are clear.

### Worker Quick-Start

```bash
# Upstream: juanfont/headscale, BSD-3-Clause, latest stable v0.29.4 (2026-09-23)
gh release view v0.29.4 -R juanfont/headscale --json assets --jq '.assets[].name'
# Reference package (clone read-only for inspection)
gh repo clone marcusquinn/cloudron-netbird-app ~/.aidevops/.agent-workspace/tmp/netbird-ref
# Release caller template shipped by aidevops
cat ~/.aidevops/agents/templates/workflows/cloudron-package-release-caller.yml
```

Key facts:

- Headscale listens on one HTTP port for API, web registration, Noise (`/ts2021` HTTP upgrade) and DERP (`/derp` HTTP upgrade). Put it on `httpPort` 8080 behind Cloudron nginx; Cloudron terminates TLS.
- `server_url` must be `https://${CLOUDRON_APP_DOMAIN}`; MagicDNS `dns.base_domain` must differ from the server domain.
- STUN is UDP: declare `udpPorts.STUN_PORT` (default 3479) and set `derp.server.stun_listen_addr` from that env var; handle the env var being absent when the operator disables the port (disable embedded STUN, keep DERP over HTTPS).
- Cloudron `oidc` addon env: `CLOUDRON_OIDC_ISSUER`, `CLOUDRON_OIDC_CLIENT_ID`, `CLOUDRON_OIDC_CLIENT_SECRET`; Headscale callback path `/oidc/callback`.

### Files to Modify

- `NEW: CloudronManifest.json` — id `com.marcusquinn.cloudron.headscale` (packager-owned namespace), httpPort 8080, `udpPorts.STUN_PORT`, addons `localstorage` + `oidc`, `optionalSso: true`, healthCheckPath `/health` (confirm upstream endpoint), metadata/tags modelled on the NetBird manifest.
- `NEW: Dockerfile` — `FROM` the digest-pinned Cloudron base image used by `cloudron-netbird-app`; download the pinned Headscale linux amd64 release binary and verify its published checksum.
- `NEW: start.sh` — generate `/app/data/config.yaml` from a template on first run, re-apply Cloudron-owned keys (server_url, listen, OIDC, STUN, paths) every start, `chown cloudron:cloudron /app/data`, exec Headscale as `cloudron` via `gosu`.
- `NEW: config.template.yaml` — Headscale config with `/app/data` paths, SQLite, embedded DERP, metrics on `127.0.0.1:9090`, gRPC on localhost only.
- `NEW: CHANGELOG` and `NEW: CHANGELOG.md` — Cloudron-format and Keep a Changelog, first entry 0.1.0.
- `NEW: logo.png` (256×256) and `NEW: media/hero.png` (1188×396) — use upstream artwork only if its licence permits; otherwise generate original artwork and record provenance in `DESIGN.md`.
- `NEW: docs/README.md`, `NEW: docs/PACKAGING-NOTES.md`, `NEW: docs/PUBLISHING.md` — adapt NetBird's publishing doc (image name, test location `headscale-test`).
- `NEW: scripts/publish-cloudron-catalog.sh` — adapt from NetBird (image `ghcr.io/marcusquinn/cloudron-headscale-app`).
- `NEW: .github/workflows/cloudron-catalog-publish.yml` — adapt from NetBird.
- `NEW: .github/workflows/cloudron-package-release.yml` — copy the aidevops caller template unchanged.
- `NEW: .github/workflows/linked-issue-check.yml`, `NEW: .github/dependabot.yml` — copy from NetBird.
- `NEW: SECURITY.md`, `NEW: CONTRIBUTING.md`, `NEW: .dockerignore`, `NEW: .editorconfig` — adapt from NetBird.
- `NEW: test/package-test.sh` — static package checks modelled on NetBird's `test/package-test.sh`.
- `EDIT: README.md` — install, enrolment and port summary; keep the managed badge and README blocks intact.
- `EDIT: AGENTS.md` — replace placeholders only if commands change.
- `EDIT: DESIGN.md` — record logo/hero source and palette.

### Complete Write Surface

- **Callers/readers:** Cloudron reads `CloudronManifest.json` and `CloudronVersions.json`; Tailscale clients call `/ts2021`, `/derp`, `/register`, `/oidc/callback`; aidevops `cloudron-package-monitor-helper.sh` reads the manifest from the default branch.
- **Writers/mutation paths:** `start.sh` writes `/app/data/config.yaml` and key files; Headscale writes `/app/data/db.sqlite`; only `cloudron-catalog-publish.yml` writes `CloudronVersions.json` and tags.
- **Existing verification/tests:** none in this repository yet; NetBird's `test/package-test.sh` and `test/publish-catalog-test.sh` are the patterns to adapt.
- **Schemas/config:** `CloudronManifest.json`, `config.template.yaml`, `CloudronVersions.json` (generated by the workflow only).
- **Generated/deployed mirrors:** GHCR image and `CloudronVersions.json` produced by the catalog workflow; never hand-written.
- **Migrations/backfills:** Headscale runs its own SQLite migrations on start; `start.sh` must back up `db.sqlite` to `/app/data/db.sqlite.bak-<version>` before an upstream version change.
- **Cleanup/rollback paths:** Cloudron backup/restore of `/app/data`; published catalog entries are append-only (`cloudron versions revoke` + new version for bad releases).

### Implementation Steps

1. Inspect the NetBird reference files listed above and the Headscale v0.29.4 `config-example.yaml`.
2. Write the manifest, Dockerfile, `config.template.yaml` and `start.sh`. Idempotent first-run setup: create keys only when missing; never overwrite operator-edited non-Cloudron config keys.
3. Adapt the publication scripts and workflows, replacing NetBird names and image paths.
4. Build and run locally: `docker build -t headscale-cloudron:dev .`, run with `/app/data` bind-mounted and `CLOUDRON_APP_DOMAIN=localhost`, confirm `/health` returns 200, then `headscale users create test` and `headscale preauthkeys create --user <id>` succeed via `docker exec`.
5. Register a real client against the local container where feasible (`tailscale up --login-server http://127.0.0.1:8080 --authkey <key>` in a second container) and record output in the PR.
6. Write docs, CHANGELOGs and artwork; run the verification block; open the PR.

### Hazards and Compatibility

- **Concurrency/atomicity:** single Headscale process with SQLite; no concurrent writers. `start.sh` writes config via temp file + `mv`.
- **Migration/rollback:** upstream schema migrations are one-way; back up `db.sqlite` before version changes and document restore via Cloudron backup.
- **Mixed-version/backward compatibility:** first release, no prior catalog entries; future manifests must stay parseable by `minBoxVersion`.
- **Idempotency/retry:** start script safe to run on every restart; key generation only when files are missing; catalog workflow already fail-closed and idempotent.
- **Partial failure/recovery:** if config generation fails, exit non-zero so Cloudron marks the app unhealthy rather than starting with defaults; missing `STUN_PORT` disables STUN only.

### Verification Before Dispatch

```bash
cloudron-package-helper.sh validate
cloudron-package-helper.sh check-compatibility
bash test/package-test.sh
shellcheck start.sh scripts/*.sh test/*.sh
docker build -t headscale-cloudron:dev .
docker run -d --name hs -p 8080:8080 -v "$PWD/.tmp-data:/app/data" -e CLOUDRON_APP_DOMAIN=localhost headscale-cloudron:dev
curl -fsS http://127.0.0.1:8080/health
docker exec hs headscale users list
```

- **Surface mapping:** `validate`/`check-compatibility` prove manifest and pinned base; `package-test.sh` proves static package invariants; `shellcheck` covers scripts; the docker commands prove the runtime, config generation, `/app/data` persistence and health path. The pull-request run of `cloudron-catalog-publish.yml` proves the publication pipeline validates without publishing.
- **Broad verification trigger:** Not required — new standalone repository.

### Recoverability Checkpoint

- [ ] Focused functional verification passes: `docker build` + health + `headscale users list`
- [ ] WIP commit created before broad gates: `wip: headscale cloudron package runtime`
- [ ] Evidence-triggered broad verification then run: not required — new repository

### Scope Boundaries

**Hard boundaries:** do not add `CloudronVersions.json` by hand; do not store secrets in the repository; do not change NetBird or aidevops repositories from this task.

**AI brief owner:** marcusquinn interactive session (this brief).

**Recovery:** preserve the current PR and use the structured runtime request and Pulse intake in `reference/worker-discipline.md` when local recovery is unsafe.

### Files Scope

- `CloudronManifest.json`
- `Dockerfile`
- `.dockerignore`
- `.editorconfig`
- `start.sh`
- `config.template.yaml`
- `CHANGELOG`
- `CHANGELOG.md`
- `README.md`
- `AGENTS.md`
- `DESIGN.md`
- `SECURITY.md`
- `CONTRIBUTING.md`
- `logo.png`
- `media/hero.png`
- `docs/README.md`
- `docs/PACKAGING-NOTES.md`
- `docs/PUBLISHING.md`
- `scripts/publish-cloudron-catalog.sh`
- `test/package-test.sh`
- `.github/workflows/cloudron-catalog-publish.yml`
- `.github/workflows/cloudron-package-release.yml`
- `.github/workflows/linked-issue-check.yml`
- `.github/dependabot.yml`
- `TODO.md`
- `todo/tasks/t4-brief.md`

## Acceptance Criteria

- [ ] The package builds and the container serves a healthy Headscale control plane with state in `/app/data`.

  ```yaml
  verify:
    method: bash
    run: "cloudron-package-helper.sh validate && bash test/package-test.sh"
  ```

- [ ] The STUN UDP port default is not 3478 and the manifest declares it under `udpPorts`.

  ```yaml
  verify:
    method: bash
    run: "jq -e '.udpPorts.STUN_PORT.defaultValue != 3478' CloudronManifest.json"
  ```

- [ ] No catalog or secret material is hand-committed.

  ```yaml
  verify:
    method: codebase
    pattern: "BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY|privateKey"
    path: "."
    expect: absent
  ```

- [ ] The pull-request run of `cloudron-catalog-publish.yml` and `linked-issue-check.yml` pass.
- [ ] PR body includes the local docker evidence (health response, user/pre-auth key creation, and client registration output or the documented reason it could not run).
- [ ] `docs/PUBLISHING.md` lists the operator hand-off steps: add the `CLOUDRON_RELEASE_PAT` secret, live install via `cloudron install --versions-url <PUBLIC_VERSIONS_URL> --location headscale-test`, upgrade/restart/backup-restore checks, and Community Apps submission at ca.cloudron.io.
- [ ] Changed-file lint is clean (`shellcheck`, markdownlint where configured).

## Context & Decisions

- Mirror `cloudron-netbird-app` structure and publication pipeline instead of inventing a new one.
- Embedded DERP over HTTPS through Cloudron nginx; STUN on a separate UDP port defaulting to 3479 to coexist with NetBird's 3478.
- Cloudron SSO via `oidc` addon with `optionalSso: true`; pre-auth keys remain the non-SSO path.
- Admin is CLI-first (`cloudron exec` → `headscale ...`). A Headplane web UI is a non-goal for 0.1.0; file a follow-up if wanted.
- If Cloudron nginx does not pass the `/ts2021` or `/derp` HTTP upgrades unbuffered, fall back to NetBird's pattern: a dedicated `tcpPorts` listener with TLS terminated in-app via the `tls` addon. Record the evidence either way in `docs/PACKAGING-NOTES.md`.
- Operator-only steps (secret, live Cloudron qualification, Community Apps submission) are tracked in the follow-up operator task, not in this worker task.

## Relevant Files

- `marcusquinn/cloudron-netbird-app:CloudronManifest.json` — manifest shape, `udpPorts`, `oidc` addon usage.
- `marcusquinn/cloudron-netbird-app:docs/PUBLISHING.md` — publication flow and release credential rules.
- `marcusquinn/cloudron-netbird-app:.github/workflows/cloudron-catalog-publish.yml` — catalog pipeline to adapt.
- `marcusquinn/aidevops:.agents/templates/workflows/cloudron-package-release-caller.yml` — release caller.
- `marcusquinn/aidevops:.agents/tools/deployment/cloudron-app-packaging.md` — managed package lifecycle.

## Dependencies

- **Blocked by:** none
- **Blocks:** operator qualification and Community Apps submission task (t5)
- **External:** none for the worker; GHCR publication uses `GITHUB_TOKEN`, catalog push needs the operator-provided `CLOUDRON_RELEASE_PAT`.

## Estimate Breakdown

| Phase | Time | Notes |
|-------|------|-------|
| Research/read | 45m | NetBird reference, Headscale config and reverse-proxy docs |
| Implementation | 4h | manifest, Dockerfile, start script, config, workflows, docs, artwork |
| Verification | 1h | local docker runtime, client registration, CI |
| **Total** | **~6h** | |
