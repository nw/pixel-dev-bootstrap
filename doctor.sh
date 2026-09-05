#!/usr/bin/env bash
set -Eeuo pipefail

if command -v dev-doctor >/dev/null 2>&1; then
  exec dev-doctor
fi

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$ROOT_DIR/bin/dev-doctor"
