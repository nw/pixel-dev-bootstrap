#!/usr/bin/env bash

say()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

as_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    "$@"
  else
    require_command sudo
    sudo "$@"
  fi
}

BOOTSTRAP_STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/pixel-dev-bootstrap"
BOOTSTRAP_RUN_ID="$(date +%Y%m%d-%H%M%S)"
BOOTSTRAP_BACKUP_ROOT="$BOOTSTRAP_STATE_ROOT/backups/$BOOTSTRAP_RUN_ID"
BOOTSTRAP_BACKUP_USED=0

backup_file() {
  local target="$1"
  [[ -e "$target" || -L "$target" ]] || return 0

  local relative="${target#/}"
  local destination="$BOOTSTRAP_BACKUP_ROOT/$relative"
  mkdir -p -- "$(dirname -- "$destination")"
  cp -a -- "$target" "$destination"
  BOOTSTRAP_BACKUP_USED=1
  info "Backed up $target"
}

install_file() {
  local source="$1"
  local target="$2"
  local mode="${3:-}"

  [[ -f "$source" ]] || die "Source file missing: $source"
  mkdir -p -- "$(dirname -- "$target")"

  if [[ -f "$target" ]] && cmp -s -- "$source" "$target"; then
    [[ -n "$mode" ]] && chmod "$mode" "$target"
    info "Unchanged: $target"
    return 0
  fi

  backup_file "$target"
  cp -- "$source" "$target"
  [[ -n "$mode" ]] && chmod "$mode" "$target"
  info "Installed: $target"
}

install_if_missing() {
  local source="$1"
  local target="$2"
  local mode="${3:-}"

  if [[ -e "$target" || -L "$target" ]]; then
    info "Preserved existing: $target"
    return 0
  fi
  install_file "$source" "$target" "$mode"
}

prune_old_backups() {
  local keep="${PIXEL_BOOTSTRAP_BACKUPS_KEEP:-10}"
  local root="$BOOTSTRAP_STATE_ROOT/backups"
  [[ "$keep" =~ ^[0-9]+$ ]] || keep=10
  [[ -d "$root" ]] || return 0

  local had_nullglob=0
  shopt -q nullglob && had_nullglob=1
  shopt -s nullglob
  local -a backups=("$root"/*)
  ((had_nullglob)) || shopt -u nullglob

  local -a directories=() path
  for path in "${backups[@]}"; do
    [[ -d "$path" ]] && directories+=("$path")
  done

  local remove_count=$((${#directories[@]} - keep))
  ((remove_count > 0)) || return 0

  local index
  for ((index=0; index<remove_count; index++)); do
    rm -rf -- "${directories[index]}"
  done
  info "Pruned $remove_count old bootstrap backup(s); keeping newest $keep"
}

finish_backup_notice() {
  if ((BOOTSTRAP_BACKUP_USED)); then
    say "Previous files were preserved"
    info "$BOOTSTRAP_BACKUP_ROOT"
  fi
  prune_old_backups
}

install_optional_packages_apt() {
  local package
  for package in "$@"; do
    if ! as_root apt-get install -y --no-install-recommends "$package"; then
      warn "Could not install optional Debian package: $package"
    fi
  done
}

install_optional_packages_pkg() {
  local package
  for package in "$@"; do
    if ! pkg install -y "$package"; then
      warn "Could not install optional Termux package: $package"
    fi
  done
}
