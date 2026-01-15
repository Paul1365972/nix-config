#!/bin/sh
set -e

echo "Copying folder to /etc/nixos"
cp -rf . /etc/nixos

HOSTNAME=$(hostname)
echo "Setup NixOS configuration for hostname: $HOSTNAME"

sudo nixos-rebuild switch --flake /etc/nixos#$HOSTNAME
echo "NixOS configuration setup complete!"
echo "From now on use: nixos-rebuild switch"
