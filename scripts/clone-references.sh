#!/usr/bin/env sh
set -eu

REPOSITORIES="
denful-den https://github.com/denful/den.git
denful-den-wiki https://github.com/denful/den.wiki.git
denful-dendrix https://github.com/denful/dendrix.git
denful-flake-aspects https://github.com/denful/flake-aspects.git
denful-flake-file https://github.com/denful/flake-file.git
denful-import-tree https://github.com/denful/import-tree.git
hercules-ci-flake.parts-website https://github.com/hercules-ci/flake.parts-website.git
mic92-sops-nix https://github.com/Mic92/sops-nix.git
mightyiam-dendritic https://github.com/mightyiam/dendritic.git
nix-community-nixos-wsl https://github.com/nix-community/NixOS-WSL.git
nvmd-nixos-raspberrypi https://github.com/nvmd/nixos-raspberrypi.git
vic-vix https://github.com/vic/vix.git
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
		rm -rf "$target"
		git clone --quiet --depth 1 "$url" "$target"
	fi
done
