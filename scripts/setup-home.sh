#!/usr/bin/env bash
set -Eeuo pipefail

: "${BOOTSTRAP_ROOT:?BOOTSTRAP_ROOT is required}"
: "${BOOTSTRAP_PLATFORM:?BOOTSTRAP_PLATFORM is required}"
: "${BOOTSTRAP_GENERATE_SSH_KEY:=1}"
: "${BOOTSTRAP_RESTORE_SSH_KEY:=0}"
: "${BOOTSTRAP_INSTALL_BOXES:=0}"

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
# Deliberately copy configuration rather than symlink it. The bootstrap source
# commonly lives on Android shared storage, where Unix symlink/mode semantics
# are not a reliable contract.
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

  if [[ "$BOOTSTRAP_INSTALL_BOXES" == "1" ]]; then
    install_file "$BOOTSTRAP_ROOT/config/bash/boxes.bash" \
      "$HOME/.config/pixel-dev-bootstrap/shell/boxes.bash" 0644
  else
    # Base is intentionally the default. Remove stale optional helpers so a
    # previous --with-boxes run does not silently survive a return to base.
    rm -f -- "$HOME/.config/pixel-dev-bootstrap/shell/boxes.bash"
  fi

  mkdir -p "$HOME/.config/containers"
  install_file "$BOOTSTRAP_ROOT/config/containers/containers.conf" \
    "$HOME/.config/containers/containers.conf" 0644
  install_file "$BOOTSTRAP_ROOT/config/containers/storage.conf" \
    "$HOME/.config/containers/storage.conf" 0644
else
  rm -f -- \
    "$HOME/.config/pixel-dev-bootstrap/shell/podman.bash" \
    "$HOME/.config/pixel-dev-bootstrap/shell/boxes.bash"
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

# Debian intentionally ships these commands under collision-safe binary names.
# Normalize them into ~/bin so shared shell config can use the conventional names.
if [[ "$BOOTSTRAP_PLATFORM" == "avf" ]]; then
  [[ -x /usr/bin/fdfind ]] && ln -sf /usr/bin/fdfind "$HOME/bin/fd"
  [[ -x /usr/bin/batcat ]] && ln -sf /usr/bin/batcat "$HOME/bin/bat"
fi

say "Configuring SSH and Git defaults"
install_if_missing "$BOOTSTRAP_ROOT/config/ssh/config" "$HOME/.ssh/config" 0600

SSH_KEY="$HOME/.ssh/id_ed25519"

if [[ "$BOOTSTRAP_RESTORE_SSH_KEY" == "1" && ! -f "$SSH_KEY" ]]; then
  say "Restoring SSH key from encrypted shared-storage recovery blob"
  if ! "$HOME/bin/ssh-restore"; then
    die "SSH restore was requested but failed"
  fi
fi

if [[ "$BOOTSTRAP_GENERATE_SSH_KEY" == "1" ]]; then
  if [[ ! -f "$SSH_KEY" ]]; then
    comment="${BOOTSTRAP_PLATFORM}@pixel"
    ssh-keygen -t ed25519 -C "$comment" -f "$SSH_KEY" -N ""
    info "Generated: $SSH_KEY"
  else
    info "Preserved existing SSH key: $SSH_KEY"
  fi
fi

git_config_default() {
  local key="$1" value="$2"
  git config --global --get "$key" >/dev/null 2>&1 || git config --global "$key" "$value"
}

if command -v git >/dev/null 2>&1; then
  # Defaults are only seeded when absent. A configs-only rerun must never
  # silently overwrite a global Git preference the user changed deliberately.
  git_config_default init.defaultBranch main
  git_config_default fetch.prune true
  git_config_default core.editor nvim
  if [[ -f "${SSH_KEY}.pub" ]]; then
    git_config_default gpg.format ssh
    git_config_default user.signingkey "${SSH_KEY}.pub"
    git_config_default commit.gpgsign false
  fi
fi
unset -f git_config_default 2>/dev/null || true

finish_backup_notice
