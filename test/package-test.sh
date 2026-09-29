#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
    jq -e '.id == "com.marcusquinn.cloudron.headscale" and .httpPort == 8080 and .healthCheckPath == "/health" and .optionalSso == true and .udpPorts.STUN_PORT.defaultValue == 3479 and .addons.localstorage == {} and .addons.oidc.loginRedirectUri == "/oidc/callback"' "${ROOT_DIR}/CloudronManifest.json" >/dev/null || fail "manifest contract failed" || return 1
    contains Dockerfile 'cloudron/base:6.0.0@sha256:9bed4c8fa880645f8e669041ee28febe941481d00e9445e3e5a5483cb541d09b' || return 1
    contains Dockerfile 'HEADSCALE_SHA256=212ed0a884c0d3541e094c4bebbe94397df6f4e01bd3d7f059c520cb55e0d757' || return 1
    # shellcheck disable=SC2016 # The Dockerfile literal must retain ${PATH}.
    contains Dockerfile 'ENV PATH="/app/code/bin:${PATH}"' || return 1
    contains Dockerfile 'HEADSCALE_CONFIG=/app/data/config.yaml' || return 1
    contains config.template.yaml 'path: /app/data/db.sqlite' || return 1
    contains start.sh 'exec gosu cloudron:cloudron' || return 1
    contains start.sh 'chown -R cloudron:cloudron' || return 1
    contains docs/PUBLISHING.md 'CLOUDRON_RELEASE_PAT' || return 1
    bash -n "${ROOT_DIR}/start.sh"
    shellcheck "${ROOT_DIR}/start.sh" "${ROOT_DIR}/scripts/publish-cloudron-catalog.sh" "${ROOT_DIR}/test/package-test.sh"
    printf '%s\n' 'PASS: Headscale Cloudron package contract'
    return 0
}

main "$@"
