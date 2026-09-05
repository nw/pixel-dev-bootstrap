#!/usr/bin/env bash
set -Eeuo pipefail

: "${BOOTSTRAP_ROOT:?BOOTSTRAP_ROOT is required}"
: "${BOOTSTRAP_UPGRADE:=1}"
: "${BOOTSTRAP_CONFIGS_ONLY:=0}"
: "${BOOTSTRAP_GENERATE_SSH_KEY:=1}"
: "${BOOTSTRAP_RESTORE_SSH_KEY:=0}"
: "${BOOTSTRAP_INSTALL_PODMAN:=1}"

# shellcheck source=./lib.sh
source "$BOOTSTRAP_ROOT/scripts/lib.sh"

if [[ "$BOOTSTRAP_CONFIGS_ONLY" != "1" ]]; then
  [[ -f /etc/debian_version ]] || die "This installer expects Debian inside Pixel AVF Terminal."
  [[ -d /mnt/shared ]] || die "Expected AVF shared mount /mnt/shared was not found."
  require_command apt-get

  say "Updating Debian package metadata"
  export DEBIAN_FRONTEND=noninteractive
  as_root apt-get update

  if [[ "$BOOTSTRAP_UPGRADE" == "1" ]]; then
    say "Upgrading Debian packages"
    as_root apt-get upgrade -y
  fi

  BASE_PACKAGES=(
    git openssh-client curl wget rsync ca-certificates bash-completion
    jq ripgrep fd-find fzf tmux neovim less file tree patch zip unzip tar man-db
    bat age
    procps iproute2 dnsutils lsof netcat-openbsd socat xdg-utils
    python3 python3-pip python3-venv
    build-essential cmake ninja-build pkg-config
  )

  say "Installing a small AVF Debian host baseline"
  as_root apt-get install -y --no-install-recommends "${BASE_PACKAGES[@]}"

  OPTIONAL_PACKAGES=(
    micro
    eza
    zoxide
    gh
    shellcheck
    shfmt
    clang
    wl-clipboard
    xclip
  )

  say "Installing useful optional Debian packages"
  install_optional_packages_apt "${OPTIONAL_PACKAGES[@]}"

  if [[ "$BOOTSTRAP_INSTALL_PODMAN" == "1" ]]; then
    PODMAN_PACKAGES=(
      podman
      buildah
      uidmap
      slirp4netns
      fuse-overlayfs
      dbus-user-session
      crun
    )

    say "Installing rootless Podman support"
    as_root apt-get install -y --no-install-recommends "${PODMAN_PACKAGES[@]}"
    install_optional_packages_apt podman-compose passt
  fi
fi

say "Creating the reset-resilient Android-visible seed layout"
if [[ -d /mnt/shared && -w /mnt/shared ]]; then
  mkdir -p \
    /mnt/shared/dev/artifacts \
    /mnt/shared/dev/configs \
    /mnt/shared/dev/containers/compose \
    /mnt/shared/dev/exports
  if [[ ! -e /mnt/shared/dev/configs/repos.txt ]]; then
    cp -- "$BOOTSTRAP_ROOT/examples/repos.txt.example" /mnt/shared/dev/configs/repos.txt
    info "Seeded /mnt/shared/dev/configs/repos.txt"
  fi
else
  warn "/mnt/shared is unavailable or not writable; reset-resilient seed directories were not created"
fi

export BOOTSTRAP_PLATFORM="avf"
export BOOTSTRAP_GENERATE_SSH_KEY
export BOOTSTRAP_RESTORE_SSH_KEY
bash "$BOOTSTRAP_ROOT/scripts/setup-home.sh"

has_large_subid_range() {
  local file="$1"
  local user="$2"
  [[ -r "$file" ]] || return 1
  awk -F: -v user="$user" '$1 == user && $3 >= 65536 { found=1 } END { exit !found }' "$file"
}

has_any_subid_range() {
  local file="$1"
  local user="$2"
  [[ -r "$file" ]] || return 1
  awk -F: -v user="$user" '$1 == user { found=1 } END { exit !found }' "$file"
}

range_conflicts_with_other_user() {
  local file="$1"
  local user="$2"
  local first="$3"
  local last="$4"
  [[ -r "$file" ]] || return 1
  awk -F: -v user="$user" -v first="$first" -v last="$last" '
    $1 != user && $2 <= last && ($2 + $3 - 1) >= first { found=1 }
    END { exit !found }
  ' "$file"
}

configure_subid() {
  local kind="$1"
  local file user first last option
  user="$(id -un)"
  first=100000
  last=165535

  case "$kind" in
    uid) file=/etc/subuid; option=--add-subuids ;;
    gid) file=/etc/subgid; option=--add-subgids ;;
    *) die "Unknown subordinate-ID kind: $kind" ;;
  esac

  if has_large_subid_range "$file" "$user"; then
    info "$kind mapping already configured: $(grep -E "^${user}:" "$file" | paste -sd ' ' -)"
    return 0
  fi

  if has_any_subid_range "$file" "$user"; then
    warn "$file already contains a smaller mapping for $user; leaving it unchanged"
    warn "Rootless Podman may need at least 65536 subordinate IDs. Inspect $file manually."
    return 1
  fi

  if range_conflicts_with_other_user "$file" "$user" "$first" "$last"; then
    warn "$file already allocates part of ${first}-${last} to another user"
    warn "Choose a free 65536-ID range and add it manually for $user"
    return 1
  fi

  as_root usermod "$option" "${first}-${last}" "$user"
  info "Added $user:${first}:65536 to $file"
}

if [[ "$BOOTSTRAP_CONFIGS_ONLY" != "1" && "$BOOTSTRAP_INSTALL_PODMAN" == "1" ]]; then
  say "Configuring subordinate IDs for rootless Podman"
  subid_ok=1
  configure_subid uid || subid_ok=0
  configure_subid gid || subid_ok=0

  if ((subid_ok)); then
    # Refresh Podman's rootless namespace after subordinate-ID changes.
    podman system migrate >/dev/null 2>&1 || true
  fi

  say "Checking rootless Podman"
  if podman info >/dev/null 2>&1; then
    podman info --format 'rootless={{.Host.Security.Rootless}} driver={{.Store.GraphDriverName}}' \
      2>/dev/null || true
  else
    warn "podman is installed, but rootless initialization failed; run dev-doctor"
  fi
fi

say "AVF Debian sanity check"
for command_name in git ssh python3 nvim micro podman; do
  if command -v "$command_name" >/dev/null 2>&1; then
    printf '%-9s %s\n' "$command_name:" \
      "$("$command_name" --version 2>&1 | head -n 1)"
  fi
done

cat <<'EOF_DONE'

AVF Debian is ready.

Next:
  source ~/.bashrc
  dev-doctor

Operating model:
  /mnt/shared/dev   reset-resilient seed/config/artifact interchange
  ~/src             disposable VM-local working trees
  Podman            disposable or named workload state

The installer intentionally leaves Node and project-specific runtimes out of
AVF's host. Use nodebox, pybox, pm, or explicit Podman commands instead.
EOF_DONE
