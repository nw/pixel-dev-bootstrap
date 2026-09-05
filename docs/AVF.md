# AVF Debian operating notes

## Filesystem boundary

```text
/mnt/shared/dev/
  pixel-dev-bootstrap/   reset-resilient reconstruction copy
  artifacts/             results Android should see
  configs/               non-secret portable configuration
  containers/            Containerfiles and compose definitions
  exports/               deliberate outbound files

/home/droid/
  src/                   Git working trees
  scratch/               experiments
  bin/                   local helpers
  .local/share/containers/
                         rootless Podman images, layers, volumes, state
```

Assume `/home/droid` is destroyed by a VM reset. It is still the correct place for active work because it has normal Linux filesystem semantics.

`/mnt/shared` survives that VM reset, but it is **not** a device-loss durability
layer. A phone wipe, loss, or storage failure removes it too. Keep canonical
source and important reconstruction metadata in Git/remotes or another external
backup; use `/mnt/shared/dev` as an offline reset-resilient cache.

Do not use `/mnt/shared` as the primary home for repositories, package trees, build directories, databases, or container storage. Export meaningful outputs there deliberately.

## VM resources

The default 1 GB allocation is a useful low-cost starting point.

```text
1 GB    shell, Git, SSH, light editing, one modest container
2 GB    normal Node/Python work, a larger build, a few small services
4 GB    compilers, ESP-IDF, heavier agents, multi-service work
6+ GB   deliberate burst use only; Android and foreground apps need headroom
```

Practical rhythm:

1. Leave the VM small by default.
2. Raise RAM for a specific workload rather than permanently.
3. Close obviously unnecessary Android apps before a heavy session.
4. Shut the VM down when the discrete task is complete.

The bootstrap cannot change the Terminal app's VM allocation from inside Debian; adjust it in the Android Terminal/VM settings.

## Security posture

- Keep the Pixel bootloader locked for enterprise compatibility.
- Keep rootless Podman rootless.
- Do not enable persistent Podman services merely for convenience.
- Do not enable user lingering by default; it works against the phone's battery model.
- Deny microphone access unless a Linux application has a concrete need.
- Keep cleartext SSH private keys and secrets in `/home/droid`, not `/mnt/shared`.
- If reset-stable SSH identity is useful, `ssh-seal` can place an `age`-encrypted key blob under `$DEV_SHARED/configs/ssh/`; retain the passphrase separately.
- Published container ports bind to `127.0.0.1` by default. Expose to `0.0.0.0` deliberately.

## Container-first boundary

The AVF host should hold boring, reusable infrastructure:

```text
shell + editor + git + ssh + diagnostics + podman
```

Project runtimes belong in images:

```bash
nodebox ~/src/project 3000
pybox ~/src/project
pm rust:latest ~/src/project - -- cargo test
```

Use named Podman volumes for caches or service data when useful, but regard them as VM-local and disposable unless explicitly exported.

Distrobox becomes valuable when a container turns into a persistent interactive toolchain environment with its own home, setup, GUI exports, or repeated integration needs. Until that pattern is visible, plain Podman is cheaper and clearer.


## Explicit Podman substrate

The bootstrap pins the rootless runtime and storage backend instead of relying on distro auto-detection:

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

`crun` and `fuse-overlayfs` are installed with Podman. On a fresh/rebuilt AVF VM this yields a predictable rootless store. If an existing VM has already initialized Podman with another storage driver, changing the file does not migrate old image/container state; keep the old store until done with it or reset deliberately.

Debian packages `fd-find` and `bat` expose `/usr/bin/fdfind` and `/usr/bin/batcat`. The bootstrap creates conventional aliases as real symlinks in `~/bin`:

```text
~/bin/fd  -> /usr/bin/fdfind
~/bin/bat -> /usr/bin/batcat
```

For aggressive cleanup before a VM reset or after disposable experiments:

```bash
pdeepclean
```

This runs `podman system prune -a --volumes --build -f`; it intentionally removes all unused images, containers, volumes, and build cache.

## Clipboard boundary

`wl-clipboard` and `xclip` are installed on a best-effort basis. They operate against graphical session clipboards:

```bash
printf 'hello' | clipcopy
clippaste
```

The text Terminal activity has its own Android-native copy/paste behavior. Do not assume a graphical clipboard backend is active unless `WAYLAND_DISPLAY` or `DISPLAY` exists. `dev-doctor` reports the active backend.

## Repository reseed

`reseed` consumes `$DEV_SHARED/configs/repos.txt`, one Git URL per line, and
clones only missing working trees into `~/src`. It never pulls or mutates an
existing working tree. The manifest is seeded from `examples/repos.txt.example`
on first setup. Treat its shared-storage copy as an offline recovery cache; keep
a canonical copy elsewhere if the list matters after device loss.

```bash
reseed
```
