export PIXEL_PLATFORM="avf"
export DEV_SHARED="${DEV_SHARED:-/mnt/shared/dev}"

if [[ -d /mnt/shared/Download ]]; then
  export DOWNLOADS="${DOWNLOADS:-/mnt/shared/Download}"
elif [[ -d /mnt/shared/Downloads ]]; then
  export DOWNLOADS="${DOWNLOADS:-/mnt/shared/Downloads}"
else
  export DOWNLOADS="${DOWNLOADS:-/mnt/shared}"
fi

mkdir -p "$HOME/src" "$HOME/scratch" "$HOME/bin" 2>/dev/null || true

downloads() { cd "$DOWNLOADS" || return; }

vnote-import() {
  local src="${VNOTE_SHARED_FILE:-$DEV_SHARED/voice-scratchpad.md}"
  local dest="${1:-$PWD/voice-scratchpad.md}"

  [[ -f "$src" ]] || {
    echo "vnote-import: no scratchpad found at $src" >&2
    return 1
  }

  mkdir -p -- "$(dirname -- "$dest")"

  if [[ -e "$dest" ]]; then
    echo "vnote-import: destination exists: $dest" >&2
    return 1
  fi

  cp -- "$src" "$dest"
  printf 'Imported voice note -> %s\n' "$dest"
}

avfinfo() {
  echo "== AVF Debian =="
  uname -a
  echo
  free -h
  echo
  df -h / /mnt/shared 2>/dev/null || df -h /
  echo
  grep -E "^${USER}:" /etc/subuid /etc/subgid 2>/dev/null || true
}
