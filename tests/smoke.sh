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
test -x "$termux_home/bin/recipe"
test -f "$termux_home/.local/share/pixel-dev-bootstrap/recipe-catalog/vnote/recipe.sh"
test ! -e "$termux_home/.local/share/pixel-dev-bootstrap/recipes/vnote"
test ! -e "$termux_home/bin/vnote"
grep -q 'common.bash' "$termux_home/.bashrc"
grep -q 'recipes.d' "$termux_home/.bashrc"

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
test ! -e "$avf_home/bin/recipe"
test ! -e "$avf_home/.local/share/pixel-dev-bootstrap/recipe-catalog"
test -f "$avf_home/.config/pixel-dev-bootstrap/shell/podman.bash"
test ! -e "$avf_home/.config/pixel-dev-bootstrap/shell/boxes.bash"
grep -q 'runtime = "crun"' "$avf_home/.config/containers/containers.conf"
grep -q 'driver = "overlay"' "$avf_home/.config/containers/storage.conf"
grep -q 'mount_program = "/usr/bin/fuse-overlayfs"' "$avf_home/.config/containers/storage.conf"

# Image-specific helpers are opt-in and cleanly removable by returning to base.
HOME="$avf_home" USER=tester \
  bash "$ROOT_DIR/install.sh" --avf --configs-only --no-ssh-key --no-podman --with-boxes >/dev/null
test -f "$avf_home/.config/pixel-dev-bootstrap/shell/boxes.bash"
grep -q '^nodebox()' "$avf_home/.config/pixel-dev-bootstrap/shell/boxes.bash"
HOME="$avf_home" USER=tester \
  bash "$ROOT_DIR/install.sh" --avf --configs-only --no-ssh-key --no-podman --base >/dev/null
test ! -e "$avf_home/.config/pixel-dev-bootstrap/shell/boxes.bash"

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

# Termux recipes are opt-in, copy payloads into private storage, and never
# remove shared package dependencies. Stub pkg/dpkg/Termux commands so the
# lifecycle can be exercised without Android.
printf 'Testing Termux recipe lifecycle...\n'
fake_bin="$test_root/fake-bin"
mkdir -p "$fake_bin"
cat > "$fake_bin/dpkg" <<'EOF_DPKG'
#!/usr/bin/env bash
exit 1
EOF_DPKG
cat > "$fake_bin/pkg" <<'EOF_PKG'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${RECIPE_TEST_PKG_LOG:?}"
exit 0
EOF_PKG
chmod +x "$fake_bin/dpkg" "$fake_bin/pkg"

pkg_log="$test_root/pkg.log"
: > "$pkg_log"
TERMUX_VERSION=test PREFIX=/data/data/com.termux/files/usr \
  HOME="$termux_home" PATH="$fake_bin:$termux_home/bin:$PATH" \
  RECIPE_TEST_PKG_LOG="$pkg_log" \
  "$termux_home/bin/recipe" install vnote >/dev/null

test -d "$termux_home/.local/share/pixel-dev-bootstrap/recipes/vnote"
test -L "$termux_home/bin/vnote"
test "$(readlink -f "$termux_home/bin/vnote")" = \
  "$termux_home/.local/share/pixel-dev-bootstrap/recipes/vnote/bin/vnote"
grep -q 'install -y termux-api ffmpeg' "$pkg_log"

# Native-STT fast path should append a Markdown note without needing Whisper.
cat > "$fake_bin/termux-speech-to-text" <<'EOF_STT'
#!/usr/bin/env bash
printf 'hello from vnote\n'
EOF_STT
chmod +x "$fake_bin/termux-speech-to-text"
notes="$test_root/voice.md"
TERMUX_VERSION=test PREFIX=/data/data/com.termux/files/usr \
  HOME="$termux_home" PATH="$fake_bin:$termux_home/bin:$PATH" \
  DEV_SHARED="$test_root" VNOTE_NOTES_FILE="$notes" \
  "$termux_home/bin/vnote" >/dev/null
grep -q -- '--- Voice Note \[' "$notes"
grep -q 'hello from vnote' "$notes"

# Removal owns recipe files/links only; it must not run pkg removal.
: > "$pkg_log"
TERMUX_VERSION=test PREFIX=/data/data/com.termux/files/usr \
  HOME="$termux_home" PATH="$fake_bin:$termux_home/bin:$PATH" \
  RECIPE_TEST_PKG_LOG="$pkg_log" \
  "$termux_home/bin/recipe" remove vnote >/dev/null
test ! -e "$termux_home/bin/vnote"
test ! -e "$termux_home/.local/share/pixel-dev-bootstrap/recipes/vnote"
test ! -s "$pkg_log"

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
