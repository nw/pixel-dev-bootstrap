# Shared Bash behavior for Termux and Pixel AVF Debian.

export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS="${LESS:--FRX}"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
export SRC="${SRC:-$HOME/src}"
export SCRATCH="${SCRATCH:-$HOME/scratch}"

# Non-interactive shells only need the environment above.
[[ $- != *i* ]] && return 0

# ---- SSH agent -------------------------------------------------------------

export PIXEL_AUTO_SSH_AGENT="${PIXEL_AUTO_SSH_AGENT:-1}"
PIXEL_SSH_ENV="$HOME/.ssh/agent-environment"

__pixel_start_ssh_agent() {
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  (umask 077; ssh-agent -s > "$PIXEL_SSH_ENV")
  # shellcheck disable=SC1090
  . "$PIXEL_SSH_ENV" >/dev/null
}

__pixel_ensure_ssh_agent() {
  if [[ -r "$PIXEL_SSH_ENV" ]]; then
    # shellcheck disable=SC1090
    . "$PIXEL_SSH_ENV" >/dev/null
  fi

  if [[ -z "${SSH_AGENT_PID:-}" ]] || ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
    __pixel_start_ssh_agent
  fi

  if [[ -f "$HOME/.ssh/id_ed25519" ]] && ! ssh-add -l >/dev/null 2>&1; then
    ssh-add "$HOME/.ssh/id_ed25519" >/dev/null 2>&1 || true
  fi
}

if [[ "$PIXEL_AUTO_SSH_AGENT" == "1" ]] && command -v ssh-agent >/dev/null 2>&1; then
  __pixel_ensure_ssh_agent
fi

# ---- Shell behavior --------------------------------------------------------

shopt -s histappend
shopt -s checkwinsize
shopt -s cmdhist
shopt -s globstar

HISTSIZE=20000
HISTFILESIZE=50000
HISTCONTROL=ignoreboth:erasedups

__pixel_history_sync() {
  history -a
  history -n
}

case ";${PROMPT_COMMAND:-};" in
  *';__pixel_history_sync;'*) ;;
  *) PROMPT_COMMAND="__pixel_history_sync${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac

PROMPT_DIRTRIM=3
PS1='\[\e[1;34m\]\w\[\e[0m\] \$ '

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi

# ---- Modern command conveniences ------------------------------------------

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons=auto'
  alias ll='eza -lah --icons=auto'
  alias la='eza -a --icons=auto'
  alias l='eza -CF --icons=auto'
  alias tree='eza --tree --icons=auto'
else
  alias ll='ls -lah'
  alias la='ls -A'
  alias l='ls -CF'
fi

# Keep `cat` boring and script-compatible. `bat` is installed under its own name.

if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
fi

alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'

alias gs='git status -sb'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --decorate --graph -20'

alias ports='ss -lntup 2>/dev/null || ss -lntu'

psg() {
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -af -- "$*"
  else
    ps -ef | grep -i -- "$*" | grep -v grep
  fi
}

# ---- Navigation and small helpers -----------------------------------------

csrc() { cd "$SRC" || return; }
cscratch() { cd "$SCRATCH" || return; }
cshared() { cd "${DEV_SHARED:?DEV_SHARED is not configured}" || return; }
cartifacts() { cd "${DEV_SHARED:?DEV_SHARED is not configured}/artifacts" || return; }

mkcd() {
  [[ $# -eq 1 ]] || { echo "usage: mkcd <directory>" >&2; return 2; }
  mkdir -p -- "$1" && cd -- "$1"
}

croot() {
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
  cd "$root" || return
}

serve() {
  local port="${1:-8000}"
  local python_cmd
  python_cmd="$(command -v python3 || command -v python || true)"
  [[ -n "$python_cmd" ]] || { echo "python/python3 is not installed" >&2; return 1; }
  "$python_cmd" -m http.server "$port" --bind 127.0.0.1
}

serve_lan() {
  local port="${1:-8000}"
  local python_cmd
  python_cmd="$(command -v python3 || command -v python || true)"
  [[ -n "$python_cmd" ]] || { echo "python/python3 is not installed" >&2; return 1; }
  "$python_cmd" -m http.server "$port" --bind 0.0.0.0
}

alias serve-lan='serve_lan'

devinfo() {
  printf 'platform: %s\n' "${PIXEL_PLATFORM:-unknown}"
  printf 'kernel:   '; uname -a
  printf 'home:     %s\n' "$HOME"
  printf 'shared:   %s\n' "${DEV_SHARED:-not configured}"

  local command_name
  for command_name in git ssh podman node npm python3 python nvim micro clang; do
    if command -v "$command_name" >/dev/null 2>&1; then
      printf '%-9s %s\n' "$command_name:" \
        "$("$command_name" --version 2>&1 | head -n 1)"
    fi
  done
}

# ---- Completion ------------------------------------------------------------

for completion_file in \
  "${PREFIX:-}/share/bash-completion/bash_completion" \
  "/usr/share/bash-completion/bash_completion"; do
  if [[ -r "$completion_file" ]] && ! shopt -oq posix; then
    # shellcheck disable=SC1090
    . "$completion_file"
    break
  fi
done
unset completion_file

# fzf packages do not wire interactive key bindings consistently across
# Termux and Debian. Source whichever packaged integration files exist.
if command -v fzf >/dev/null 2>&1; then
  for fzf_file in \
    "${PREFIX:-}/share/fzf/key-bindings.bash" \
    "${PREFIX:-}/share/fzf/completion.bash" \
    /usr/share/doc/fzf/examples/key-bindings.bash \
    /usr/share/doc/fzf/examples/completion.bash \
    /usr/share/bash-completion/completions/fzf; do
    [[ -r "$fzf_file" ]] && . "$fzf_file"
  done
  unset fzf_file
fi
