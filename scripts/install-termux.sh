#!/usr/bin/env bash
set -Eeuo pipefail

: "${BOOTSTRAP_ROOT:?BOOTSTRAP_ROOT is required}"
: "${BOOTSTRAP_UPGRADE:=1}"
: "${BOOTSTRAP_CONFIGS_ONLY:=0}"
: "${BOOTSTRAP_GENERATE_SSH_KEY:=1}"

# shellcheck source=./lib.sh
source "$BOOTSTRAP_ROOT/scripts/lib.sh"

if [[ "$BOOTSTRAP_CONFIGS_ONLY" != "1" ]]; then
  require_command pkg

  say "Updating Termux package metadata"
  export DEBIAN_FRONTEND=noninteractive
  pkg update

  if [[ "$BOOTSTRAP_UPGRADE" == "1" ]]; then
    say "Upgrading Termux packages"
    pkg upgrade -y -o Dpkg::Options::="--force-confold"
  fi

  CORE_PACKAGES=(
    termux-exec
    git openssh curl wget rsync ca-certificates bash-completion
    jq ripgrep fd fzf tmux neovim micro less file tree patch zip unzip tar man
    procps iproute2 dnsutils inetutils lsof
    python python-pip nodejs-lts npm clang make cmake ninja pkg-config
    eza bat zoxide
  )

  say "Installing Termux CLI and development baseline"
  pkg install -y "${CORE_PACKAGES[@]}"

  OPTIONAL_PACKAGES=(
    gh
    shellcheck
    shfmt
    termux-api
  )

  say "Installing useful optional Termux packages"
  install_optional_packages_pkg "${OPTIONAL_PACKAGES[@]}"
fi

say "Configuring Android shared-storage bridge"
if [[ ! -d "$HOME/storage/shared" ]]; then
  if command -v termux-setup-storage >/dev/null 2>&1; then
    echo "Android may ask you to grant Termux file access."
    if ! termux-setup-storage; then
      warn "Storage setup did not complete. Re-run: termux-setup-storage"
    fi
  else
    warn "termux-setup-storage is unavailable"
  fi
fi

if [[ -d "$HOME/storage/shared" ]]; then
  mkdir -p \
    "$HOME/storage/shared/dev/artifacts" \
    "$HOME/storage/shared/dev/configs" \
    "$HOME/storage/shared/dev/containers" \
    "$HOME/storage/shared/dev/exports"
fi

export BOOTSTRAP_PLATFORM="termux"
export BOOTSTRAP_GENERATE_SSH_KEY
bash "$BOOTSTRAP_ROOT/scripts/setup-home.sh"

if command -v termux-reload-settings >/dev/null 2>&1; then
  termux-reload-settings || warn "Could not reload Termux settings automatically"
fi

say "Termux sanity check"
for command_name in git ssh node npm python nvim micro; do
  if command -v "$command_name" >/dev/null 2>&1; then
    printf '%-9s %s\n' "$command_name:" \
      "$("$command_name" --version 2>&1 | head -n 1)"
  fi
done

cat <<'EOF_DONE'

Termux is ready.

Next:
  source ~/.bashrc
  dev-doctor

Clipboard integration:
  The termux-api command package was installed on a best-effort basis.
  Android clipboard access also requires the matching Termux:API companion app
  from the same distribution/signing source as Termux.
EOF_DONE
