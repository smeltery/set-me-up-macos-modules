#!/bin/bash
# Shared helpers for macos modules that can install via Homebrew cask
# (brewfile) or by downloading the same vendor artifact (dmg/zip/pkg).
#
# Usage (from a module script, after smu::import base/system/homebrew):
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts/lib/install-app.sh"
#   macos_modules::install_cask_or_vendor "cleanshot"
#
# Prefer cask when brew is available. Force the vendor path with:
#   SMU_VENDOR_INSTALL=1 smu -m productivity/cleanshot

# shellcheck disable=SC2034

macos_modules::cask_download_url() {
    local token="$1"
    local url

    url="$(curl -fsSL "https://formulae.brew.sh/api/cask/${token}.json" \
        | python3 -c 'import json, sys; print(json.load(sys.stdin)["url"])')" || return 1

    [[ -n "$url" ]] || return 1
    printf '%s\n' "$url"
}

# Resolve redirects so install_from_URL can detect .dmg/.zip/.pkg from the basename.
macos_modules::resolve_download_url() {
    local url="$1"
    local final

    final="$(curl -fsSIL -o /dev/null -w '%{url_effective}' "$url" 2>/dev/null)" || final="$url"
    [[ -n "$final" ]] || final="$url"
    printf '%s\n' "$final"
}

# macos_modules::install_cask_or_vendor <cask-token> [--rename-from <App.app>] [--rename-to <App.app>]
macos_modules::install_cask_or_vendor() {
    local token="$1"
    shift

    local rename_from="" rename_to=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --rename-from)
            rename_from="$2"
            shift 2
            ;;
        --rename-to)
            rename_to="$2"
            shift 2
            ;;
        *)
            error "Unknown option: $1"
            return 1
            ;;
        esac
    done

    if [[ "${SMU_VENDOR_INSTALL:-0}" != "1" ]] && cmd_exists brew; then
        brew_bundle_install -f "brewfile"
        return $?
    fi

    local url final
    url="$(macos_modules::cask_download_url "$token")" || {
        error "Could not resolve download URL for cask '${token}'."
        return 1
    }
    final="$(macos_modules::resolve_download_url "$url")"

    ask_for_sudo
    install_from_URL "$final" || return 1

    if [[ -n "$rename_from" && -n "$rename_to" ]]; then
        if [[ -d "/Applications/${rename_from}" && ! -d "/Applications/${rename_to}" ]]; then
            sudo mv "/Applications/${rename_from}" "/Applications/${rename_to}"
        fi
    fi
}
