#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

readonly DATA_DIR="/app/data"
readonly CONFIG_PATH="${DATA_DIR}/config.yaml"

fail() {
    local message="$1"
    printf 'ERROR: %s\n' "${message}" >&2
    return 1
}

validate_environment() {
    if [[ -z "${CLOUDRON_APP_DOMAIN:-}" ]]; then
        fail "CLOUDRON_APP_DOMAIN is required" || return 1
    fi
    if [[ -n "${STUN_PORT:-}" ]] && ! [[ "${STUN_PORT}" =~ ^[0-9]+$ ]]; then
        fail "STUN_PORT must be a valid UDP port" || return 1
    fi
    return 0
}

write_initial_config() {
    local stun_address=""
    local derp_enabled="false"
    local temporary_path="${CONFIG_PATH}.tmp"

    if [[ -n "${STUN_PORT:-}" ]]; then
        stun_address="0.0.0.0:${STUN_PORT}"
        derp_enabled="true"
    fi

    sed -e "s|__SERVER_URL__|https://${CLOUDRON_APP_DOMAIN}|g" \
        -e "s|__APP_DOMAIN__|${CLOUDRON_APP_DOMAIN}|g" \
        -e "s|__DERP_ENABLED__|${derp_enabled}|g" \
        -e "s|__STUN_LISTEN_ADDR__|${stun_address}|g" \
        /app/code/config.template.yaml >"${temporary_path}"
    mv "${temporary_path}" "${CONFIG_PATH}"
    return 0
}

apply_cloudron_settings() {
    local escaped_domain="${CLOUDRON_APP_DOMAIN//|/\\|}"

    # Only package-owned listener and public URL keys are changed after setup.
    sed -i -e "s|^server_url:.*|server_url: \"https://${escaped_domain}\"|" \
        -e 's|^listen_addr:.*|listen_addr: "0.0.0.0:8080"|' \
        -e 's|^metrics_listen_addr:.*|metrics_listen_addr: "127.0.0.1:9090"|' \
        -e 's|^grpc_listen_addr:.*|grpc_listen_addr: "127.0.0.1:50443"|' \
        "${CONFIG_PATH}"
    return 0
}

report_oidc_availability() {
    if [[ -n "${CLOUDRON_OIDC_ISSUER:-}" && -n "${CLOUDRON_OIDC_CLIENT_ID:-}" && -n "${CLOUDRON_OIDC_CLIENT_SECRET:-}" ]]; then
        printf '%s\n' 'Cloudron OIDC credentials are available; see the operator guide for /oidc/callback setup.'
    elif [[ -n "${CLOUDRON_OIDC_ISSUER:-}${CLOUDRON_OIDC_CLIENT_ID:-}${CLOUDRON_OIDC_CLIENT_SECRET:-}" ]]; then
        printf '%s\n' 'WARNING: incomplete optional Cloudron OIDC environment; continuing without OIDC.' >&2
    fi
    return 0
}

main() {
    validate_environment || return 1
    mkdir -p "${DATA_DIR}"
    if [[ ! -f "${CONFIG_PATH}" ]]; then
        write_initial_config || return 1
    fi
    apply_cloudron_settings || return 1
    report_oidc_availability || return 1
    chown -R cloudron:cloudron "${DATA_DIR}"
    exec gosu cloudron:cloudron /app/code/bin/headscale serve --config "${CONFIG_PATH}"
}

main "$@"
