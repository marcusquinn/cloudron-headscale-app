#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Render the Cloudron store slides (media/listing-N-<name>.png, 2400x800) from
# media/src/slide.html.
# Usage: CHROME=/path/to/chrome-headless-shell scripts/render-store-media.sh
set -euo pipefail

render_slide() {
    local chrome="$1"
    local root="$2"
    local number="$3"
    local name="$4"
    local out="${root}/media/listing-${number}-${name}.png"
    "$chrome" --headless --disable-gpu --hide-scrollbars --allow-file-access-from-files \
        --window-size=1200,400 --force-device-scale-factor=2 --virtual-time-budget=3000 \
        --screenshot="$out" "file://${root}/media/src/slide.html#${number}" >/dev/null 2>&1 || return 1
    test -s "$out" || return 1
    printf 'Rendered %s\n' "$out"
    return 0
}

main() {
    local root chrome
    root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    chrome="${CHROME:-}"
    if [[ -z "$chrome" ]]; then
        chrome="$(command -v chrome-headless-shell || command -v chromium || true)"
    fi
    [[ -n "$chrome" && -x "$chrome" ]] || { printf 'Set CHROME to a headless Chromium binary\n' >&2; return 1; }
    render_slide "$chrome" "$root" 1 devices || return 1
    render_slide "$chrome" "$root" 2 sso || return 1
    render_slide "$chrome" "$root" 3 relay || return 1
    render_slide "$chrome" "$root" 4 terminal || return 1
    return 0
}

main "$@"
