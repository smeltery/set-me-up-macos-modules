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

    if [[ -d "/Applications/Endurance.app" ]]; then
        sudo rm -rf "/Applications/Endurance.app"
    fi

}

main
