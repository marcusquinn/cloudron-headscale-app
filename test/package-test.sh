#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Static package checks: manifest contract, pinned build inputs, store metadata
# and publishing guards. Runs in CI preflight and locally.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly RAW_PREFIX='^https://raw.githubusercontent.com/marcusquinn/cloudron-headscale-app/[0-9a-f]{40}/'

fail() {
    local message="$1"
    printf 'FAIL: %s\n' "${message}" >&2
    return 1
}

contains() {
    local path="$1"
    local expected="$2"
    grep -Fq -- "${expected}" "${ROOT_DIR}/${path}" || fail "${path} is missing ${expected}" || return 1
    return 0
}

main() {
    local file version push_job
    cd "${ROOT_DIR}"
    jq -e '.id == "com.marcusquinn.cloudron.headscale" and .manifestVersion == 2 and .httpPort == 8080
        and .healthCheckPath == "/health" and .minBoxVersion == "9.1.0" and .optionalSso == true
        and .udpPorts.STUN_PORT.defaultValue == 3480 and .addons.localstorage == {}
        and .addons.oidc.loginRedirectUri == "/oidc/callback"' CloudronManifest.json >/dev/null ||
        fail "manifest contract failed" || return 1

    # Build inputs are pinned: base image digest and checksum-verified upstream binary.
    contains Dockerfile 'FROM cloudron/base:6.0.0@sha256:9bed4c8fa880645f8e669041ee28febe941481d00e9445e3e5a5483cb541d09b' || return 1
    grep -Eq '^ARG HEADSCALE_SHA256=[0-9a-f]{64}$' Dockerfile || fail "Headscale binary checksum not pinned" || return 1
    version="$(sed -n 's/^ARG HEADSCALE_VERSION=//p' Dockerfile)"
    [[ "$(jq -r .upstreamVersion CloudronManifest.json)" == "${version}" ]] ||
        fail "upstreamVersion does not match HEADSCALE_VERSION" || return 1
    contains Dockerfile 'sha256sum --check --strict' || return 1
    # shellcheck disable=SC2016 # Literal Dockerfile text, not a shell expansion.
    contains Dockerfile 'HEADSCALE_VERSION=${HEADSCALE_VERSION}' || return 1
    contains Dockerfile "EXPOSE 8080 $(jq -r .udpPorts.STUN_PORT.defaultValue CloudronManifest.json)/udp" || return 1
    contains Dockerfile 'HEADSCALE_CONFIG=/app/data/config.yaml' || return 1
    contains config.template.yaml 'path: /app/data/db.sqlite' || return 1
    contains start.sh 'exec gosu cloudron:cloudron' || return 1
    contains start.sh 'chown -R cloudron:cloudron' || return 1
    # shellcheck disable=SC2016 # Literal start.sh heredoc text, not a shell expansion.
    contains start.sh 'redirect_uri: "https://${CLOUDRON_APP_DOMAIN}/oidc/callback"' || return 1

    # Store metadata comes from these files; media and icon URLs are commit-pinned HTTPS.
    for file in CHANGELOG CHANGELOG.md DESCRIPTION.md POSTINSTALL.md README.md logo.png \
        docs/PACKAGING-NOTES.md docs/PUBLISHING.md media/src/slide.html; do
        test -s "${file}" || fail "missing ${file}" || return 1
    done
    jq -e --arg prefix "${RAW_PREFIX}" '.description == "file://DESCRIPTION.md" and .postInstallMessage == "file://POSTINSTALL.md"
        and .changelog == "file://CHANGELOG" and (.tags | length > 0)
        and (.iconUrl | test($prefix + "logo.png$"))
        and (.mediaLinks | length > 0 and all(test($prefix + "media/")))' CloudronManifest.json >/dev/null ||
        fail "store metadata incomplete or not commit-pinned" || return 1
    for file in $(jq -r --arg prefix "${RAW_PREFIX}" '.mediaLinks[] | sub($prefix; "")' CloudronManifest.json); do
        test -s "${file}" || fail "mediaLinks entry ${file} is not in the repository" || return 1
    done
    grep -Eq "^\[$(jq -r .version CloudronManifest.json)\]$" CHANGELOG || fail "CHANGELOG has no section for the manifest version" || return 1

    # Only the authorized CLI publication writes the catalog; never hand-edit it.
    jq -e '.versions | type == "object"' CloudronVersions.json >/dev/null || fail "CloudronVersions.json malformed" || return 1
    contains .github/workflows/cloudron-catalog-publish.yml 'CLOUDRON_PUBLICATION_ENABLED' || return 1
    contains .github/workflows/cloudron-catalog-publish.yml 'scripts/create-github-release.sh' || return 1
    # Check the write-capable job, not only the unprivileged publish job.
    push_job="$(sed -n '/^  push:/,/^  release:/p' .github/workflows/cloudron-catalog-publish.yml)"
    grep -Fq 'needs: [preflight, build, publish]' <<< "${push_job}" || fail "push job must depend on the image build" || return 1
    grep -Fq -- 'jq -e --slurpfile candidate' <<< "${push_job}" || fail "push job must validate catalog contents" || return 1
    # shellcheck disable=SC2016 # Literal jq text, not a shell expansion.
    grep -Fq -- '$catalog.versions[$v] == $source.versions[$v]' <<< "${push_job}" || fail "push job must preserve existing versions" || return 1
    contains docs/PUBLISHING.md 'CLOUDRON_PUBLICATION_ENABLED' || return 1

    for file in start.sh scripts/*.sh test/*.sh; do
        bash -n "${file}" || fail "syntax error in ${file}" || return 1
    done
    shellcheck start.sh scripts/*.sh test/*.sh
    printf '%s\n' 'PASS: Headscale Cloudron package contract'
    return 0
}

main "$@"
