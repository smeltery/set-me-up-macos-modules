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

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    ask_for_sudo

    # Vendor "download" URL redirects to a versioned .zip. Resolve the
    # final URL so install_from_URL can detect the extension from the
    # basename (passing the short URL would leave EXTENSION=download).
    local url
    url="$(curl -fsSIL -o /dev/null -w '%{url_effective}' \
        'https://enduranceapp.com/download')"

    if [[ -z "$url" || "$url" != *.* ]]; then
        error "Could not resolve Endurance download URL."
        return 1
    fi

    install_from_URL "$url"

}

main
