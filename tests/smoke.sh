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
HOME="$termux_home" PIXEL_AUTO_SSH_AGENT=0 \
  bash --noprofile --norc -ic '
    source "$HOME/.bashrc"
    test "$PIXEL_PLATFORM" = termux
    type csrc >/dev/null
    command -v clipcopy >/dev/null
  ' >/dev/null 2>&1

echo "Testing AVF configuration install..."
HOME="$avf_home" USER=tester \
  bash "$ROOT_DIR/install.sh" --avf --configs-only --no-ssh-key --no-podman >/dev/null
HOME="$avf_home" USER=tester PIXEL_AUTO_SSH_AGENT=0 \
  bash --noprofile --norc -ic '
    source "$HOME/.bashrc"
    test "$PIXEL_PLATFORM" = avf
    type pm >/dev/null
    type nodebox >/dev/null
    command -v clipcopy >/dev/null
  ' >/dev/null 2>&1

if command -v shellcheck >/dev/null 2>&1; then
  echo "Running ShellCheck..."
  # shellcheck disable=SC2046
  shellcheck -x $(find "$ROOT_DIR" -type f \
    \( -name '*.sh' -o -name '*.bash' -o -path '*/bin/*' \))
fi

echo "Smoke test: PASS"
