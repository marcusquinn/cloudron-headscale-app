# cloudron-headscale-app

<!-- AI-CONTEXT-START -->

## Quick Reference

- **Validate**: `cloudron-package-helper.sh validate`
- **Build**: `cloudron-package-helper.sh build`
- **Test install**: `cloudron-package-helper.sh install headscale-test`
- **Release checks**: `cloudron-package-helper.sh check-compatibility` and
  `cloudron-package-helper.sh preflight-release vX.Y.Z`

## Project Overview

Cloudron app package for [Headscale](https://github.com/juanfont/headscale), a
self-hosted implementation of the Tailscale control server. It lets Tailscale
clients join a mesh whose coordination server you control, with optional
embedded DERP relay and Cloudron OIDC sign-in.

## Architecture

Mirror the structure of `marcusquinn/cloudron-netbird-app`: `Dockerfile` pinned to
the Cloudron base image, `start.sh`, `CloudronManifest.json`, `docs/` for
operator guides, and the Cloudron release and catalog-publish workflows.

## Conventions

- Commits: [Conventional Commits](https://www.conventionalcommits.org/)
- Branches: `feature/`, `bugfix/`, `hotfix/`, `refactor/`, `chore/`
- Documentation: human/operator guides in `docs/`, AI-only context in `.agents/`;
  retain conventional root entrypoints and respect existing repository conventions.

## Key Files

| File | Purpose |
|------|---------|
| `.agents/AGENTS.md` | Project-specific agent instructions |
| `docs/` | Human/operator guides, linked from root entrypoints |
| `TODO.md` | Task tracking |
| `CHANGELOG.md` | Version history |

<!-- AI-CONTEXT-END -->
