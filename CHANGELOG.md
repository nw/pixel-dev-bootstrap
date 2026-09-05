# Changelog

## 0.1.6 — named AVF OCI environments

- Remove the `--base` / `--with-boxes` install-profile split and the old
  `nodebox` / `pybox` / `debbox` convenience layer.
- Add AVF-only `box` as a thin data-driven vocabulary over Podman.
- Store reset-resilient box definitions under `$DEV_SHARED/configs/boxes.d`
  and seed registry aliases under `$DEV_SHARED/configs/registries.conf`.
- Add registry alias resolution plus `box login/logout/auth`, while keeping
  credentials entirely Podman-owned.
- Add `box list/info/pull/run/shell` with repeatable runtime `--env`, `--port`,
  and `--mount` flags plus localhost-first `--bind` behavior.
- Parse box definitions as inert `key=value` data rather than sourcing shell.
- Add an ESP-IDF-shaped example definition without prescribing an actual
  toolchain image or registry.
- Document the complete `box` API and the Git / OCI registry / shared-storage /
  disposable-AVF persistence split.
- Extend smoke coverage across image resolution, registry auth delegation,
  environment overrides, mounts, repeated ports, and configured shells.

## 0.1.5 — inert recipe discovery and safer recipe updates

- Make `recipe list` and metadata-only `recipe info` inspect literal recipe
  metadata without sourcing executable recipe code.
- Document the two single-line quoted metadata assignments as a hard recipe
  contract and keep catalog browsing side-effect free.
- Stage a complete recipe payload in private storage before installing package
  dependencies or touching the active payload and links.
- Treat an empty successful Android speech-to-text result in `vnote` as cancel/no
  speech, exiting cleanly instead of unexpectedly entering local Whisper mode.
- Extend smoke coverage for inert catalog browsing, failed staged-copy recovery,
  and native speech-dialog cancellation.

## 0.1.4 — optional Termux recipes and vnote

- Add a deliberately small Termux-only recipe layer for Android/CLI integrations.
- Keep base bootstrap recipe-free; refresh only a private recipe catalog and the `recipe` helper.
- Add `recipe list/info/install/check/remove` with idempotent package dependency checks.
- Define package ownership explicitly: recipes may install missing dependencies but never uninstall packages.
- Copy recipe payloads into Termux-private storage before wiring `~/bin` or `recipes.d/*.bash` private-to-private symlinks.
- Add a stable `recipes.d` shell include seam instead of allowing recipes to append into `~/.bashrc`.
- Move `termux-api` out of the base Termux package set; Android API integration is now opt-in.
- Add the `vnote` recipe: Android speech-to-text first, optional local `whisper-cli` fallback, Enter-or-time-ceiling recording, and Markdown output.
- Expand README guidance around copy semantics, recipe scope, shared dependencies, and AVF/Podman separation.

## 0.1.3 — base profile and optional runtime shortcuts

- Make the AVF shell runtime-neutral by default: `pm`, `pms`, and `pmlan` remain core.
- Move `nodebox`, `pybox`, and `debbox` into an optional `boxes.bash` convenience layer.
- Add explicit `--base` and `--with-boxes` install switches; base is the default.
- Returning to `--base` removes stale optional box helpers from prior installs.
- Clarify that image-specific shorthand is a replaceable convenience layer, not part of the bootstrap contract.
- Extend smoke coverage for opt-in/opt-out profile behavior.

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
