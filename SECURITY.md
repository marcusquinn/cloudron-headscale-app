# Security policy

Report vulnerabilities privately through the repository security advisory flow. Do not include credentials, enrolment keys, or mesh member data in public issues.

## Supported versions

| Package version | Supported |
| --- | --- |
| Latest published release | Yes |
| Older releases | No. Update the app in Cloudron. |

Each package release records its Headscale version in [CHANGELOG.md](CHANGELOG.md)
and in `upstreamVersion` in [CloudronManifest.json](CloudronManifest.json).

## Scope

This policy covers the Cloudron packaging: `Dockerfile`, `start.sh`,
`config.template.yaml` and the manifest. Report vulnerabilities in Headscale
itself to the [upstream project](https://github.com/juanfont/headscale/security).
