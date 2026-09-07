#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

printf 'Syntax checking shell files...\n'
while IFS= read -r -d '' file; do
  bash -n "$file"
done < <(
  find "$ROOT_DIR" -type f \
    \( -name '*.sh' -o -name '*.bash' -o -path '*/bin/*' -o -path '*/shortcuts/*' \) -print0
)

termux_home="$(mktemp -d)"
avf_home="$(mktemp -d)"
test_root="$(mktemp -d)"
cleanup() { rm -rf "$termux_home" "$avf_home" "$test_root"; }
trap cleanup EXIT

printf 'Testing one-line bootstrap entrypoint...\n'
remote_home="$test_root/remote-home"
remote_bin="$test_root/remote-bin"
remote_shared="$remote_home/storage/shared"
remote_log="$test_root/remote-install.log"
mkdir -p "$remote_home" "$remote_bin" "$remote_shared"
cat > "$remote_bin/git" <<'EOF_REMOTE_GIT'
#!/usr/bin/env bash
set -e
if [[ "$1" == "clone" ]]; then
  target="${@: -1}"
  mkdir -p "$target/.git"
  cat > "$target/install.sh" <<'EOF_REMOTE_INSTALL'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${REMOTE_INSTALL_LOG:?}"
EOF_REMOTE_INSTALL
  chmod +x "$target/install.sh"
  exit 0
fi
if [[ "$1" == "-C" ]]; then
  dir="$2"; shift 2
  case "$1" in
    config) exit 0 ;;
    remote) printf '%s\n' "${PIXEL_DEV_BOOTSTRAP_REPO:-https://github.com/nw/pixel-dev-bootstrap.git}"; exit 0 ;;
    status) exit 0 ;;
    pull) exit 0 ;;
  esac
fi
exit 0
EOF_REMOTE_GIT
chmod +x "$remote_bin/git"
TERMUX_VERSION=test PREFIX=/data/data/com.termux/files/usr \
  HOME="$remote_home" PATH="$remote_bin:$PATH" \
  REMOTE_INSTALL_LOG="$remote_log" \
  bash "$ROOT_DIR/bootstrap.sh" --no-upgrade >/dev/null
test -d "$remote_shared/dev/pixel-dev-bootstrap/.git"
test -f "$remote_shared/dev/pixel-dev-bootstrap/install.sh"
grep -qx -- '--no-upgrade' "$remote_log"

printf 'Testing Termux configuration install...\n'
HOME="$termux_home" \
  bash "$ROOT_DIR/install.sh" --termux --configs-only --no-ssh-key >/dev/null

test -f "$termux_home/.bashrc"
test -f "$termux_home/.termux/termux.properties"
test -x "$termux_home/bin/clipcopy"
test -x "$termux_home/bin/reseed"
test -x "$termux_home/bin/ssh-seal"
test -x "$termux_home/bin/recipe"
test ! -e "$termux_home/bin/box"
test ! -e "$termux_home/bin/avf-sync"
test -f "$termux_home/.local/share/pixel-dev-bootstrap/recipe-catalog/vnote/recipe.sh"
test ! -e "$termux_home/.local/share/pixel-dev-bootstrap/recipes/vnote"
test ! -e "$termux_home/bin/vnote"
grep -q 'common.bash' "$termux_home/.bashrc"
grep -q 'recipes.d' "$termux_home/.bashrc"

# Catalog browsing must be inert: literal metadata is readable without sourcing
# recipe code or leaking its top-level side effects into list/info operations.
sidefx_recipe="$termux_home/.local/share/pixel-dev-bootstrap/recipe-catalog/sidefx"
sidefx_marker="$test_root/recipe-list-side-effect"
mkdir -p "$sidefx_recipe"
cat > "$sidefx_recipe/recipe.sh" <<'EOF_SIDEFX'
#!/usr/bin/env bash
recipe_name="sidefx"
recipe_description="Inert catalog metadata test"
touch "${RECIPE_LIST_SIDE_EFFECT:?}"
sidefx_helper() { :; }
EOF_SIDEFX
recipe_list_output="$(
  HOME="$termux_home" \
  RECIPE_LIST_SIDE_EFFECT="$sidefx_marker" \
    "$termux_home/bin/recipe" list
)"
[[ "$recipe_list_output" == *'sidefx'*'Inert catalog metadata test'* ]]
test ! -e "$sidefx_marker"
recipe_info_output="$(
  HOME="$termux_home" \
  RECIPE_LIST_SIDE_EFFECT="$sidefx_marker" \
    "$termux_home/bin/recipe" info sidefx
)"
[[ "$recipe_info_output" == *'sidefx - Inert catalog metadata test'* ]]
test ! -e "$sidefx_marker"
rm -rf -- "$sidefx_recipe"

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
test -x "$avf_home/bin/box"
test -x "$avf_home/bin/avf-sync"
test ! -e "$avf_home/.local/share/pixel-dev-bootstrap/recipe-catalog"
test -f "$avf_home/.config/pixel-dev-bootstrap/shell/podman.bash"
test ! -e "$avf_home/.config/pixel-dev-bootstrap/shell/boxes.bash"
grep -q 'runtime = "crun"' "$avf_home/.config/containers/containers.conf"
grep -q 'driver = "overlay"' "$avf_home/.config/containers/storage.conf"
grep -q 'mount_program = "/usr/bin/fuse-overlayfs"' "$avf_home/.config/containers/storage.conf"

printf 'Testing AVF durable home overlay...\n'
avf_overlay_shared="$test_root/avf-overlay-shared"
avf_overlay="$avf_overlay_shared/configs/avf/home"
mkdir -p \
  "$avf_overlay/.codex" \
  "$avf_overlay/.config/example" \
  "$avf_overlay/bin" \
  "$avf_overlay/.ssh"
printf 'host contract\n' > "$avf_overlay/.codex/AGENTS.md"
printf 'local config\n' > "$avf_overlay/.config/example/config"
printf '#!/usr/bin/env bash\nprintf "overlay tool\\n"\n' > "$avf_overlay/bin/overlay-tool"
chmod 0644 "$avf_overlay/bin/overlay-tool"
printf 'must not copy\n' > "$avf_overlay/.ssh/id_ed25519"
printf 'preserve me\n' > "$avf_home/unrelated.txt"

HOME="$avf_home" DEV_SHARED="$avf_overlay_shared" \
  "$avf_home/bin/avf-sync" --dry-run >/dev/null
test ! -e "$avf_home/.codex/AGENTS.md"

HOME="$avf_home" DEV_SHARED="$avf_overlay_shared" \
  "$avf_home/bin/avf-sync" >/dev/null
grep -qx 'host contract' "$avf_home/.codex/AGENTS.md"
grep -qx 'local config' "$avf_home/.config/example/config"
test -x "$avf_home/bin/overlay-tool"
test ! -e "$avf_home/.ssh/id_ed25519"
grep -qx 'preserve me' "$avf_home/unrelated.txt"

# Shared voice scratch state should be promoted into AVF project state only by
# explicit copy, with parent creation and no silent overwrite.
printf 'Testing AVF vnote-import helper...\n'
vnote_shared="$test_root/vnote-shared"
vnote_project="$test_root/vnote-project"
mkdir -p "$vnote_shared" "$vnote_project"
printf '%s\n' '# voice scratch' 'captured thought' > "$vnote_shared/voice-scratchpad.md"
(
  export HOME="$avf_home" DEV_SHARED="$vnote_shared"
  # shellcheck disable=SC1090
  source "$avf_home/.config/pixel-dev-bootstrap/shell/platform.bash"
  cd "$vnote_project"
  vnote-import notes/idea.md >/dev/null
)
cmp -s "$vnote_shared/voice-scratchpad.md" "$vnote_project/notes/idea.md"
if (
  export HOME="$avf_home" DEV_SHARED="$vnote_shared"
  # shellcheck disable=SC1090
  source "$avf_home/.config/pixel-dev-bootstrap/shell/platform.bash"
  cd "$vnote_project"
  vnote-import notes/idea.md >/dev/null 2>&1
); then
  echo "vnote-import unexpectedly overwrote an existing destination" >&2
  exit 1
fi

# Podman helper parser qualification. Stub podman and inspect argv.
# shellcheck disable=SC1090
source "$avf_home/.config/pixel-dev-bootstrap/shell/podman.bash"
podman() { printf '<%s>\n' "$@"; }
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


# Named AVF boxes are data-only definitions over Podman. Registry aliases,
# auth, runtime env overrides, mounts, and repeated ports must map cleanly.
printf 'Testing AVF box helper...\n'
box_shared="$test_root/box-shared"
box_fake_bin="$test_root/box-fake-bin"
mkdir -p "$box_shared/configs/boxes.d" "$box_shared/artifacts" "$box_fake_bin"
cat > "$box_shared/configs/registries.conf" <<'EOF_REGISTRIES'
public=docker.io/library
private=ghcr.io/example-org
EOF_REGISTRIES
cat > "$box_shared/configs/boxes.d/esp.box" <<EOF_BOX
# Data only: never sourced.
description=ESP-IDF toolchain test
image=private:pulse-esp-idf:5.4.4
workdir=/work
shell=/bin/bash
env=IDF_TARGET=esp32s3
env=SDKMODE=field
mount=$box_shared/artifacts:/artifacts
EOF_BOX
cat > "$box_fake_bin/podman" <<'EOF_PODMAN'
#!/usr/bin/env bash
if [[ "${1:-}" == "login" && "${2:-}" == "--get-login" ]]; then
  case "${3:-}" in
    ghcr.io) printf 'pixel-user\n'; exit 0 ;;
    *) exit 1 ;;
  esac
fi
printf '<%s>\n' "$@"
EOF_PODMAN
chmod +x "$box_fake_bin/podman"

box_env=(
  HOME="$avf_home"
  DEV_SHARED="$box_shared"
  PATH="$box_fake_bin:$avf_home/bin:$PATH"
)

out="$(env "${box_env[@]}" "$avf_home/bin/box" list)"
[[ "$out" == *'esp'*'ghcr.io/example-org/pulse-esp-idf:5.4.4'*'ESP-IDF toolchain test'* ]]

out="$(env "${box_env[@]}" "$avf_home/bin/box" info esp)"
[[ "$out" == *'workdir:     /work'* ]]
[[ "$out" == *'env:         IDF_TARGET=esp32s3'* ]]
[[ "$out" == *"mount:       $box_shared/artifacts:/artifacts"* ]]

out="$(env "${box_env[@]}" "$avf_home/bin/box" pull esp)"
[[ "$out" == *'<pull>'*'<ghcr.io/example-org/pulse-esp-idf:5.4.4>'* ]]

out="$(env "${box_env[@]}" "$avf_home/bin/box" run esp "$test_root" \
  -p 3000 -p 8080:80 \
  -e IDF_TARGET=esp32c6 -e EXTRA=yes \
  -v "$test_root:/extra:ro" \
  --bind 0.0.0.0 -- idf.py build)"
[[ "$out" == *'<--publish>'*'<0.0.0.0:3000:3000>'* ]]
[[ "$out" == *'<0.0.0.0:8080:80>'* ]]
[[ "$out" == *'<--env>'*'<IDF_TARGET=esp32s3>'* ]]
[[ "$out" == *'<IDF_TARGET=esp32c6>'* ]]
[[ "$out" == *'<EXTRA=yes>'* ]]
[[ "$out" == *"<$box_shared/artifacts:/artifacts>"* ]]
[[ "$out" == *"<$test_root:/extra:ro>"* ]]
[[ "$out" == *'<ghcr.io/example-org/pulse-esp-idf:5.4.4>'*'<idf.py>'*'<build>'* ]]

out="$(env "${box_env[@]}" "$avf_home/bin/box" shell esp "$test_root")"
[[ "$out" == *'<ghcr.io/example-org/pulse-esp-idf:5.4.4>'*'</bin/bash>'* ]]

out="$(env "${box_env[@]}" "$avf_home/bin/box" registries)"
[[ "$out" == *'private'*'ghcr.io/example-org'*'ghcr.io'* ]]

out="$(env "${box_env[@]}" "$avf_home/bin/box" login private)"
[[ "$out" == *'<login>'*'<ghcr.io>'* ]]
out="$(env "${box_env[@]}" "$avf_home/bin/box" logout private)"
[[ "$out" == *'<logout>'*'<ghcr.io>'* ]]
out="$(env "${box_env[@]}" "$avf_home/bin/box" auth)"
[[ "$out" == *'private'*'ghcr.io'*'pixel-user'* ]]

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
test -f "$termux_home/.shortcuts/vnote"
test ! -L "$termux_home/.shortcuts/vnote"
test -x "$termux_home/.shortcuts/vnote"
grep -q '\$HOME/bin/vnote' "$termux_home/.shortcuts/vnote"
grep -q 'install -y termux-api ffmpeg' "$pkg_log"

# A failed stage copy must not disturb the working recipe or install packages.
real_cp="$(command -v cp)"
cat > "$fake_bin/cp" <<EOF_CP
#!/usr/bin/env bash
last="\${*: -1}"
if [[ "\${RECIPE_TEST_FAIL_STAGE:-0}" == "1" && "\$last" == */.vnote.new.* ]]; then
  exit 74
fi
exec "$real_cp" "\$@"
EOF_CP
chmod +x "$fake_bin/cp"
: > "$pkg_log"
if TERMUX_VERSION=test PREFIX=/data/data/com.termux/files/usr \
  HOME="$termux_home" PATH="$fake_bin:$termux_home/bin:$PATH" \
  RECIPE_TEST_PKG_LOG="$pkg_log" RECIPE_TEST_FAIL_STAGE=1 \
  "$termux_home/bin/recipe" install vnote >/dev/null 2>&1; then
  echo "recipe install unexpectedly succeeded after staged-copy failure" >&2
  exit 1
fi
test -d "$termux_home/.local/share/pixel-dev-bootstrap/recipes/vnote"
test -L "$termux_home/bin/vnote"
test "$(readlink -f "$termux_home/bin/vnote")" = \
  "$termux_home/.local/share/pixel-dev-bootstrap/recipes/vnote/bin/vnote"
test -f "$termux_home/.shortcuts/vnote"
test -x "$termux_home/.shortcuts/vnote"
test ! -s "$pkg_log"
test -z "$(find "$termux_home/.local/share/pixel-dev-bootstrap/recipes" \
  -maxdepth 1 -name '.vnote.new.*' -print -quit)"
rm -f -- "$fake_bin/cp"

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

# Cancelling native STT (successful empty result) is a stop, not a request to
# fall through into an unavailable local Whisper stack.
cat > "$fake_bin/termux-speech-to-text" <<'EOF_STT_CANCEL'
#!/usr/bin/env bash
exit 0
EOF_STT_CANCEL
chmod +x "$fake_bin/termux-speech-to-text"
cancelled_notes="$test_root/cancelled-voice.md"
cancel_output="$(
  TERMUX_VERSION=test PREFIX=/data/data/com.termux/files/usr \
  HOME="$termux_home" PATH="$fake_bin:$termux_home/bin:$PATH" \
  DEV_SHARED="$test_root" VNOTE_NOTES_FILE="$cancelled_notes" \
    "$termux_home/bin/vnote"
)"
[[ "$cancel_output" == *'no speech captured; no note recorded'* ]]
test ! -e "$cancelled_notes"

# Removal owns recipe files/links only; it must not run pkg removal.
: > "$pkg_log"
TERMUX_VERSION=test PREFIX=/data/data/com.termux/files/usr \
  HOME="$termux_home" PATH="$fake_bin:$termux_home/bin:$PATH" \
  RECIPE_TEST_PKG_LOG="$pkg_log" \
  "$termux_home/bin/recipe" remove vnote >/dev/null
test ! -e "$termux_home/bin/vnote"
test ! -e "$termux_home/.shortcuts/vnote"
test ! -e "$termux_home/.local/share/pixel-dev-bootstrap/recipes/vnote"
test ! -s "$pkg_log"

# Recipe removal must not delete a shortcut after the user has modified it.
TERMUX_VERSION=test PREFIX=/data/data/com.termux/files/usr \
  HOME="$termux_home" PATH="$fake_bin:$termux_home/bin:$PATH" \
  RECIPE_TEST_PKG_LOG="$pkg_log" \
  "$termux_home/bin/recipe" install vnote >/dev/null
printf '# user customization\n' >> "$termux_home/.shortcuts/vnote"
TERMUX_VERSION=test PREFIX=/data/data/com.termux/files/usr \
  HOME="$termux_home" PATH="$fake_bin:$termux_home/bin:$PATH" \
  RECIPE_TEST_PKG_LOG="$pkg_log" \
  "$termux_home/bin/recipe" remove vnote >/dev/null
test -f "$termux_home/.shortcuts/vnote"
grep -q 'user customization' "$termux_home/.shortcuts/vnote"
rm -f -- "$termux_home/.shortcuts/vnote"

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
