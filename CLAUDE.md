# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Flakes-based NixOS configuration for multiple machines (Altair, Procyon, Arcturus, Polaris). Only `procyon` is currently active. Uses impermanence (ephemeral root), LUKS encryption, Secure Boot via lanzaboote, and sops-nix for secrets.

## Common Commands

```bash
# Format all Nix files
nix fmt

# Check the flake (runs alejandra, statix, deadnix, shellcheck, ruff, flake-checker)
nix flake check

# Build a host's system closure
nix build .#nixosConfigurations.procyon.config.system.build.toplevel

# Apply config on the current machine
sudo nixos-rebuild switch --flake .#procyon

# Enter dev shell (includes disko, sops, deploy tools, pre-commit)
nix develop
```

## Architecture

### Library (`lib/`)

- `generators.nix` — Core helpers: `mkHost` builds a NixOS system config; `mkHosts` iterates all hosts; `mkOverlay` composes package overlays; `mkSecrets` sets up sops secrets
- `importers.nix` — `rakeNixLeaves` recursively collects `.nix` files into attribute sets; used to auto-import entire directories as modules

### Modules (`modules/`)

Reusable NixOS modules. Notable:
- `boot/disk.nix` — disko partition layout with LUKS, TPM unlock, optional mirrored RAID, hibernation swap
- `persist.nix` — Impermanence setup; persistent state lives under `/nix/pst`
- `sops.nix` — Secrets wiring via sops-nix
- `user.nix` — User accounts + home-manager integration

### Profiles (`profiles/bundle/`)

Named bundles of related modules, each a directory auto-imported via `rakeNixLeaves`:
- `common` — baseline (SSH, networking, Tailscale, shell, Nix settings, colemak-dh layout)
- `dev` — dev tools, Git, VS Code, Rust/Python/Java/Nix support, Docker
- `graphical` — Hyprland, Bluetooth, browser, email, GUI networking
- `entertainment` — Discord, Steam, Spotify, Stremio
- `llm` — aichat, Claude CLI, llama.cpp, OCR (glmocr), Brave Search MCP, Context7 MCP
- `research` — Zotero (unstable)
- `server` — headless common + code-server

### Hosts (`hosts/`)

Each host file calls `mkHost` and selects profile bundles. `procyon.nix` is the only active host (TUXEDO laptop, AMD CPU, dual Samsung NVMe in RAID mirror, NVIDIA Ethernet `yt6801`, full bundle set).

### Custom Packages (`pkgs/`)

Local derivations overlaid onto nixpkgs. Includes `deploy-anywhere` (wraps nixos-anywhere), `prepare-secrets`, `brave-search-mcp-server`, `glmocr`, `sbctl`, `tpm-lockup`.

### Secrets (`secrets/`)

Encrypted with `sops` + age keys. Two age deployers (altair, procyon) configured in `.sops.yaml`. Per-host secret directories hold SSH keys, hashed passwords, and API keys. Edit secrets with `sops secrets/<host>/file.yaml`. When piping into sops from stdin, use `--filename-override` so sops matches the correct `.sops.yaml` creation rule instead of matching against `/dev/stdin`:

```bash
echo "secret" | sops -e --filename-override secrets/host/name /dev/stdin > secrets/host/name
```

## Conventions

- Nix files are formatted with `alejandra`; run `nix fmt` before committing
- Pre-commit hooks enforce `statix`, `deadnix`, `shellcheck`, `ruff` — `nix develop` installs them
- New modules go in `modules/`; new profile bundles go in `profiles/bundle/<name>/`; they are auto-imported by `rakeNixLeaves` — no manual import lists needed
- Persistent state paths must be declared in `modules/persist.nix` or per-host persist config
- Secrets must be referenced through the `sops` module; never hardcode credentials

## Deploying a New Host

1. `prepare-secrets <target>` on a deployer machine
2. `deploy-anywhere <target> nixos@nixos`

## Emergency Shell

Disable Secure Boot in BIOS → press `e` in systemd-boot → add `SYSTEMD_SULOGIN_FORCE=1`.
