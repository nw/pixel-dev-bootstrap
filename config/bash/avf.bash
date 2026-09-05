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
