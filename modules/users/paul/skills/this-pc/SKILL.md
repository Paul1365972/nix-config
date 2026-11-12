---
name: this-pc
description: What this PC can reach: remote machines, accounts, uncommon tools. Use when a task needs something outside the current folder.
---

## Local

- Projects live under `D:\Programming`; `GeoMesh` there is company work, the rest is private.
- WSL runs NixOS, for Nix and anything that needs Linux.
- An outbound firewall can block a new program until I allow it.

## Compute elsewhere

- `tailscale`: my own server and NAS.
- `boat`: many disposable sandboxes in parallel, for work that is too heavy or too parallel for this PC.
- `hcloud`: one dedicated server, for stable measurements and long-running jobs.
- `aws`: a company and a private profile, for what only AWS offers.

Delete what you rent when the work is done.

## Accounts

- `gh`: GitHub (Paul1365972).
- `pass-cli`: Proton Pass, where the logins live.
- `bun x cf`: Cloudflare; the default profile is private, `--profile geomesh` is the company.
- `bun x convex`: the backend of the company projects.
- Mail: the `fastmail` MCP is private, the `protonmail` MCP is the company and needs the Proton Mail Bridge running.

## Tools

- Documents and media: `tectonic` for LaTeX, `pdftotext` and `pdftoppm`, `magick`, `ffmpeg`, `yt-dlp`, `blender` for headless renders.
- Files: `jq`, `zstd`, `7z`, `xz`.
- Rust: `kache` caches compiles across worktrees; `cargo-binstall`, `wasm-bindgen`, `wasm-opt` and the `tracy` profiler are installed.
- System: the Sysinternals suite, `usbipd` to pass USB devices into WSL, Windows Sandbox, Wireshark, Fiddler, RenderDoc.
- Missing: a `python` command (use `uv`), Docker, `make`, `ninja`, `sqlite3` (use `bun:sqlite`) and `pandoc`.
