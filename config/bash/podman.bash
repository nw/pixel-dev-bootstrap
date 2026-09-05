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

# Deliberately destructive cleanup for a disposable AVF container store.
# Removes every unused container, image, volume, and build cache.
pdeepclean() {
  podman system prune -a --volumes --build -f
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
  pm node:24-bookworm . -- npm test
  pm node:24-bookworm -- npm test
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
    # Deliberately fully qualify short official images so Podman never needs
    # to stop for a short-name resolution prompt during a quick phone session.
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

  # Parse the command separator before assigning optional positional fields.
  # This keeps all of these forms valid:
  #   pm image
  #   pm image -- command
  #   pm image dir -- command
  #   pm image dir port -- command
  local -a positional=() command=()
  local seen_separator=0 argument
  for argument in "$@"; do
    if ((seen_separator)); then
      command+=("$argument")
    elif [[ "$argument" == "--" ]]; then
      seen_separator=1
    else
      positional+=("$argument")
    fi
  done

  ((${#positional[@]} >= 1 && ${#positional[@]} <= 3)) || {
    __pm_usage
    return 2
  }

  local image directory port mapping
  image="$(__pm_image "${positional[0]}")"
  directory="$(realpath -m -- "${positional[1]:-$PWD}")"
  port="${positional[2]:-}"

  [[ -d "$directory" ]] || {
    echo "pm: directory does not exist: $directory" >&2
    return 2
  }

  local -a arguments=(
    run --rm -it
    --init
    --pull=missing
    --userns=keep-id
    --mount "type=bind,src=$directory,dst=/work"
    --workdir /work
  )

  mapping="$(__pm_port "$port")"
  [[ -n "$mapping" ]] && arguments+=(--publish "$mapping")

  [[ -n "${TERM:-}" ]] && arguments+=(--env "TERM=$TERM")
  [[ -n "${COLORTERM:-}" ]] && arguments+=(--env "COLORTERM=$COLORTERM")

  if ((${#command[@]})); then
    podman "${arguments[@]}" "$image" "${command[@]}"
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
