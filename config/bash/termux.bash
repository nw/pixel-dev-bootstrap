export PIXEL_PLATFORM="termux"
export DEV_SHARED="${DEV_SHARED:-$HOME/storage/shared/dev}"
export DOWNLOADS="${DOWNLOADS:-$HOME/storage/downloads}"

mkdir -p "$HOME/src" "$HOME/scratch" "$HOME/bin" 2>/dev/null || true

# Android/shared-storage bridge. Re-run termux-setup-storage if this is absent.
downloads() {
  cd "$DOWNLOADS" || {
    echo "Termux shared storage is unavailable. Run: termux-setup-storage" >&2
    return 1
  }
}

wake() {
  command -v termux-wake-lock >/dev/null 2>&1 || {
    echo "termux-wake-lock is unavailable" >&2
    return 1
  }
  termux-wake-lock
  echo "Termux wake lock acquired."
}

unwake() {
  command -v termux-wake-unlock >/dev/null 2>&1 || {
    echo "termux-wake-unlock is unavailable" >&2
    return 1
  }
  termux-wake-unlock
  echo "Termux wake lock released."
}

aopen() {
  command -v termux-open >/dev/null 2>&1 || {
    echo "termux-open is unavailable" >&2
    return 1
  }
  termux-open "$@"
}
