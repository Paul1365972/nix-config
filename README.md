# nix-config

My NixOS and Home Manager configuration, built with [den](https://github.com/denful/den) and [flake-parts](https://github.com/hercules-ci/flake-parts).

## Hosts

| Host | Setup |
|------|-------|
| [phos](modules/hosts/phos/) | Laptop with Hyprland |
| [phos-wsl](modules/hosts/phos-wsl/) | NixOS on WSL, development and builds |
| [darkness](modules/hosts/darkness/) | Raspberry Pi 5 kiosk with labwc |
| [saber](modules/hosts/saber/) | Home server for media, chat, home automation, and the [model gateway](crates/llm-gateway/) |

## Configuration

The config follows the dendritic pattern, grouping related NixOS and Home Manager settings into den aspects.
Hosts and [users](modules/users/) select the [shared features](modules/features/) they need.
[import-tree](https://github.com/vic/import-tree) loads every Nix file under `modules/`.
Modules declare their flake inputs alongside their configuration, and [flake-file](https://github.com/denful/flake-file) generates `flake.nix`.

## Links

- [Agent skills](modules/users/paul/skills/) and [global agent context](modules/users/paul/AGENTS.md) for Claude Code, Codex, and Antigravity
- [Windows agent links](scripts/link-agents.ps1) link the repository skills and context into Claude Code, Codex, and Antigravity, and the context into OpenCode.
- [References](docs/References.md) for option searches, manuals, and related tools
