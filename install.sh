#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

PLATFORM="auto"
BOOTSTRAP_UPGRADE=1
BOOTSTRAP_GENERATE_SSH_KEY=1
BOOTSTRAP_RESTORE_SSH_KEY=0
BOOTSTRAP_INSTALL_PODMAN=1
BOOTSTRAP_CONFIGS_ONLY=0

usage() {
  cat <<'USAGE'
Usage: bash install.sh [options]

Auto-detects Termux or the Pixel AVF Debian environment and installs the
matching package/configuration set.

Options:
  --termux          Force the Termux installer
  --avf             Force the AVF Debian installer
  --no-upgrade      Skip package upgrades; still installs missing packages
  --no-ssh-key      Do not generate ~/.ssh/id_ed25519 when missing
  --restore-ssh-key Restore an age-encrypted SSH key from shared configs
  --no-podman       AVF only: skip Podman and subordinate-ID setup
  --configs-only    Install/update dotfiles and helper scripts only
  -h, --help        Show this help
USAGE
}

while (($#)); do
  case "$1" in
    --termux) PLATFORM="termux" ;;
    --avf) PLATFORM="avf" ;;
    --no-upgrade) BOOTSTRAP_UPGRADE=0 ;;
    --no-ssh-key) BOOTSTRAP_GENERATE_SSH_KEY=0 ;;
    --restore-ssh-key) BOOTSTRAP_RESTORE_SSH_KEY=1 ;;
    --no-podman) BOOTSTRAP_INSTALL_PODMAN=0 ;;
    --configs-only) BOOTSTRAP_CONFIGS_ONLY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ "$PLATFORM" == "auto" ]]; then
  if [[ -n "${TERMUX_VERSION:-}" ]] || [[ "${PREFIX:-}" == */com.termux/files/usr ]]; then
    PLATFORM="termux"
  elif [[ -f /etc/debian_version && -d /mnt/shared ]]; then
    PLATFORM="avf"
  else
    cat >&2 <<'EOF_DETECT'
Could not safely detect Termux or Pixel AVF Debian.
Re-run with either --termux or --avf.
EOF_DETECT
    exit 2
  fi
fi

export BOOTSTRAP_ROOT="$ROOT_DIR"
export BOOTSTRAP_UPGRADE
export BOOTSTRAP_GENERATE_SSH_KEY
export BOOTSTRAP_RESTORE_SSH_KEY
export BOOTSTRAP_INSTALL_PODMAN
export BOOTSTRAP_CONFIGS_ONLY

case "$PLATFORM" in
  termux) exec bash "$ROOT_DIR/scripts/install-termux.sh" ;;
  avf) exec bash "$ROOT_DIR/scripts/install-avf.sh" ;;
  *) printf 'Unsupported platform: %s\n' "$PLATFORM" >&2; exit 2 ;;
esac
