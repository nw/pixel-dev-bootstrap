#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Checking Bash syntax..."
while IFS= read -r -d '' file; do
  bash -n "$file"
done < <(
  find "$ROOT_DIR" -type f \
    \( -name '*.sh' -o -name '*.bash' -o -path '*/bin/*' \) -print0
)

termux_home="$(mktemp -d)"
avf_home="$(mktemp -d)"
cleanup() { rm -rf "$termux_home" "$avf_home"; }
trap cleanup EXIT

echo "Testing Termux configuration install..."
HOME="$termux_home" \
  bash "$ROOT_DIR/install.sh" --termux --configs-only --no-ssh-key >/dev/null

test -f "$termux_home/.bashrc"
test -f "$termux_home/.termux/termux.properties"
test -x "$termux_home/bin/clipcopy"
grep -q 'common.bash' "$termux_home/.bashrc"

echo "Testing AVF configuration install..."
HOME="$avf_home" USER=tester \
  bash "$ROOT_DIR/install.sh" --avf --configs-only --no-ssh-key --no-podman >/dev/null

test -f "$avf_home/.bashrc"
test -x "$avf_home/bin/clipcopy"
test -f "$avf_home/.config/pixel-dev-bootstrap/shell/podman.bash"
grep -q 'runtime = "crun"' "$avf_home/.config/containers/containers.conf"
grep -q 'driver = "overlay"' "$avf_home/.config/containers/storage.conf"
grep -q 'mount_program = "/usr/bin/fuse-overlayfs"' "$avf_home/.config/containers/storage.conf"

# The Podman helper file is safe to source non-interactively.
# shellcheck disable=SC1090
source "$avf_home/.config/pixel-dev-bootstrap/shell/podman.bash"
type pm >/dev/null
type nodebox >/dev/null
type pdeepclean >/dev/null

if command -v shellcheck >/dev/null 2>&1; then
  echo "Running ShellCheck..."
  # shellcheck disable=SC2046
  shellcheck -x $(find "$ROOT_DIR" -type f \
    \( -name '*.sh' -o -name '*.bash' -o -path '*/bin/*' \))
fi

echo "Smoke test: PASS"
