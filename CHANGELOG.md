# Changelog

## 0.1.2 — recovery loop and shell correctness

- Fix `pm` parsing for optional directory/port fields around `--`; add `--init`.
- Wire packaged fzf key bindings/completion on Termux and Debian.
- Preserve existing global Git preferences on reruns/config-only installs.
- Add AVF disk and `podman system df` output to `dev-doctor`.
- Retain only the newest 10 bootstrap backup directories by default.
- Stop aliasing `cat` to `bat`; keep `bat` explicit.
- Add `AddKeysToAgent` and `IdentitiesOnly` to the fresh SSH config template.
- Add `reseed` to clone missing repositories from `$DEV_SHARED/configs/repos.txt`.
- Add optional `age`-encrypted SSH recovery with `ssh-seal`, `ssh-restore`, and `--restore-ssh-key`.
- Clarify that `/mnt/shared` is reset-resilient device-local storage, not a device-loss durability layer; Git/remotes remain canonical.


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
- Added reset-resilient `/mnt/shared/dev` mapping, recovery guidance, backups, and diagnostics.
