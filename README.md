# Pixel Dev Bootstrap

One small, reproducible shell setup for both:

- **Termux** — instant Android-adjacent shell, SSH, quick scripts, and optional Termux:API integration.
- **Pixel AVF Debian** — the Linux Development Environment for rootless Podman, builds, containers, and heavier work.

The repository installs shared shell behavior while preserving the architectural difference between the two environments.

## Working model

```text
Android shared storage
└── dev/
    ├── pixel-dev-bootstrap/    # this durable reconstruction repo
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

## Quick start

Place or unzip this folder somewhere both environments can reach. The clean durable location is:

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
--no-podman       AVF only: skip Podman and subordinate-ID setup
--configs-only    update dotfiles/helpers without package or system changes
```

Examples:

```bash
bash install.sh --configs-only
bash install.sh --avf --no-upgrade
```

Changed configuration files are backed up under:

```text
~/.local/state/pixel-dev-bootstrap/backups/<timestamp>/
```

## What gets installed

### Shared configuration

- Bash/XDG baseline, compact prompt, persistent history, completion
- `eza`, `bat`, `zoxide`, `fd`, `fzf`, `ripgrep` integration when available
- Debian command-name normalization: `fdfind -> ~/bin/fd`, `batcat -> ~/bin/bat`
- SSH-agent startup and conservative SSH defaults
- Git defaults without inventing a name or email
- tmux baseline
- small Neovim configuration
- `clipcopy`, `clippaste`, and `dev-doctor`

The installer copies modular source files into:

```text
~/.config/pixel-dev-bootstrap/shell/
```

`~/.bashrc` is only a loader. Edit the repository copies and rerun `install.sh --configs-only` to keep maintenance reproducible.

### Termux role

Termux receives the broader native CLI/toolchain set from the original setup: Git/OpenSSH, Node LTS, Python, clang/CMake/Ninja, Neovim, micro, tmux, modern shell tools, and a tuned extra-key row.

Use it for:

- SSH/tmux
- quick scripts and network inspection
- lightweight native Node/Python work
- Android-facing helpers
- longer low-overhead sessions where booting AVF is unnecessary

### AVF Debian role

The AVF host stays intentionally smaller. It gets normal shell/editor/network tools plus rootless Podman support, but **does not install Node or project-specific runtimes on the host**.

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

The installer explicitly pins the AVF rootless container substrate for reproducible rebuilds:

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

Common images have shorter helpers:

```bash
nodebox . 3000                    # node:24-bookworm
pybox .                           # python:3.13-bookworm
debbox .                          # debian:bookworm
```

The functions use `--userns=keep-id`, bind the selected directory at `/work`, and default published ports to loopback.

If these helpers accumulate persistent homes, initialization hooks, exported GUI apps, special mounts, and environment-specific state, that is the signal to promote the pattern to Distrobox rather than continuing to grow `pm`.

## Clipboard

Two scripts provide one vocabulary across environments:

```bash
printf 'hello' | clipcopy
clippaste
```

Backends are selected at runtime:

- **Termux:** `termux-clipboard-set/get`; requires both the `termux-api` package and the matching Termux:API Android companion app.
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

That means an AVF reset destroys the AVF-local key—which is intentional under the disposable-VM model. Reauthorize the new key, use agent forwarding, or establish a separate secure restoration strategy when that inconvenience becomes real. Use `--no-ssh-key` to manage keys entirely yourself.

## Recovery cadence

After an AVF reset, the intended recovery path is roughly:

```bash
bash /mnt/shared/dev/pixel-dev-bootstrap/install.sh
source ~/.bashrc
dev-doctor
```

Then clone repos into `~/src` and pull workload images as needed. The VM should remain cheap to abuse, reset, and reconstruct.
