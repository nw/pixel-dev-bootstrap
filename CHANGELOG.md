# Changelog

## 0.1.13 — fresh AVF shared-storage readiness

- Fix the one-line bootstrap on a freshly created AVF VM when `/mnt/shared` is visible before the Android-backed mount is fully ready for writes.
- Replace the one-shot `[[ -w /mnt/shared ]]` check with an operational probe that creates `/mnt/shared/dev`, writes a private test file, removes it, and retries for up to 30 seconds.
- Keep `/mnt/shared/dev` as the canonical AVF ↔ Android interchange path; no Downloads fallback or Termux prerequisite is introduced.
- Add smoke coverage for the mount-readiness race so the bootstrap must recover when the shared path initially rejects `dev/` creation and becomes usable shortly afterward.
- Document the fresh-VM readiness behavior in the AVF notes and Quick Start.

## 0.1.12 — private bootstrap checkout on Termux and AVF

- Fix the public one-line bootstrap after a clean Termux install by moving the Git checkout off Android shared storage.
- Keep one disposable upstream checkout per environment at `~/.local/share/pixel-dev-bootstrap/source`; Termux and AVF no longer share Git metadata.
- Continue creating `$DEV_SHARED` as the explicit Android ↔ Linux reconstruction/interchange surface, but never use it as the bootstrap Git working tree.
- Remove the shared-storage `core.fileMode` workaround; the checkout now has normal private Unix filesystem semantics.
- Update smoke coverage to require a private checkout and verify that the shared `dev/` root remains checkout-free.
- Correct README, Quick Start, AVF notes, recovery examples, and the personal-versioning guidance so Git metadata is kept off shared storage.

## 0.1.11 — quick start and command reference

- Documentation-only release; runtime, installer, recipe, Podman, `box`, and AVF overlay behavior are unchanged.
- Add `docs/quickstart.md` as the compact operational reference: architecture boundary, folder map, reset cadence, and the command surface introduced by the project.
- Document the optional pattern of keeping `/mnt/shared/dev` as a tiny user-owned Git control plane while leaving the public bootstrap checkout and transient artifacts untracked.
- Add a top-level README start shim with the one-line install, immediate health check, and direct Quick Start link.
- Rename the deeper README install sections to distinguish public one-line setup from manual/local installation.

## 0.1.10 — durable AVF home overlay

- Add AVF-only `avf-sync` for copying a user-owned, reset-resilient home overlay from `$DEV_SHARED/configs/avf/home/` into the disposable VM home.
- Keep the overlay intentionally dumb: no package lifecycle, hooks, profiles, deletion semantics, or secret ownership; `--dry-run` is the only control surface.
- Never delete unrelated AVF home files and exclude common credential locations such as `.ssh`, `.gnupg`, registry auth, and Codex auth from the shared-storage overlay.
- Normalize copied overlay files to normal private-filesystem permissions and make files deliberately placed under `home/bin/` executable after sync.
- Seed the durable AVF overlay directory during AVF setup.
- Add a small Pixel AVF `AGENTS.md` example showing host boundaries for Codex/agent workflows without automatically imposing it on users.
- Document the customization boundary: public bootstrap substrate, user-owned AVF overlay, Termux recipes for Android integration, OCI/`box` for AVF workloads, and remotes/registries for canonical durability.
- Extend smoke coverage for AVF-only installation, dry-run behavior, overlay copying, executable helpers, secret exclusions, and non-destructive home semantics.

## 0.1.9 — launcher capture, AVF note promotion, and public repo hygiene

- Add a recipe-owned foreground `~/.shortcuts/vnote` launcher/widget entry so voice capture can start directly from Android.
- Keep shortcut execution inside Termux's approved shortcut tree by copying a regular executable file rather than linking outside it.
- Extend recipe ownership checks/removal to shortcut copies while preserving user-modified shortcut files.
- Add AVF `vnote-import [destination]` to explicitly promote the shared voice scratchpad into a project working tree without overwriting existing files.
- Add a basic public-repository `.gitignore` and the MIT `LICENSE`.
- Add `ACKNOWLEDGMENTS.md` and README disclosure of substantial OpenAI ChatGPT-assisted implementation, testing, documentation, and design review.
- Document Google Play Termux's integrated Widget/API surface versus companion-plugin requirements on other Termux distributions.

## 0.1.8 — public documentation and support boundary

- Documentation-only release; no runtime, installer, recipe, Podman, or `box` behavior changed.
- Add a public-facing goals/architecture overview centered on extending the development tether rather than replacing a workstation.
- Document Termux as the broad Android baseline and Pixel Linux Development Environment / AVF as the primary tested enhanced path.
- Clarify that AVF is not Pixel-only while keeping other OEM implementations explicitly untested.
- Make PRoot, rooted/custom-kernel workflows, wake hacks, pet-VM operation, and workstation replacement explicit non-goals.
- Add the escalation contract: SSH, workstation, and cloud compute are intentional next layers when phone resource/lifecycle limits are reached.
- Add the "PC disclaimer": a healthy AVF VM should remain cheaper to reconstruct than to repair.
- Refine the one-line install wording for the public `github.com/nw/pixel-dev-bootstrap` repository.
- Add matching support/scope language to `docs/AVF.md`.

## 0.1.7

- Added `bootstrap.sh` as a thin public one-line installer for Termux and Pixel AVF Debian.
- The remote bootstrap creates the shared `dev/` root and canonical `pixel-dev-bootstrap` checkout before delegating to `install.sh`.
- A clean existing checkout is updated only with `git pull --ff-only`; local modifications are preserved and suppress automatic updates.
- The same checkout is shared as `~/storage/shared/dev/pixel-dev-bootstrap` from Termux and `/mnt/shared/dev/pixel-dev-bootstrap` from AVF.
- Added README documentation for the one-liner, installer-argument forwarding, fork/remote override, and inspect-before-run path.

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
