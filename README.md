# Pixel Dev Bootstrap

A small, reproducible bootstrap for extending the useful development tether of an Android phone without pretending the phone should replace a workstation.

It supports two complementary surfaces:

- **Termux** — the broad Android baseline: instant shell, SSH, quick scripts, lightweight native tooling, and optional Android integrations.
- **Pixel AVF Debian** — the enhanced path: Google's Linux Development Environment for rootless Podman, builds, containers, and heavier Linux work.

The project is intentionally narrow. It removes setup and reconstruction friction, preserves the boundary between the two environments, and gives you an explicit escalation path when the phone is no longer the right machine.

## Start here

Install from Termux or the Pixel Linux Development Environment:

```bash
curl -fsSL https://raw.githubusercontent.com/nw/pixel-dev-bootstrap/main/bootstrap.sh | bash
```

Then:

```bash
source ~/.bashrc
dev-doctor
```

For the folder map, environment boundary, recovery cadence, and a compact
reference for every command this project introduces, see
**[docs/quickstart.md](docs/quickstart.md)**.


## Goals and architecture

The core operating rule is:

> **Persist intent, source, configuration, and artifacts—not machine state.**

The bootstrap optimizes for a few concrete outcomes:

- get to a useful shell quickly;
- keep AVF cheap to destroy and reconstruct;
- keep Android-specific integrations explicit and optional;
- keep heavier AVF workloads in OCI images rather than growing the host;
- keep user-owned AVF host customization durable without folding it into the public bootstrap;
- preserve a simple Android-visible reconstruction surface under `/mnt/shared`; and
- treat SSH, a desktop/laptop, or cloud compute as normal escalation rather than failure.

The architecture is deliberately small:

```text
Android
├── Termux
│   ├── native shell / SSH / lightweight tooling
│   └── recipe     optional Termux ↔ Android integrations
│
├── Linux Development Environment (AVF)
│   ├── minimal Debian host
│   ├── avf-sync   user-owned durable home overlay -> disposable VM home
│   ├── Podman     arbitrary/disposable OCI workloads
│   └── box        named OCI environments + runtime defaults
│
└── shared storage
    └── dev/
        ├── configs/avf/home/   reset-resilient AVF host overlay
        └── ...                 definitions, configs, artifacts, bootstrap

SSH / workstation / cloud
└── escalation when the phone's resource or lifecycle boundary is reached
```

There is no requirement to use every layer. Termux alone is useful on devices without the tested AVF path. AVF adds capability; it does not replace Termux.

### Support boundary

| Surface | Project stance | Notes |
| --- | --- | --- |
| **Termux on Android** | Supported baseline | The broadest path. Plugin/source-signature rules remain Termux's concern; recipes document any companion-app requirements. |
| **Pixel Linux Development Environment / AVF** | Primary tested enhanced path | Developed and tested on Pixel with Developer options and Linux Development Environment enabled. Google currently exposes this as an experimental developer capability. |
| **Equivalent AVF/Terminal environments on other Android devices** | May work; untested | AVF is an Android platform capability, not Pixel-only, but OEM exposure and behavior vary. This project does not claim compatibility it has not tested. |
| **PRoot-based distros** | Out of scope | Valid user choice, but intentionally not another substrate owned by this project. |
| **Rooted phones / custom kernels / wake hacks** | Out of scope | The bootstrap works with the platform rather than defeating Android's security or battery model. |

### Non-goals

This is **not** an Android development framework, a mobile distro, a package manager, a registry manager, or a project for turning AVF into a long-lived pet server. It does not try to hide the phone's RAM, battery, lifecycle, or permission constraints.

Recipes exist only for optional Termux ↔ Android capabilities. Podman/OCI remains the AVF workload abstraction. `box` is only a thin naming/runtime-default layer over Podman. PRoot remains somebody else's problem.

### The PC disclaimer 😄

If a workload needs long uptime, large memory, persistent services, privileged kernel access, or the AVF VM becomes something you are afraid to reset, **SSH to a devbox or use a laptop/desktop**. The point is to extend the tether, not abolish it.

A healthy AVF environment should remain cheaper to reconstruct than to repair.

## Installation details

From either Termux or the Pixel Linux Development Environment:

```bash
curl -fsSL https://raw.githubusercontent.com/nw/pixel-dev-bootstrap/main/bootstrap.sh | bash
```

The remote entrypoint is intentionally thin. It:

1. detects Termux or Pixel AVF Debian;
2. enables/checks Android shared storage;
3. creates the shared `dev/` root;
4. installs Git only when it is missing;
5. clones the repository into the canonical device-local path; and
6. hands control to the repository's normal `install.sh`.

The resulting checkout is the **same physical Android shared-storage directory** from both environments:

```text
Termux: ~/storage/shared/dev/pixel-dev-bootstrap
AVF:    /mnt/shared/dev/pixel-dev-bootstrap
```

Rerunning the one-liner fast-forwards a clean existing checkout. If the checkout has local changes, bootstrap preserves them and skips the automatic update rather than overwriting work.

Pass normal installer options through the one-liner with `bash -s --`:

```bash
curl -fsSL https://raw.githubusercontent.com/nw/pixel-dev-bootstrap/main/bootstrap.sh | \
  bash -s -- --no-upgrade
```

For a fork or alternate remote, override the repository URL for the receiving shell:

```bash
curl -fsSL https://raw.githubusercontent.com/nw/pixel-dev-bootstrap/main/bootstrap.sh | \
  PIXEL_DEV_BOOTSTRAP_REPO=https://github.com/you/pixel-dev-bootstrap.git bash
```

To inspect before running instead of piping directly to Bash:

```bash
curl -fsSLo /tmp/pixel-dev-bootstrap.sh \
  https://raw.githubusercontent.com/nw/pixel-dev-bootstrap/main/bootstrap.sh
less /tmp/pixel-dev-bootstrap.sh
bash /tmp/pixel-dev-bootstrap.sh
```

The one-line bootstrap establishes the repository and substrate only. It does not install recipes, box images, registry credentials, or project-specific workloads.

## Working model

```text
Android shared storage
└── dev/
    ├── pixel-dev-bootstrap/    # reset-resilient offline reconstruction copy
    ├── artifacts/
    ├── configs/
    │   └── avf/home/           # user-owned AVF home overlay
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

## Manual/local install

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
--configs-only    update dotfiles/helpers without package or system changes
```

Examples:

```bash
bash install.sh --configs-only
bash install.sh --avf --no-upgrade
```

The installer establishes the substrate only. Optional Termux capability is
installed explicitly through `recipe`; named AVF workload environments are
resolved explicitly through `box`. There are no runtime/image install profiles.

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
- platform-specific helpers: `recipe` on Termux; `box` and `avf-sync` on AVF

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

Recipe discovery is inert. `recipe list` and the metadata fallback for
`recipe info` parse two single-line literal assignments without sourcing
recipe code:

```bash
recipe_name="vnote"
recipe_description="Quick voice notes through Android STT"
```

Those two assignments are a hard recipe contract. Executable `recipe.sh` code
is sourced only for explicit `install` and `check` operations, never while
browsing the catalog.

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
- optional launcher/widget shortcuts are copied as regular executable files under
  `~/.shortcuts/` because Termux shortcut validation requires the canonical file
  to remain inside that directory;
- recipe removal deletes only recipe-owned private files, links, and unchanged
  shortcut copies. Shared packages and user-modified shortcut files are left alone.

This copy-first model is deliberate. The public/bootstrap copy may live under
Android shared storage; installed recipe payloads do not execute from or depend
on shared-storage symlink behavior. Updates are staged as a complete private
copy before the active recipe payload or links are touched, so a failed copy
leaves the installed recipe intact.

Rerunning `install.sh --configs-only` refreshes the private **catalog only**. It
does not mutate an installed recipe. Run `recipe install <name>` again when you
explicitly want to update that recipe from the refreshed catalog.

### `vnote` recipe

`vnote` is the first example: a small voice-to-Markdown bridge that uses Android
speech-to-text through Termux:API and can optionally fall back to local
`whisper-cli` transcription when native STT is unavailable or fails. Cancelling
the Android dialog, or completing it without recognized speech, exits cleanly
without starting local recording.

```bash
recipe install vnote
vnote
```

The recipe also installs a foreground launcher script at:

```text
~/.shortcuts/vnote
```

That makes voice capture available from Termux's widget/launcher shortcut surface
without first navigating into a shell. Current Google Play Termux includes Widget
functionality in the main app; F-Droid/GitHub Termux users need the matching
Termux:Widget plugin from the same signing source. Refresh the widget after
installing or updating the recipe if the shortcut is not immediately visible.

The recipe ensures `termux-api` and `ffmpeg`. The matching **Termux:API Android
companion app must still be installed from the same signing source as Termux**
when that Termux distribution requires the separate companion app. Current Google
Play Termux exposes the speech/microphone commands used by `vnote` directly. The
recipe deliberately does not install a Whisper engine or model.

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

### AVF durable home overlay

The public bootstrap should not have to own every personal host-level preference.
AVF therefore has one deliberately dumb customization seam:

```text
$DEV_SHARED/configs/avf/home/
```

Paths below that directory mirror paths below `$HOME`. For example:

```text
/mnt/shared/dev/configs/avf/home/
├── .codex/
│   └── AGENTS.md
├── .config/
│   └── some-tool/config.toml
└── bin/
    └── my-helper
```

Preview and apply it with:

```bash
avf-sync --dry-run
avf-sync
```

`avf-sync` is **copy-only**: it never deletes unrelated files from the VM home.
Matching overlay paths intentionally win when copied. It does not install packages,
run lifecycle hooks, create profiles, or become another recipe system. Files under
`home/bin/` are made user-executable after landing on the normal AVF filesystem,
because Android shared storage is not trusted to preserve executable-mode intent.

The overlay is for non-secret host configuration and small durable tools. Common
credential locations (`.ssh`, `.gnupg`, registry auth, Codex auth, and similar) are
excluded on purpose. Keep secrets in AVF-private state or use a purpose-built
recovery path such as `ssh-seal`. Project runtimes still belong in OCI images, and
Git/remotes remain the real durability layer beyond the device.

A small agent-host example is included at:

```text
examples/avf-home/.codex/AGENTS.md.example
```

To adopt it as a durable Codex host contract:

```bash
mkdir -p /mnt/shared/dev/configs/avf/home/.codex
cp /mnt/shared/dev/pixel-dev-bootstrap/examples/avf-home/.codex/AGENTS.md.example \
  /mnt/shared/dev/configs/avf/home/.codex/AGENTS.md
avf-sync
```

That creates a normal VM-local `~/.codex/AGENTS.md` while keeping the source in
the reset-resilient overlay. Repository `AGENTS.md` files remain the place for
project-specific constraints; the example is intentionally only about the Pixel
AVF host boundary.

### AVF Debian role

The AVF host stays intentionally smaller. It gets normal shell/editor/network tools plus rootless Podman support, but **does not install Node or project-specific runtimes on the host**. `pm`/`pms`/`pmlan` cover ad-hoc images; `box` adds a thin named-OCI vocabulary without changing the AVF host package baseline.

Use it for:

- containerized Node/Python/toolchains
- builds and services
- ESP-IDF or other persistent toolchain environments when needed
- disposable experiments
- Linux graphical applications through Display

Voice notes captured on the Termux side can be promoted from shared scratch state
into a project working tree explicitly:

```bash
cd ~/src/project
vnote-import notes/idea.md
```

`vnote-import` copies `$DEV_SHARED/voice-scratchpad.md` by default, creates parent
directories, and refuses to overwrite an existing destination. Override the source
with `VNOTE_SHARED_FILE` when needed. The explicit copy keeps `/mnt/shared` as the
interchange surface while project-owned notes live under the normal AVF filesystem.

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

`pm` remains the cheapest disposable-workload helper:

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

The Podman functions use `--userns=keep-id`, bind the selected directory at
`/work`, and default published ports to loopback.

### Named OCI boxes

`box` is a thin, AVF-only convenience layer for **named OCI environments**. It
is not an installer, image manager, package manager, or credential store.
Podman remains authoritative for image/container/auth state.

The durable definition surface is data only:

```text
/mnt/shared/dev/configs/
├── registries.conf
└── boxes.d/
    └── <name>.box
```

Because these files live under `/mnt/shared`, they survive an AVF reset. Keep a
canonical copy in Git/remote storage if they matter after device loss.

#### Registry aliases

The installer seeds:

```text
public=docker.io/library
```

in:

```text
/mnt/shared/dev/configs/registries.conf
```

Add a private namespace when useful:

```text
private=ghcr.io/your-user-or-org
```

An image specification may then use the alias before the first `:`:

```text
public:node:24
    -> docker.io/library/node:24

private:pulse-esp-idf:5.4.4
    -> ghcr.io/your-user-or-org/pulse-esp-idf:5.4.4
```

Fully-qualified image names continue to work normally.

Authentication is deliberately delegated to Podman:

```bash
box registries
box login private
box auth
box logout private
```

`box login private` resolves the alias to its registry host and invokes
`podman login`; credentials remain Podman-owned and VM-local. Authentication is
host-scoped, so multiple aliases on the same registry host share the same Podman
credential. A reset therefore requires logging into private registries again
unless you separately choose a Podman-supported credential strategy.

#### Box definition format

A box is one inert `key=value` file; it is parsed, never sourced as shell code:

```text
# /mnt/shared/dev/configs/boxes.d/esp.box
description=ESP-IDF toolchain environment
image=private:pulse-esp-idf:5.4.4
workdir=/work
shell=/bin/bash
env=IDF_TARGET=esp32s3
mount=/mnt/shared/dev/artifacts:/artifacts
```

Supported keys:

```text
description=...     optional human description
image=...           required OCI image or registry-alias image
workdir=...         container workdir; default /work
shell=...           command used by `box shell`; default /bin/sh
env=KEY=value       repeatable default environment entry
mount=host:guest    repeatable default Podman volume mapping
```

No ports are stored in the definition by default. Ports describe the current
workload/session, so they remain explicit runtime flags.

See [`examples/boxes/esp-idf.box.example`](examples/boxes/esp-idf.box.example)
for a substantial-toolchain-shaped example. The image name is intentionally a
placeholder: build/publish the OCI environment that matches your own toolchain.

#### `box` API surface

```text
box list
box info <name>
box pull <name>

box run <name> [directory]
  [-p|--port <host:container>]...
  [-e|--env <KEY=value>]...
  [-v|--mount <host:container[:options]>]...
  [--bind <address>]
  [-- <command...>]

box shell <name> [directory]
  [-p|--port <host:container>]...
  [-e|--env <KEY=value>]...
  [-v|--mount <host:container[:options]>]...
  [--bind <address>]

box registries
box login <registry-alias>
box logout <registry-alias>
box auth
```

Runtime environment flags are appended after definition defaults, so an
explicit value naturally wins:

```bash
box run esp ~/src/pulse \
  -e IDF_TARGET=esp32c6 \
  -- idf.py build
```

Ports are repeatable and bind to loopback by default:

```bash
box run web ~/src/app \
  -p 3000:3000 \
  -p 8080:80
```

Explicit LAN exposure is visible in the command:

```bash
box run web ~/src/app -p 3000:3000 --bind 0.0.0.0
```

A single-number port maps host and container ports identically:

```bash
box run web ~/src/app -p 3000
# 127.0.0.1:3000 -> container :3000
```

`box pull` is only a friendly resolution step over `podman pull`. `box` never
removes images or volumes; use Podman directly or `pdeepclean` for cleanup.
Likewise, `box` does not persist registry credentials, resolve image versions,
or build images. OCI registries and Podman already own those concerns.

This creates a narrow persistence split:

```text
Git/remotes        source of truth
OCI registry       reproducible execution environments
/mnt/shared/dev    reset-resilient definitions/artifacts
AVF + Podman       disposable execution state
```

If a named environment starts requiring a persistent home, lifecycle hooks,
GUI exports, or deep host integration, that is the point where Distrobox may
have earned itself. `box` should remain a thin name-to-OCI/runtime-default map.

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
avf-sync       # optional user-owned host overlay
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

## License

Pixel Dev Bootstrap is released under the [MIT License](LICENSE).

## Development and AI assistance

The project is scoped, directed, reviewed, and maintained by Nathan White.
OpenAI's ChatGPT contributed materially during the 0.1.x development cycle,
including implementation, test construction, documentation, design iteration, and
review. Other AI models were also used as independent feedback/review tools.

AI output is treated as engineering input, not authority: shipped changes are
reviewed, tested, and accepted by the maintainer. No AI service is required at
runtime. See [ACKNOWLEDGMENTS.md](ACKNOWLEDGMENTS.md).
