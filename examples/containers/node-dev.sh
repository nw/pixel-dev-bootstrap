#!/usr/bin/env bash
set -Eeuo pipefail

project_dir="${1:-$PWD}"
port="${2:-3000}"

podman run --rm -it \
  --pull=missing \
  --userns=keep-id \
  --mount "type=bind,src=$(realpath -m -- "$project_dir"),dst=/work" \
  --workdir /work \
  --publish "127.0.0.1:${port}:${port}" \
  docker.io/library/node:24-bookworm \
  bash
