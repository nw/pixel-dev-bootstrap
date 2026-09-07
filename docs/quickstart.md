# Quick start and command reference

Operational reference for `pixel-dev-bootstrap`.

For rationale and support scope, see the main [README](../README.md). For AVF
specifics, see [AVF.md](AVF.md).

## Boundary

> **Extend the development tether; do not replace the workstation.**

```text
Termux
  always-there Android shell, SSH, lightweight tools, Android integrations

Pixel AVF Debian
  disposable burst Linux, rootless Podman, builds and heavier tooling

/mnt/shared/dev
  reset-resilient configs, interchange and artifacts
  not a primary Linux working filesystem and not device-loss durability

SSH / workstation / cloud
  intentional escalation when the phone stops being the right execution target
```

Recipes are optional Termux ↔ Android integrations. AVF workloads belong in OCI
images through Podman. `box` is only a named-environment layer over Podman.

## Install

From Termux or the Pixel Linux Development Environment:

```bash
curl -fsSL https://raw.githubusercontent.com/nw/pixel-dev-bootstrap/main/bootstrap.sh | bash
```

Then:

```bash
source ~/.bashrc
dev-doctor
```

The bootstrap checkout lives on each environment's private filesystem:

```text
Termux: ~/.local/share/pixel-dev-bootstrap/source
AVF:    ~/.local/share/pixel-dev-bootstrap/source
```

The paths look the same but are separate checkouts. Shared storage is created for
`dev/` state only; Git metadata is intentionally kept off Android shared storage.

The bootstrap installs the substrate only. Recipes, registry authentication,
box images and project workloads remain explicit.

## Folder map

```text
Android shared storage
└── dev/
    ├── configs/
    │   ├── repos.txt              repo URLs for reseed
    │   ├── registries.conf        box registry aliases
    │   ├── boxes.d/*.box          named OCI environments
    │   └── avf/home/              user-owned AVF home overlay
    │       ├── .codex/AGENTS.md
    │       ├── .config/
    │       └── bin/
    ├── containers/                durable OCI/compose inputs
    ├── artifacts/                 Android-visible outputs
    └── exports/                   explicit exports

Termux private home
├── ~/.local/share/pixel-dev-bootstrap/source
│                                  disposable bootstrap checkout
└── ~/src/                         Termux working trees

AVF private home
├── ~/.local/share/pixel-dev-bootstrap/source
│                                  disposable bootstrap checkout
└── /home/droid/
    ├── src/                       disposable AVF working trees
    ├── scratch/
    └── bin/
```

Shared root aliases:

```text
Termux: $HOME/storage/shared/dev
AVF:    /mnt/shared/dev
```

### Optional versioned personal control plane

Keep Git metadata on a normal private filesystem or remote, **not** directly under
`/mnt/shared/dev`. Android shared storage is the materialized reset-resilient copy,
not a Git working tree.

A simple personal pattern is:

```text
private Git checkout / remote
  configs/
  containers/
        |
        | copy/sync non-secret reconstruction files
        v
/mnt/shared/dev/
  configs/
  containers/
```

The remote repository or another external backup is canonical durability. Shared
storage survives an AVF reset, not a lost or wiped phone.

## Fast paths

### Termux

```bash
source ~/.bashrc
dev-doctor
recipe list
```

Optional voice capture:

```bash
recipe install vnote
vnote
```

### AVF Debian

```bash
source ~/.bashrc
dev-doctor
avf-sync --dry-run
avf-sync
reseed
```

Disposable OCI shell:

```bash
pms debian:bookworm
```

Named OCI environment:

```bash
box list
box info esp
```

## Commands

### Install and health

| Command | Purpose |
| --- | --- |
| `bootstrap.sh` | thin remote entrypoint; detects Termux/AVF, creates shared `dev/`, maintains a private bootstrap checkout, then runs `install.sh` |
| `bash install.sh [options]` | local installer |
| `dev-doctor` | environment, storage, command, clipboard and AVF/Podman diagnostics |
| `./doctor.sh` | checkout-local wrapper for `dev-doctor` |

`install.sh` options:

```text
--termux          force Termux
--avf             force AVF Debian
--no-upgrade      skip full package upgrade; install missing packages
--no-ssh-key      do not generate ~/.ssh/id_ed25519
--restore-ssh-key restore an age-encrypted key from shared configs
--no-podman       AVF only: skip Podman and subordinate-ID setup
--configs-only    refresh bootstrap-owned config/helpers only
-h, --help        show help
```

Examples:

```bash
bash install.sh --configs-only
bash install.sh --avf --no-upgrade
```

Pass options through the one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/nw/pixel-dev-bootstrap/main/bootstrap.sh | \
  bash -s -- --no-upgrade
```

Use a fork:

```bash
curl -fsSL https://raw.githubusercontent.com/nw/pixel-dev-bootstrap/main/bootstrap.sh | \
  PIXEL_DEV_BOOTSTRAP_REPO=https://github.com/you/pixel-dev-bootstrap.git bash
```

### Common reconstruction and interchange

| Command | Purpose |
| --- | --- |
| `reseed [repos-file]` | clone missing repos into `$SRC`; never pull/overwrite existing trees |
| `clipcopy [text]` | copy argument/stdin through the active Termux or AVF Display clipboard backend |
| `clippaste` | print the active clipboard to stdout |
| `ssh-seal [--force]` | `age`-encrypt `~/.ssh/id_ed25519` into shared reset-recovery storage |
| `ssh-restore [--force]` | restore the encrypted SSH key into private home |

Default reseed manifest:

```text
$DEV_SHARED/configs/repos.txt
```

Example:

```bash
reseed
printf 'hello' | clipcopy
clippaste > note.txt
```

### Common shell helpers

| Command | Purpose |
| --- | --- |
| `csrc` | enter `$SRC` |
| `cscratch` | enter `$SCRATCH` |
| `cshared` | enter `$DEV_SHARED` |
| `cartifacts` | enter `$DEV_SHARED/artifacts` |
| `croot` | enter current Git root |
| `mkcd <dir>` | create and enter directory |
| `downloads` | enter the platform's Android Downloads view |
| `serve [port]` | HTTP server on `127.0.0.1`, default `8000` |
| `serve-lan [port]` | HTTP server on `0.0.0.0` |
| `ports` | listening TCP/UDP sockets |
| `psg <pattern>` | matching processes |
| `devinfo` | compact platform/tool summary |

Small Git aliases (`gs`, `gd`, `gds`, `gl`) and modern `ls`/navigation helpers
are also installed when their backing packages are available.

## Termux-only

### `recipe`

Optional Termux ↔ Android capabilities. Base bootstrap installs no recipes.

```text
recipe list
recipe info <name>
recipe install <name>
recipe check <name>
recipe remove <name>
```

Recipes may ensure missing Termux packages, but packages are shared state and
are never removed automatically. `recipe remove` removes only recipe-owned
payloads, links and unchanged shortcut files.

### `vnote`

Install explicitly:

```bash
recipe install vnote
```

Capture speech into Markdown:

```bash
vnote             # native Android STT first; local fallback max 120s
vnote 30          # local fallback ceiling 30s
vnote 0           # no local ceiling; Enter stops recording
```

Optional controls:

```bash
export VNOTE_MODE=auto      # auto | native | local
export VNOTE_NOTES_FILE="$DEV_SHARED/voice-scratchpad.md"
export VNOTE_MAX_SECONDS=120
export VNOTE_MODEL="$HOME/models/ggml-tiny.en.bin"
```

The recipe also installs `~/.shortcuts/vnote` for the Termux launcher/widget
surface. A local Whisper engine/model is deliberately user-owned and optional.

## AVF-only

### `avf-sync`

Copy the user-owned durable AVF home overlay into the disposable VM home:

```text
$DEV_SHARED/configs/avf/home/ -> $HOME/
```

```bash
avf-sync --dry-run
avf-sync
```

It never deletes unrelated home state. Common credential paths are excluded.
Files intentionally placed under overlay `home/bin/` become executable after
copying onto the normal AVF filesystem.

Optional source override:

```bash
AVF_SYNC_SOURCE=/other/overlay avf-sync --dry-run
```

### `vnote-import`

Promote the shared voice scratchpad into a project without overwriting existing
files:

```bash
cd ~/src/rax
vnote-import notes/idea.md
```

Without an argument, destination is `$PWD/voice-scratchpad.md`.

### `avfinfo`

Compact kernel, RAM, disk and subordinate-ID view:

```bash
avfinfo
```

### Ad-hoc Podman helpers

```text
pm <image> [directory] [port] [-- command ...]
pms <image> [directory] [port]
pmlan <image> [directory] [port] [-- command ...]
```

`pm` defaults to the current directory mounted at `/work`, uses
`--userns=keep-id`, pulls missing images, removes the container on exit and
binds ports to `127.0.0.1`.

```bash
pm node:24-bookworm
pm node:24-bookworm . -- npm test
pm node:24-bookworm . 3000
pm node:24-bookworm ~/src/app 8080:3000 -- npm test
pms debian:bookworm
```

`pmlan` is the deliberate LAN-exposure form (`0.0.0.0`).

Podman shorthand:

| Command | Behavior |
| --- | --- |
| `p` | `podman` |
| `pi` | images |
| `pps` | running containers |
| `ppa` | all containers |
| `pv` | volumes |
| `pn` | networks |
| `pstats` | stats |
| `pclean [args...]` | normal `podman system prune` |
| `pdeepclean` | aggressive prune of all unused containers, images, volumes and build cache |

### `box`

Named OCI environments. Podman still owns images, containers and credentials.

```text
box list
box info <name>
box pull <name>
box run <name> [directory] [-p port]... [-e KEY=value]... [-v mount]...
        [--bind address] [-- command ...]
box shell <name> [directory] [-p port]... [-e KEY=value]... [-v mount]...
          [--bind address]
box registries
box login <registry-alias>
box logout <registry-alias>
box auth
```

Examples:

```bash
box run esp ~/src/pulse -e IDF_TARGET=esp32c6 -- idf.py build
box run web ~/src/app -p 3000:3000
box shell esp ~/src/pulse
```

Ports bind to loopback unless explicitly exposed:

```bash
box run web ~/src/app -p 3000:3000 --bind 0.0.0.0
```

Definitions live at `$DEV_SHARED/configs/boxes.d/<name>.box` and support inert
`key=value` fields:

```text
description=<text>
image=<image or registry-alias:image>
workdir=/work
shell=/bin/bash
env=KEY=value                         # repeatable
mount=host:container[:options]        # repeatable
```

Example:

```text
description=ESP-IDF toolchain
image=private:pulse-esp-idf:5.4.4
workdir=/work
shell=/bin/bash
env=IDF_TARGET=esp32s3
mount=/mnt/shared/dev/artifacts:/artifacts
```

Registry aliases live at `$DEV_SHARED/configs/registries.conf`:

```text
public=docker.io/library
private=ghcr.io/your-user-or-org
```

`box login/logout` only resolves the host and delegates authentication to
Podman. Credentials are never owned or persisted by the bootstrap.

## AVF reset cadence

```bash
# Re-establish public substrate when needed.
curl -fsSL https://raw.githubusercontent.com/nw/pixel-dev-bootstrap/main/bootstrap.sh | bash
source ~/.bashrc

# Restore user-owned AVF host shape.
avf-sync

# Recreate missing working trees.
reseed

# Authenticate/pull only environments needed for current work.
box login private    # when required
box pull esp         # example
```

If recovery starts becoming careful VM restoration, persistent-service
management or host-specific project setup, the workload has crossed the intended
boundary. Put it in OCI, SSH to larger compute, or use a workstation.
