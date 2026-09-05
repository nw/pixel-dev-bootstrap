#!/usr/bin/env bash
set -Eeuo pipefail

: "${BOOTSTRAP_ROOT:?BOOTSTRAP_ROOT is required}"
: "${BOOTSTRAP_PLATFORM:?BOOTSTRAP_PLATFORM is required}"
: "${BOOTSTRAP_GENERATE_SSH_KEY:=1}"

# shellcheck source=./lib.sh
source "$BOOTSTRAP_ROOT/scripts/lib.sh"

say "Creating home-directory layout"
mkdir -p \
  "$HOME/src" \
  "$HOME/scratch" \
  "$HOME/bin" \
  "$HOME/.local/bin" \
  "$HOME/.local/share" \
  "$HOME/.local/state" \
  "$HOME/.config/nvim" \
  "$HOME/.config/pixel-dev-bootstrap/shell" \
  "$HOME/.cache" \
  "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

say "Installing shell configuration"
install_file "$BOOTSTRAP_ROOT/config/bash/bashrc" "$HOME/.bashrc" 0644
install_file "$BOOTSTRAP_ROOT/config/bash/bash_profile" "$HOME/.bash_profile" 0644
install_file "$BOOTSTRAP_ROOT/config/bash/inputrc" "$HOME/.inputrc" 0644
install_file "$BOOTSTRAP_ROOT/config/bash/common.bash" \
  "$HOME/.config/pixel-dev-bootstrap/shell/common.bash" 0644
install_file "$BOOTSTRAP_ROOT/config/bash/${BOOTSTRAP_PLATFORM}.bash" \
  "$HOME/.config/pixel-dev-bootstrap/shell/platform.bash" 0644

if [[ "$BOOTSTRAP_PLATFORM" == "avf" ]]; then
  install_file "$BOOTSTRAP_ROOT/config/bash/podman.bash" \
    "$HOME/.config/pixel-dev-bootstrap/shell/podman.bash" 0644
else
  rm -f -- "$HOME/.config/pixel-dev-bootstrap/shell/podman.bash"
fi

say "Installing editor and terminal configuration"
install_file "$BOOTSTRAP_ROOT/config/nvim/init.lua" "$HOME/.config/nvim/init.lua" 0644
install_file "$BOOTSTRAP_ROOT/config/tmux/tmux.conf" "$HOME/.tmux.conf" 0644

if [[ "$BOOTSTRAP_PLATFORM" == "termux" ]]; then
  mkdir -p "$HOME/.termux"
  install_file "$BOOTSTRAP_ROOT/config/termux/termux.properties" \
    "$HOME/.termux/termux.properties" 0644
fi

say "Installing helper commands"
local_bin_source="$BOOTSTRAP_ROOT/bin"
for helper in "$local_bin_source"/*; do
  [[ -f "$helper" ]] || continue
  install_file "$helper" "$HOME/bin/$(basename -- "$helper")" 0755
done

say "Configuring SSH and Git defaults"
install_if_missing "$BOOTSTRAP_ROOT/config/ssh/config" "$HOME/.ssh/config" 0600

SSH_KEY="$HOME/.ssh/id_ed25519"
if [[ "$BOOTSTRAP_GENERATE_SSH_KEY" == "1" ]]; then
  if [[ ! -f "$SSH_KEY" ]]; then
    comment="${BOOTSTRAP_PLATFORM}@pixel"
    ssh-keygen -t ed25519 -C "$comment" -f "$SSH_KEY" -N ""
    info "Generated: $SSH_KEY"
  else
    info "Preserved existing SSH key: $SSH_KEY"
  fi
fi

if command -v git >/dev/null 2>&1; then
  git config --global init.defaultBranch main
  git config --global fetch.prune true
  git config --global core.editor nvim
  if [[ -f "${SSH_KEY}.pub" ]]; then
    git config --global gpg.format ssh
    git config --global user.signingkey "${SSH_KEY}.pub"
    git config --global commit.gpgsign false
  fi
fi

finish_backup_notice
