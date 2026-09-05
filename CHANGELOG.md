# Changelog

## 0.1.1 — 2026-09-01

- Pin AVF rootless Podman to `crun`.
- Pin container storage to `overlay` via `/usr/bin/fuse-overlayfs`.
- Normalize Debian `fdfind` and `batcat` into `~/bin/fd` and `~/bin/bat`.
- Add destructive `pdeepclean` helper for disposable VM cleanup.
- Extend diagnostics and smoke tests for the explicit Podman substrate.

## 0.1.0 — 2026-09-01

- Unified auto-detecting installer for Termux and Pixel AVF Debian.
- Split inline shell, Neovim, tmux, SSH, and Termux configuration into maintained files.
- Preserved the Termux package/tooling baseline and Fold-oriented extra keys.
- Added minimal AVF host setup and rootless Podman subordinate-ID configuration.
- Added localhost-first `pm`, `pms`, `nodebox`, `pybox`, and `debbox` helpers.
- Added Termux/Wayland/X11 clipboard dispatch helpers.
- Added durable `/mnt/shared/dev` mapping, recovery guidance, backups, and diagnostics.
