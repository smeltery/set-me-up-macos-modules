#!/bin/bash
# Shared helpers for macos modules that can install via Homebrew cask
# (brewfile), vendor dmg/zip/pkg, or Mac App Store (`mas`).
#
# Usage (from a module script, after smu::import base/system/homebrew):
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts/lib/install-app.sh"
#   macos_modules::install_cask_or_vendor "cleanshot"
#   macos_modules::install_cask_or_vendor "textsniper" --mas-id 1528890965
#
# Install method (first match wins):
#   SMU_INSTALL_METHOD=cask|vendor|mas
#   SMU_VENDOR_INSTALL=1          # alias for vendor
#   SMU_MAS_INSTALL=1             # alias for mas (requires --mas-id)
#
# Default is cask when brew is available; otherwise vendor.

# shellcheck disable=SC2034

macos_modules::resolve_install_method() {
    local has_mas_id="${1:-0}"

    if [[ -n "${SMU_INSTALL_METHOD:-}" ]]; then
        printf '%s\n' "$SMU_INSTALL_METHOD"
        return 0
    fi
    if [[ "${SMU_MAS_INSTALL:-0}" == "1" ]]; then
        printf '%s\n' "mas"
        return 0
    fi
    if [[ "${SMU_VENDOR_INSTALL:-0}" == "1" ]]; then
        printf '%s\n' "vendor"
        return 0
    fi
    if cmd_exists brew; then
        printf '%s\n' "cask"
        return 0
    fi
    # No brew: prefer mas when the module supports it, else vendor download.
    if [[ "$has_mas_id" == "1" ]] && cmd_exists mas; then
        printf '%s\n' "mas"
        return 0
    fi
    printf '%s\n' "vendor"
}

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

macos_modules::install_via_mas() {
    local mas_id="$1"

    if ! cmd_exists brew && ! cmd_exists mas; then
        error "Installing via Mac App Store requires 'mas' (or Homebrew to install it)."
        return 1
    fi

    if ! cmd_exists mas; then
        brew install mas || {
            error "Failed to install 'mas'."
            return 1
        }
    fi

    # Requires an active Mac App Store sign-in on this machine.
    mas install "$mas_id"
}

macos_modules::install_via_vendor() {
    local token="$1"
    local rename_from="${2:-}"
    local rename_to="${3:-}"

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

# macos_modules::install_cask_or_vendor <cask-token> [--mas-id <id>] [--rename-from <App.app>] [--rename-to <App.app>]
macos_modules::install_cask_or_vendor() {
    local token="$1"
    shift

    local mas_id="" rename_from="" rename_to=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --mas-id)
            mas_id="$2"
            shift 2
            ;;
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

    local has_mas_id=0 method
    [[ -n "$mas_id" ]] && has_mas_id=1
    method="$(macos_modules::resolve_install_method "$has_mas_id")"

    case "$method" in
    mas)
        if [[ -z "$mas_id" ]]; then
            error "SMU_INSTALL_METHOD=mas requires --mas-id for this module."
            return 1
        fi
        macos_modules::install_via_mas "$mas_id"
        ;;
    vendor)
        macos_modules::install_via_vendor "$token" "$rename_from" "$rename_to"
        ;;
    cask)
        if ! cmd_exists brew; then
            error "Homebrew is required for cask install."
            return 1
        fi
        brew_bundle_install -f "brewfile"
        ;;
    *)
        error "Unknown SMU_INSTALL_METHOD='${method}' (expected cask, vendor, or mas)."
        return 1
        ;;
    esac
}
