#!/usr/bin/env bash
set -e

CONFIG_DIR="$HOME/.config/nix"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Available hosts: phos, phos-wsl, darkness"
echo ""
read -p "Enter host: " HOST

if [ -z "$HOST" ]; then
    echo "No host specified"
    exit 1
fi

echo "Installing NixOS config for: $HOST"

# Move to config dir if not already there
if [ "$REPO_DIR" != "$CONFIG_DIR" ]; then
    echo "Moving to $CONFIG_DIR..."
    mkdir -p "$(dirname "$CONFIG_DIR")"
    cd /
    mv "$REPO_DIR" "$CONFIG_DIR"
    cd "$CONFIG_DIR"
else
    echo "Already in $CONFIG_DIR"
fi

# Apply configuration
echo "Applying configuration..."
sudo nixos-rebuild switch --flake ".#$HOST" --extra-experimental-features "nix-command flakes"

echo "Done!"
