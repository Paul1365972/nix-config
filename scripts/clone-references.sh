#!/usr/bin/env sh
set -eu

REPOSITORIES="
denful-den https://github.com/denful/den.git
denful-den-wiki https://github.com/denful/den.wiki.git
denful-flake-file https://github.com/denful/flake-file.git
denful-import-tree https://github.com/denful/import-tree.git
nix-community-home-manager https://github.com/nix-community/home-manager.git
nix-community-disko https://github.com/nix-community/disko.git
nix-community-nixos-wsl https://github.com/nix-community/NixOS-WSL.git
nvmd-nixos-raspberrypi https://github.com/nvmd/nixos-raspberrypi.git
nlewo-comin https://github.com/nlewo/comin.git
mic92-sops-nix https://github.com/Mic92/sops-nix.git
numtide-treefmt-nix https://github.com/numtide/treefmt-nix.git
"

repos_dir=$(cd "$(dirname "$0")/.." && pwd)/references/repos
mkdir -p "$repos_dir"

echo "$REPOSITORIES" | while read -r name url; do
	[ -n "$name" ] || continue
	target="$repos_dir/$name"

	if [ -d "$target/.git" ]; then
		echo "updating $name"
		git -C "$target" pull --quiet --ff-only
	else
		echo "cloning  $name"
		git clone --quiet --depth 1 "$url" "$target"
	fi
done
