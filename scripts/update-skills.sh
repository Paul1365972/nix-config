#!/usr/bin/env bash
# Diffs every vendored skill body against its metadata.source URL.
set -eu

skills_dir=$(cd "$(dirname "$0")/.." && pwd)/modules/users/paul/skills
body() { awk 'f>=2 { print } /^---$/ { f++ }' "$1"; }

for skill in "$skills_dir"/*/SKILL.md; do
	source=$(sed -n 's/^  source: //p' "$skill")
	[ -n "$source" ] || continue
	name=$(basename "$(dirname "$skill")")
	upstream=$(mktemp)
	curl -fsSL "$source" -o "$upstream"
	if body "$upstream" | diff -u - <(body "$skill") >/dev/null; then
		echo "unchanged $name"
	else
		echo "changed   $name"
		body "$upstream" | diff -u - <(body "$skill") || true
	fi
	rm -f "$upstream"
done
