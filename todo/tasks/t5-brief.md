# t5: Qualify Headscale package on Cloudron and submit to Community Apps

## Origin

- **Created:** 2026-09-27
- **Session:** opencode:ses_f1f59ba62ffeapMbfcXvy05cN5
- **Created by:** ai-interactive (Marcus Quinn session)
- **Blocked by:** t4 (package implementation PR merged)
- **Conversation context:** Operator half of the Headscale package lifecycle. These steps need the maintainer's GitHub secret, Cloudron server and Cloudron Community Apps account, so they are not worker-dispatchable.

## What

The package from t4 is published, qualified on a live Cloudron, and listed in Cloudron Community Apps.

## Why

Community Apps submission is the stated end goal; it needs credentials and a real Cloudron install that headless workers do not have.

## How (operator checklist)

1. Create a fine-grained PAT limited to this repository with only `Contents: Read and write`; save it as the repository secret `CLOUDRON_RELEASE_PAT` (see `docs/PUBLISHING.md` "Release credential").
2. Merge the t4 PR (or re-run `cloudron-catalog-publish.yml` on `main`) and confirm the workflow published the image, committed `CloudronVersions.json`, tagged `v<VERSION>`, and created the GitHub release.
3. Install on the Cloudron: `cloudron install --versions-url <PUBLIC_VERSIONS_URL> --location headscale-test`.
4. Qualify: health check green; `cloudron exec` → `headscale users create`/`preauthkeys create`; one Tailscale client registers via `--login-server`; two clients ping each other; DERP relay works with direct UDP blocked; SSO login works when enabled; restart, update (install the next catalog version when available) and backup/restore keep state.
5. Sign in at [Cloudron Community Apps](https://ca.cloudron.io), add the versions URL, and verify the imported icon, hero, description, changelog and install URL.
6. Record evidence (commands, screenshots ≤1568px) in the issue, then add a Headscale section to aidevops `.agents/reference/mesh-remote-workers.md` via a separate aidevops task.

## Acceptance Criteria

- [ ] `CloudronVersions.json` on `main` lists the published version with an immutable image digest.
- [ ] Live install passes the qualification list above, with evidence in the issue.
- [ ] The app appears in Cloudron Community Apps with correct metadata.
- [ ] No secret values appear in the repository, issue, or logs.

## Dependencies

- **Blocked by:** t4
- **External:** GitHub PAT, Cloudron server admin access, Cloudron Community Apps account.
