# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Working Instructions

When exploring or modifying this codebase:
- **Read documentation directly** - Search and read at least 30 .md files in `docs/repos/`. Do not use subagents for this.
- **Read modules directly** - Read all top-level files in `modules/` and any other nix files as needed. Do not use subagents for this.
- **Reference previous attempts** - `docs/attempt1/` and `docs/attempt2/` contain earlier configurations for reference, but keep new work more minimal.
- **Keep it simple** - Follow the clean Dendritic pattern. Aspects should be nicely encapsulated in folders and files.

## Project Overview

NixOS configuration using the [den](https://github.com/vic/den) aspect-oriented Dendritic pattern with flakes, flake-parts, and home-manager.

## Target Hosts

| Host | System | Description | Reference |
|------|--------|-------------|-----------|
| `darkness` | aarch64-linux | Raspberry Pi with labwc/waybar/chromium kiosk | `docs/imperative/darkness/` |
| `phos-wsl` | x86_64-linux | Simple WSL instance | - |
| `phos` | x86_64-linux | NixOS laptop (dual boot) with Hyprland | - |

All hosts use the `paul` user with bash shell.

## Architecture

### Key Pattern: Dendritic/Aspect-Oriented

Configuration is organized into **aspects** - reusable modules that encapsulate cross-cutting concerns. Aspects compose together via `includes` lists.

## Important Conventions

1. **Never edit flake.nix directly** - Edit files in `modules/` then run `nix run .#write-flake`
2. **Angle bracket imports** - `<den/...>` syntax enabled via `__findFile` in `angle-brackets.nix`
3. **Input placement** - Declare inputs close to where they're used in `modules/`
4. **import-tree** - All `.nix` files in `modules/` are automatically imported
5. **Folder organization** - Subfolders (e.g., `desktop/`, `tools/`) are purely organizational; aspects are still `den.aspects.<name>`
6. **No namespaces needed** - For local aspects, just use `den.aspects.<name>` directly

## Den Batteries Used

- `<den/home-manager>` - Integrates home-manager into hosts
- `<den/define-user>` - Creates user at OS and HM levels
- `<den/primary-user>` - Makes user admin (wheel, networkmanager)
- `<den/user-shell>` - Sets default shell

## Documentation

- `docs/repos/` - Git submodules with reference documentation
- `docs/dendritic-template/` - Vic's den template for reference
- `docs/imperative/darkness/` - Original imperative Pi setup
