# Optional image-specific conveniences for AVF Debian.
#
# These are intentionally not part of the base profile. `pm`, `pms`, and
# `pmlan` are the stable Podman vocabulary; these helpers are only shorthand
# for recurring image choices.

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
