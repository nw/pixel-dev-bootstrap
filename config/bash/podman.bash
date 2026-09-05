# Rootless Podman conveniences for the AVF Debian guest.

alias p='podman'
alias pi='podman images'
alias pps='podman ps'
alias ppa='podman ps --all'
alias pv='podman volume ls'
alias pn='podman network ls'
alias pstats='podman stats'

pclean() {
  podman system prune "$@"
}

__pm_usage() {
  cat >&2 <<'USAGE'
usage: pm <image> [directory] [port] [-- command ...]

  image      OCI image. Short official names are resolved through docker.io.
  directory  Bind-mounted at /work. Defaults to the current directory.
  port       "3000" maps 127.0.0.1:3000:3000.
             "8080:3000" maps 127.0.0.1:8080:3000.
             "-" or an empty value creates no mapping.

Examples:
  pm node:24-bookworm
  pm node:24-bookworm . 3000
  pm node:24-bookworm ~/src/app 8080:3000 -- npm test
  PM_BIND_ADDRESS=0.0.0.0 pm node:24-bookworm . 3000
USAGE
}

__pm_image() {
  local image="$1"
  if [[ "$image" == */* ]]; then
    printf '%s\n' "$image"
  else
    printf 'docker.io/library/%s\n' "$image"
  fi
}

__pm_port() {
  local specification="$1"
  local bind_address="${PM_BIND_ADDRESS:-127.0.0.1}"

  case "$specification" in
    ""|-) return 0 ;;
    *:*:*) printf '%s\n' "$specification" ;;
    *:*) printf '%s:%s\n' "$bind_address" "$specification" ;;
    *) printf '%s:%s:%s\n' "$bind_address" "$specification" "$specification" ;;
  esac
}

pm() {
  (($# >= 1)) || { __pm_usage; return 2; }
  command -v podman >/dev/null 2>&1 || {
    echo "podman is not installed" >&2
    return 127
  }

  local image directory port mapping
  image="$(__pm_image "$1")"
  directory="${2:-$PWD}"
  port="${3:-}"

  shift || true
  (($#)) && shift || true
  (($#)) && shift || true
  [[ "${1:-}" == "--" ]] && shift

  directory="$(realpath -m -- "$directory")"
  [[ -d "$directory" ]] || {
    echo "pm: directory does not exist: $directory" >&2
    return 2
  }

  local -a arguments=(
    run --rm -it
    --pull=missing
    --userns=keep-id
    --mount "type=bind,src=$directory,dst=/work"
    --workdir /work
  )

  mapping="$(__pm_port "$port")"
  [[ -n "$mapping" ]] && arguments+=(--publish "$mapping")

  [[ -n "${TERM:-}" ]] && arguments+=(--env "TERM=$TERM")
  [[ -n "${COLORTERM:-}" ]] && arguments+=(--env "COLORTERM=$COLORTERM")

  if (($#)); then
    podman "${arguments[@]}" "$image" "$@"
  else
    podman "${arguments[@]}" "$image"
  fi
}

pms() {
  (($# >= 1)) || { __pm_usage; return 2; }
  local image="$1"
  local directory="${2:-$PWD}"
  local port="${3:-}"
  pm "$image" "$directory" "$port" -- /bin/sh -lc \
    'if command -v bash >/dev/null 2>&1; then exec bash; else exec sh; fi'
}

pmlan() {
  PM_BIND_ADDRESS=0.0.0.0 pm "$@"
}

nodebox() {
  local directory="${1:-$PWD}"
  local port="${2:-}"
  local tag="${3:-24-bookworm}"
  pms "node:$tag" "$directory" "$port"
}

pybox() {
  local directory="${1:-$PWD}"
  local port="${2:-}"
  local tag="${3:-3.13-bookworm}"
  pms "python:$tag" "$directory" "$port"
}

debbox() {
  local directory="${1:-$PWD}"
  local tag="${2:-bookworm}"
  pms "debian:$tag" "$directory" ""
}
