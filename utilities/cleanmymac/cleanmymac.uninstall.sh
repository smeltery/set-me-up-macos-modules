#!/bin/bash

# shellcheck source=/dev/null

declare current_dir &&
    current_dir="$(dirname "${BASH_SOURCE[0]}")" &&
    cd "${current_dir}" &&
    source "$HOME/set-me-up/dotfiles/utilities/import.sh"

smu::import base
smu::import system

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    if ! is_macos; then
        error "This script is only for macOS!"
        return 1
    fi

    ask_for_sudo

    for app_path in "/Applications/CleanMyMac.app" "/Applications/CleanMyMac_5.app"; do
        if [[ -d "$app_path" ]]; then
            sudo rm -rf "$app_path"
        fi
    done

}

main
