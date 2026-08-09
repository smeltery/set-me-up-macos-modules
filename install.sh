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
        error "These modules are only for macOS!"
        return 1
    fi

    while IFS= read -r -d '' brewfile; do
        brew_bundle_install -f "$brewfile"
    done < <(find . -type f -name "brewfile" -print0)

}

main
