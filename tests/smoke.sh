#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

printf 'Syntax checking shell files...\n'
while IFS= read -r -d '' file; do
  bash -n "$file"
done < <(
  find "$ROOT_DIR" -type f \
    \( -name '*.sh' -o -name '*.bash' -o -path '*/bin/*' \) -print0
)

termux_home="$(mktemp -d)"
avf_home="$(mktemp -d)"
test_root="$(mktemp -d)"
cleanup() { rm -rf "$termux_home" "$avf_home" "$test_root"; }
trap cleanup EXIT

printf 'Testing Termux configuration install...\n'
HOME="$termux_home" \
  bash "$ROOT_DIR/install.sh" --termux --configs-only --no-ssh-key >/dev/null

test -f "$termux_home/.bashrc"
test -f "$termux_home/.termux/termux.properties"
test -x "$termux_home/bin/clipcopy"
test -x "$termux_home/bin/reseed"
test -x "$termux_home/bin/ssh-seal"
grep -q 'common.bash' "$termux_home/.bashrc"

# Config-only reruns seed defaults but preserve deliberate global Git choices.
HOME="$termux_home" git config --global core.editor micro
HOME="$termux_home" \
  bash "$ROOT_DIR/install.sh" --termux --configs-only --no-ssh-key >/dev/null
test "$(HOME="$termux_home" git config --global --get core.editor)" = "micro"

printf 'Testing AVF configuration install...\n'
HOME="$avf_home" USER=tester \
  bash "$ROOT_DIR/install.sh" --avf --configs-only --no-ssh-key --no-podman >/dev/null

test -f "$avf_home/.bashrc"
test -x "$avf_home/bin/clipcopy"
test -x "$avf_home/bin/reseed"
test -x "$avf_home/bin/ssh-restore"
test -f "$avf_home/.config/pixel-dev-bootstrap/shell/podman.bash"
grep -q 'runtime = "crun"' "$avf_home/.config/containers/containers.conf"
grep -q 'driver = "overlay"' "$avf_home/.config/containers/storage.conf"
grep -q 'mount_program = "/usr/bin/fuse-overlayfs"' "$avf_home/.config/containers/storage.conf"

# Podman helper parser qualification. Stub podman and inspect argv.
# shellcheck disable=SC1090
source "$avf_home/.config/pixel-dev-bootstrap/shell/podman.bash"
podman() { printf '<%s>\n' "$@"; }
export -f podman
cd "$test_root"

out="$(pm node:24)"
[[ "$out" == *'<--init>'* ]]
[[ "$out" == *'<docker.io/library/node:24>'* ]]
[[ "$out" != *'<--publish>'* ]]

out="$(pm node:24 -- npm test)"
[[ "$out" == *'<npm>'*'<test>'* ]]
[[ "$out" != *'<--publish>'* ]]

out="$(pm node:24 . -- npm test)"
[[ "$out" == *'<npm>'*'<test>'* ]]
[[ "$out" != *'<--publish>'* ]]

out="$(pm node:24 . 3000 -- npm test)"
[[ "$out" == *'<--publish>'*'<127.0.0.1:3000:3000>'* ]]
[[ "$out" == *'<npm>'*'<test>'* ]]

out="$(pms node:24 . 3000)"
[[ "$out" == *'</bin/sh>'*'<-lc>'* ]]
[[ "$out" == *'<127.0.0.1:3000:3000>'* ]]

# reseed clones missing repos and preserves existing working trees.
manifest="$test_root/repos.txt"
bare="$test_root/example.git"
git init --bare -q "$bare"
printf '%s\n' "$bare" > "$manifest"
SRC="$test_root/src" DEV_SHARED="$test_root/shared" "$avf_home/bin/reseed" "$manifest" >/dev/null
test -d "$test_root/src/example/.git"
marker="$test_root/src/example/preserve-me"
touch "$marker"
SRC="$test_root/src" DEV_SHARED="$test_root/shared" "$avf_home/bin/reseed" "$manifest" >/dev/null
test -e "$marker"

if command -v shellcheck >/dev/null 2>&1; then
  printf 'Running ShellCheck...\n'
  # shellcheck disable=SC2046
  shellcheck -x $(find "$ROOT_DIR" -type f \
    \( -name '*.sh' -o -name '*.bash' -o -path '*/bin/*' \))
fi

printf 'Smoke test: PASS\n'
