# NixOS Configuration

My NixOS configurations using the [den](https://github.com/vic/den) aspect-oriented pattern.

## Hosts

- **phos** - NixOS laptop with Hyprland
- **phos-wsl** - NixOS on WSL2
- **darkness** - Raspberry Pi 5 kiosk

## Quick Start

```bash
# Clone and install
nix-shell -p git
git clone https://github.com/Paul1365972/nix-config.git
cd nix-config && ./install.sh
```

## WSL Initial Setup

```bash
# Build tarball (on existing NixOS or Linux with Nix)
nix build .#nixosConfigurations.wsl.config.system.build.tarballBuilder
sudo ./result/bin/nixos-wsl-tarball-builder
```

```powershell
# Import on Windows
wsl --import NixOS $env:USERPROFILE\NixOS nixos.wsl --version 2
wsl -d NixOS
```

## Raspberry Pi SD Image

```bash
# Build the SD image
nix build .#darkness-sd-image

# Flash to SD card (replace sdX)
sudo dd if=./result/sd-image/*.img of=/dev/sdX bs=4M status=progress
```

## Development

```bash
nix run .#write-flake  # Regenerate flake.nix after changing inputs
nix flake update       # Update dependencies in flake.lock
nix flake check        # Verify configuration
nix run .#vm           # Test laptop in VM
```

## Docs

- `docs/repos/` - Reference documentation
- `docs/dendritic-template/` - Vic's template
- `docs/attempt1/` - Previous config attempt
- `docs/attempt2/` - Earlier experiment
- `docs/imperative/` - Non-declarative configs
