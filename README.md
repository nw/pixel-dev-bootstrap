# Pixel Dev Bootstrap

One small, reproducible shell setup for both:

- **Termux** — instant Android-adjacent shell, SSH, quick scripts, and optional Termux:API integration.
- **Pixel AVF Debian** — the Linux Development Environment for rootless Podman, builds, containers, and heavier work.

The repository installs shared shell behavior while preserving the architectural difference between the two environments.

## Working model

```text
Android shared storage
└── dev/
    ├── pixel-dev-bootstrap/    # reset-resilient offline reconstruction copy
    ├── artifacts/
    ├── configs/
    ├── containers/
    └── exports/

Termux private home
└── ~/src                      # native Termux repos/work

AVF Debian private disk
└── /home/droid/src            # disposable VM-local repos/work
```

The same Android directory is normally visible as:

```text
Termux:    ~/storage/shared/dev
AVF:       /mnt/shared/dev
```

Treat shared storage as the **loading dock and reconstruction surface**. Keep Git working trees, build trees, `node_modules`, container stores, databases, and symlink-heavy state in each environment's normal private Linux filesystem.

> Persist intent, source, configuration, and artifacts—not machine state.

### Durability tiers

`/mnt/shared` is **reset resilience**, not disaster recovery. It survives an AVF
VM reset, but a lost, wiped, or dead phone takes it with the device. Treat:

1. **Git/remotes or another external backup** as the canonical source of truth.
2. **`/mnt/shared/dev`** as a device-local offline reconstruction cache and
   Android ↔ Linux interchange surface.
3. **`/home/droid`** and the Podman store as disposable machine state.

This distinction is intentional: AVF rebuilds should be cheap without pretending
shared phone storage is a complete backup strategy.

## Quick start

Place or unzip this folder somewhere both environments can reach. The clean reset-resilient device-local location is:

```text
Android internal storage/dev/pixel-dev-bootstrap
```

### Termux

```bash
termux-setup-storage
bash ~/storage/shared/dev/pixel-dev-bootstrap/install.sh
source ~/.bashrc
dev-doctor
```

If the archive is still in Downloads:

```bash
bash ~/storage/downloads/pixel-dev-bootstrap/install.sh
```

### AVF Debian

```bash
bash /mnt/shared/dev/pixel-dev-bootstrap/install.sh
source ~/.bashrc
dev-doctor
```

If the archive is still in Android Downloads, the path is commonly:

```bash
bash /mnt/shared/Download/pixel-dev-bootstrap/install.sh
```

The installer auto-detects the environment. Shared storage may not preserve executable bits, so invoking it with `bash` is intentional.

## Installer options

```text
--termux          force Termux
--avf             force AVF Debian
--no-upgrade      install missing packages without a full upgrade
--no-ssh-key      do not generate ~/.ssh/id_ed25519
--restore-ssh-key restore an age-encrypted SSH key from shared configs
--no-podman       AVF only: skip Podman and subordinate-ID setup
--base            base profile (default; no image-specific box helpers)
--with-boxes      AVF only: add nodebox/pybox/debbox shorthand
--configs-only    update dotfiles/helpers without package or system changes
```

Examples:

```bash
bash install.sh --configs-only
bash install.sh --avf --no-upgrade
bash install.sh --avf --with-boxes
```

Changed configuration files are backed up under:

```text
~/.local/state/pixel-dev-bootstrap/backups/<timestamp>/
```

The newest 10 backup runs are retained by default. Override with
`PIXEL_BOOTSTRAP_BACKUPS_KEEP=<n>` when needed.

## What gets installed

### Shared configuration

- Bash/XDG baseline, compact prompt, persistent history, completion
- `eza`, `bat`, `zoxide`, `fd`, `fzf`, `ripgrep` integration when available
- Debian command-name normalization: `fdfind -> ~/bin/fd`, `batcat -> ~/bin/bat`
- SSH-agent startup and conservative SSH defaults
- Git defaults without inventing a name or email
- tmux baseline
- small Neovim configuration
- `clipcopy`, `clippaste`, `dev-doctor`, and `reseed`

The installer copies modular source files into:

```text
~/.config/pixel-dev-bootstrap/shell/
```

`~/.bashrc` is only a loader. Edit the repository copies and rerun `install.sh --configs-only` to keep maintenance reproducible.

Copying rather than symlinking is deliberate. The bootstrap repository commonly
lives on Android shared storage, where Unix symlink/mode semantics are not a
reliable contract. Bootstrap-owned configuration is copied into private storage;
symlinks are used only when both ends live inside the normal private filesystem.

### Termux role

Termux receives the broader native CLI/toolchain set from the original setup: Git/OpenSSH, Node LTS, Python, clang/CMake/Ninja, Neovim, micro, tmux, modern shell tools, and a tuned extra-key row.

Use it for:

- SSH/tmux
- quick scripts and network inspection
- lightweight native Node/Python work
- Android-facing helpers
- longer low-overhead sessions where booting AVF is unnecessary

## Optional Termux recipes

Recipes are **Termux-only Android/CLI integrations**. They are not a second
workload system for AVF: general development environments belong in Podman/OCI
containers there.

Base bootstrap installs **no recipes**. The Termux setup only refreshes a small recipe catalog
into private storage and installs the `recipe` command:

```bash
recipe list
recipe info vnote
recipe install vnote
recipe check vnote
recipe remove vnote
```

The ownership boundary is intentionally narrow:

- a recipe may declare Termux package dependencies; `recipe install` installs
  only packages that are missing;
- packages are **dependencies, not recipe-owned state** and are never removed
  automatically; package cleanup is manual because dependencies may be shared
  by other recipes or by the user;
- recipe source from the bootstrap catalog is copied into
  `~/.local/share/pixel-dev-bootstrap/recipes/<name>/`;
- commands are then linked from that private copy into `~/bin`;
- optional shell integration is a separate
  `~/.config/pixel-dev-bootstrap/recipes.d/<name>.bash` include, never an inline
  append to `~/.bashrc`;
- recipe removal deletes only those recipe-owned private files and links.

This copy-first model is deliberate. The public/bootstrap copy may live under
Android shared storage; installed recipe payloads do not execute from or depend
on shared-storage symlink behavior.

Rerunning `install.sh --configs-only` refreshes the private **catalog only**. It
does not mutate an installed recipe. Run `recipe install <name>` again when you
explicitly want to update that recipe from the refreshed catalog.

### `vnote` recipe

`vnote` is the first example: a small voice-to-Markdown bridge that uses Android
speech-to-text through Termux:API and can optionally fall back to local
`whisper-cli` transcription.

```bash
recipe install vnote
vnote
```

The recipe ensures `termux-api` and `ffmpeg`. The matching **Termux:API Android
companion app must still be installed from the same signing source as Termux**.
The recipe deliberately does not install a Whisper engine or model.

```bash
vnote       # Android STT first; local fallback max 120 seconds
vnote 30    # local fallback max 30 seconds
vnote 0     # no fallback ceiling; Enter stops recording
```

Notes default to:

```text
${DEV_SHARED:-$HOME/scratch}/voice-scratchpad.md
```

Useful overrides:

```bash
export VNOTE_NOTES_FILE="$DEV_SHARED/voice-scratchpad.md"
export VNOTE_MAX_SECONDS=120
export VNOTE_MODEL="$HOME/models/ggml-tiny.en.bin"
export VNOTE_MODE=auto     # auto | native | local
```

See [`recipes/vnote/README.md`](recipes/vnote/README.md).

### AVF Debian role

The AVF host stays intentionally smaller. It gets normal shell/editor/network tools plus rootless Podman support, but **does not install Node or project-specific runtimes on the host**. The default shell layer is likewise runtime-neutral: `pm`, `pms`, and `pmlan` are the only container workflow abstractions enabled by default.

Use it for:

- containerized Node/Python/toolchains
- builds and services
- ESP-IDF or other persistent toolchain environments when needed
- disposable experiments
- Linux graphical applications through Display

See [`docs/AVF.md`](docs/AVF.md) for persistence and VM-resource guidance.

## Rootless Podman

The AVF installer installs Podman with `uidmap`, `slirp4netns`, `fuse-overlayfs`, `dbus-user-session`, `crun`, and Buildah. When no suitable subordinate-ID range exists, it adds:

```text
<user>:100000:65536
```

Equivalent to:

```bash
sudo usermod --add-subuids 100000-165535 "$USER"
sudo usermod --add-subgids 100000-165535 "$USER"
```

It does not overwrite an existing mapping. Run `dev-doctor` to inspect the result.

The installer explicitly pins the AVF rootless container substrate for reproducible rebuilds. This is deliberate harnessing for the tested Pixel AVF environment, not an attempt to migrate an established Podman store:

```toml
# ~/.config/containers/containers.conf
[engine]
runtime = "crun"

# ~/.config/containers/storage.conf
[storage]
driver = "overlay"

[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
```

This matches the disposable-VM model: `crun` is installed explicitly and rootless storage stays on VM-local overlay via `fuse-overlayfs`. If a VM already has an established Podman store using a different driver, do not expect changing `storage.conf` to migrate that store; inspect or reset it deliberately. Fresh AVF rebuilds are the intended path.

### Podman shortcuts

```bash
p                     # podman
pi                    # images
pps                   # running containers
ppa                   # all containers
pv                    # volumes
pn                    # networks
pclean                # interactive system prune
pdeepclean            # remove all unused containers/images/volumes/cache
```

`pm` is the small disposable-workload helper:

```bash
pm <image> [directory] [port] [-- command ...]
```

Examples:

```bash
# Mount the current directory at /work.
pm node:24-bookworm

# Local-only port mapping: 127.0.0.1:3000 -> container :3000.
pm node:24-bookworm . 3000

# Different host/container ports and an explicit command.
pm node:24-bookworm ~/src/app 8080:3000 -- npm test

# Explicitly expose to the LAN rather than localhost only.
PM_BIND_ADDRESS=0.0.0.0 pm node:24-bookworm . 3000
```

`pms` opens a shell instead of using the image's default command:

```bash
pms node:24-bookworm . 3000
```

The base profile stops there. It deliberately does not choose language/runtime
images for you.

If repeated use establishes a real pattern, opt into a tiny convenience layer:

```bash
bash install.sh --avf --configs-only --with-boxes
```

That adds:

```bash
nodebox . 3000                    # node:24-bookworm
pybox .                           # python:3.13-bookworm
debbox .                          # debian:bookworm
```

Those helpers live in a separate `boxes.bash` file and can be removed cleanly by
rerunning `bash install.sh --avf --configs-only --base`. They do not pull images
until invoked.

The Podman functions use `--userns=keep-id`, bind the selected directory at
`/work`, and default published ports to loopback.

If a runtime helper grows persistent homes, initialization hooks, exported GUI
apps, special mounts, or environment-specific state, that is the signal to
promote the pattern to Distrobox rather than continuing to grow shell shorthand.

## Clipboard

Two scripts provide one vocabulary across environments:

```bash
printf 'hello' | clipcopy
clippaste
```

Backends are selected at runtime:

- **Termux:** `termux-clipboard-set/get`; requires both the `termux-api` package and the matching Termux:API Android companion app. Base does not install `termux-api`; install it manually or through a recipe such as `vnote`.
- **AVF Display / Wayland:** `wl-copy` and `wl-paste` from `wl-clipboard`.
- **AVF Display / X11:** `xclip`.

The AVF text Terminal's own selection/copy UI is separate. Linux clipboard commands become useful when a graphical Display session exposes a Wayland or X11 clipboard; they are not presented as a guaranteed always-on Android-host clipboard bridge.

Neovim enables `unnamedplus` only when it detects a functioning platform-shaped backend rather than assuming a clipboard exists.

## SSH keys and resets

By default, each environment generates its own unencrypted Ed25519 key if one is missing:

```text
Termux key comment: termux@pixel
AVF key comment:    avf@pixel
```

Private keys are never copied into `/mnt/shared` by the installer.

That means an AVF reset destroys the AVF-local key by default—which is intentional under the disposable-VM model. Reauthorize the new key, use agent forwarding, or manage keys entirely yourself with `--no-ssh-key`.

For a cheap opt-in recovery path, `age` is installed when available. Seal the
current key into shared storage with a strong passphrase you retain separately:

```bash
ssh-seal
```

This writes only an encrypted blob to:

```text
$DEV_SHARED/configs/ssh/id_ed25519.age
```

After an AVF reset, reconstruct and restore in one pass:

```bash
bash /mnt/shared/dev/pixel-dev-bootstrap/install.sh --restore-ssh-key
```

The installer prompts through `age`, recreates the public key from the restored
private key, and never stores the passphrase. This protects the key at rest on
shared storage, but the passphrase must be strong; the encrypted blob is still
only device-local unless separately backed up.

## Recovery cadence

After an AVF reset, the intended recovery path is roughly:

```bash
bash /mnt/shared/dev/pixel-dev-bootstrap/install.sh
source ~/.bashrc
dev-doctor
```

Then restore missing working trees from the reset-resilient manifest:

```bash
reseed
```

`reseed` reads `$DEV_SHARED/configs/repos.txt`, clones missing repositories into
`~/src`, and preserves anything already present. The installer seeds that file
from `examples/repos.txt.example` only when it does not already exist. Keep any
important canonical copy of the manifest in a remote/private repository, because
shared storage does not survive device loss or wipe.

Pull workload images as needed. The VM should remain cheap to abuse, reset, and
reconstruct.

For Termux, optional Android integrations are deliberately reconstructed after
the base rather than baked into it:

```bash
recipe install vnote     # only when this capability is wanted
```

A user-owned extension may choose to install personal recipes automatically,
but upstream bootstrap does not.
