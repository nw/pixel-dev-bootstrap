#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="${PIXEL_DEV_BOOTSTRAP_REPO:-https://github.com/nw/pixel-dev-bootstrap.git}"
REPO_REF="${PIXEL_DEV_BOOTSTRAP_REF:-main}"

say()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

as_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "Need root privileges for: $*"
  fi
}

PLATFORM=""
SHARED_ROOT=""

if [[ -n "${TERMUX_VERSION:-}" ]] || [[ "${PREFIX:-}" == */com.termux/files/usr ]]; then
  PLATFORM="termux"

  if [[ ! -d "$HOME/storage/shared" ]]; then
    command -v termux-setup-storage >/dev/null 2>&1 || \
      die "termux-setup-storage is unavailable"

    say "Enabling Android shared storage"
    info "Grant Termux file access if Android prompts, then return here."
    termux-setup-storage || true

    for ((attempt=0; attempt<30; attempt++)); do
      [[ -d "$HOME/storage/shared" ]] && break
      sleep 1
    done
  fi

  [[ -d "$HOME/storage/shared" ]] || \
    die "Shared storage is still unavailable. Run termux-setup-storage and retry."
  SHARED_ROOT="$HOME/storage/shared"

  if ! command -v git >/dev/null 2>&1; then
    say "Installing bootstrap prerequisite: git"
    pkg update
    pkg install -y git ca-certificates
  fi
elif [[ -f /etc/debian_version && -d /mnt/shared ]]; then
  PLATFORM="avf"
  [[ -w /mnt/shared ]] || die "/mnt/shared is not writable"
  SHARED_ROOT="/mnt/shared"

  if ! command -v git >/dev/null 2>&1; then
    say "Installing bootstrap prerequisite: git"
    as_root apt-get update
    as_root apt-get install -y --no-install-recommends git ca-certificates
  fi
else
  die "Could not detect Termux or Pixel AVF Debian"
fi

DEV_ROOT="$SHARED_ROOT/dev"
REPO_DIR="$HOME/.local/share/pixel-dev-bootstrap/source"
mkdir -p "$DEV_ROOT" "$(dirname -- "$REPO_DIR")"

say "Preparing pixel-dev-bootstrap"
info "platform: $PLATFORM"
info "path:     $REPO_DIR"

if [[ -e "$REPO_DIR" && ! -d "$REPO_DIR/.git" ]]; then
  die "$REPO_DIR already exists but is not a Git checkout; refusing to overwrite it"
fi

if [[ ! -d "$REPO_DIR/.git" ]]; then
  git clone --branch "$REPO_REF" "$REPO_URL" "$REPO_DIR"
else
  current_origin="$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || true)"
  if [[ -n "$current_origin" && "$current_origin" != "$REPO_URL" ]]; then
    warn "Existing checkout uses a different origin: $current_origin"
    warn "Leaving it untouched and using the existing checkout."
  elif [[ -n "$(git -C "$REPO_DIR" status --porcelain)" ]]; then
    warn "Existing checkout has local changes; skipping automatic update."
  else
    say "Updating existing checkout"
    # Keep reruns conservative: only fast-forward the checkout the user already has.
    if ! git -C "$REPO_DIR" pull --ff-only; then
      warn "Could not fast-forward existing checkout; continuing with current files."
    fi
  fi
fi

[[ -f "$REPO_DIR/install.sh" ]] || die "install.sh not found in $REPO_DIR"

say "Running local bootstrap"
bash "$REPO_DIR/install.sh" "$@"

cat <<EOF_DONE

One-line bootstrap complete.

Repository:
  $REPO_DIR

Reload the shell configuration in this session with:
  source ~/.bashrc
EOF_DONE
