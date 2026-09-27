#!/bin/bash

# shellcheck source=/dev/null

declare current_dir &&
    current_dir="$(dirname "${BASH_SOURCE[0]}")" &&
    cd "${current_dir}" &&
    source "$HOME/set-me-up/dotfiles/utilities/import.sh"

smu::import base
smu::import system
smu::import homebrew

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    if ! is_macos; then
        error "This script is only for macOS!"
        return 1
    fi

    local repo_root
    repo_root="$(cd "${current_dir}/../.." && pwd)"
    # shellcheck source=/dev/null
    source "$repo_root/scripts/lib/install-app.sh"

    macos_modules::install_cask_or_vendor "maestri"

}

main
