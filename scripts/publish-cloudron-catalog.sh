#!/usr/bin/env bash
set -euo pipefail

fail() {
    local message="$1"
    printf 'ERROR: %s\n' "${message}" >&2
    return 1
}

main() {
    local catalog_path="${1:-CloudronVersions.json}"
    local image_ref="${2:-${EXPECTED_IMAGE_REF:-}}"
    local expected_version="${3:-${EXPECTED_VERSION:-}}"

    [[ -f "${catalog_path}" ]] || fail "Catalog not found: ${catalog_path}" || return 1
    [[ -n "${image_ref}" && "${image_ref}" == *@sha256:* ]] || fail "An immutable image reference is required" || return 1
    [[ "$(jq -r '.version' CloudronManifest.json)" == "${expected_version}" ]] || fail "Manifest version does not match expected version" || return 1
    cloudron versions add --state testing --image "${image_ref}"
    cloudron versions update --version="${expected_version}" --state=published --image "${image_ref}"
    cloudron versions verify
    return 0
}

main "$@"
