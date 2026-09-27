# 'set-me-up' macOS Modules

[![License: PolyForm Shield 1.0.0](https://img.shields.io/badge/License-PolyForm%20Shield%201.0.0-blue.svg)](https://polyformproject.org/licenses/shield/1.0.0)

This repository contains granular macOS/Homebrew modules for the [`set-me-up`](https://github.com/smeltery/set-me-up) project.

## Structure

Each module is organized by category with per-package subdirectories:

```
macos/
├── ai/
│   ├── chatgpt/
│   └── maestri/
├── app-store/
│   ├── carousel-weather/
│   ├── notability/
│   └── pure-paste/
├── browsers/
│   └── brave-browser/
├── cloud-sync/
│   └── insync/
├── design/
│   ├── colorsnapper/
│   ├── drawio/
│   └── figma/
├── development-tools/
│   ├── code/
│   ├── cursor/
│   ├── insomnia/
│   ├── jetbrains-toolbox/
│   ├── macports/
│   ├── rancher-desktop/
│   ├── worktrunk/
│   ├── xcode/
│   └── zed/
├── fonts/
│   ├── fira-code/
│   └── jetbrains-mono/
├── media/
│   ├── iina/
│   └── spotify/
├── productivity/
│   ├── betterdisplay/
│   ├── cleanshot/
│   ├── contexts/
│   ├── displaybuddy/
│   ├── dockdoor/
│   ├── hyperkey/
│   ├── raycast/
│   ├── rectangle-pro/
│   ├── textsniper/
│   ├── topnotch/
│   └── wisprflow/
├── security/
│   ├── 1password/
│   └── nordvpn/
├── terminal/
│   ├── alacritty/
│   ├── iterm2/
│   └── warp/
└── utilities/
    ├── airbuddy/
    ├── aldente/
    ├── appcleaner/
    ├── archiver/
    ├── cleanmymac/
    ├── cleanmymac-cli/
    ├── endurance/
    ├── imazing/
    ├── muzzle/
    ├── one-switch/
    ├── openlogi/
    ├── renamer/
    ├── rocket/
    └── syntax-highlight/
```

## Module kinds

Each module directory contains one of:

- **`brewfile`** — most common. A standard Homebrew Bundle file consumed by `brew bundle install`.
- **`<name>.sh`** — used when an install can't be expressed as a brewfile (App Store launches, vendor installers, post-install configuration). See `development-tools/xcode/`, `development-tools/macports/`, and `installers/`.

When both a `<name>.sh` and a `brewfile` are present, `smu` runs the script (it takes precedence). Several former-Setapp modules use that shape to support multiple install paths:

1. **Homebrew cask** (default) — `brew_bundle_install` against the sibling `brewfile` when `brew` is available.
2. **Vendor dmg/zip/pkg** — download the current cask artifact from [formulae.brew.sh](https://formulae.brew.sh) and install it with `install_from_URL`.
3. **Mac App Store** (`mas`) — when the module declares `--mas-id` (currently `productivity/textsniper`). Requires App Store sign-in.

Select a path with `SMU_INSTALL_METHOD`:

```bash
smu -m productivity/cleanshot                              # cask (default)
SMU_INSTALL_METHOD=vendor smu -m productivity/cleanshot    # vendor dmg/zip
SMU_INSTALL_METHOD=mas smu -m productivity/textsniper      # App Store via mas
```

`SMU_VENDOR_INSTALL=1` and `SMU_MAS_INSTALL=1` remain aliases for `vendor` and `mas`.

Shared helper: `scripts/lib/install-app.sh`. Endurance has no cask and always uses the vendor zip. Pure App Store modules still live under `app-store/` as `mas` brewfiles.

The `smu` installer resolves a module by name and runs whichever artifact it finds. See the [installer README](https://github.com/smeltery/set-me-up-installer#discovering-modules) for the full module-resolution rules and the `-p` / `-i` / `-l` flags.

## OS guarding

These modules are macOS-only. Defense-in-depth is layered so that running them on Linuxbrew or any other host fails closed:

1. **Top-level `install.sh`** — checks `is_macos` once and then iterates every `brewfile` under this tree via `brew_bundle_install`. Use this as the single entry point when bulk-installing the whole module set.
2. **Per-brewfile guard** — every `brewfile` starts with `abort "macOS only" unless OS.mac?`. Even a direct `brew bundle --file=…` invocation refuses to run on the wrong host.
3. **Per-script guard** — each `*.sh` module calls `is_macos` at the top of `main()` and bails with an error message otherwise.

## Auditing and uninstalling

The `smu` installer ships read-only auditing (`smu --status`) and reversal (`smu --uninstall`) for every module:

```bash
smu --status                                # what's currently installed
smu -u -m media/spotify productivity/raycast    # uninstall (prompts [y/N])
smu -iu                                          # interactive uninstall via fzf
```

For brewfile modules detection and uninstall are automatic — `brew bundle check` answers "is it installed?" and `brew bundle cleanup --file <brewfile> --force` reverses the install. No per-module work is required.

For `*.sh` modules `smu` only acts when the module ships two opt-in sibling files:

- **`<name>.installed`** — sourced by `smu --status`. Exit 0 means installed; non-zero means missing. Without this file, the module reports `unknown` (smu never guesses).
- **`<name>.uninstall.sh`** — sourced by `smu --uninstall`. Without this file, the module is reported as "cannot auto-uninstall — manual cleanup required" and skipped.

If a `*.sh` module shares its directory with a `brewfile`, `smu --uninstall` runs both inverses in order: the per-module `<name>.uninstall.sh` first (to clean up what the install script did beyond the brewfile), then `brew bundle cleanup --force` (to drop the brewfile-declared dependencies).

See the [installer README](https://github.com/smeltery/set-me-up-installer#auditing-whats-installed) for the full status/uninstall reference, including detection rules, sample output, and authoring examples.

## Usage

These modules are designed to be used as submodules within the [`set-me-up` blueprint](https://github.com/smeltery/set-me-up-blueprint) repository.

## License

This project is licensed under the [PolyForm Shield License 1.0.0](https://polyformproject.org/licenses/shield/1.0.0) — see [LICENSE](LICENSE) for details.