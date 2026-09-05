# vnote recipe

A deliberately small Termux/Android integration for appending spoken thoughts to
Markdown from the CLI.

```bash
recipe install vnote
vnote
```

`vnote` first uses Android speech-to-text through Termux:API. If that returns no
text, it can fall back to a local `whisper-cli` workflow.

## What the recipe installs

Termux packages ensured on install:

```text
termux-api
ffmpeg
```

The **Termux:API Android companion app is still required** and must come from the
same signing/distribution source as Termux. A recipe can install Termux packages;
it cannot install or own Android applications.

The recipe deliberately does **not** install a Whisper engine or model. Android
STT is useful by itself, while a local Whisper stack is a larger personal choice.
If wanted, put `whisper-cli` on `PATH` and set:

```bash
export VNOTE_MODEL="$HOME/models/ggml-tiny.en.bin"
```

## Usage

```bash
vnote             # Android STT first; local fallback max 120s
vnote 30          # local fallback max 30s
vnote 0           # local fallback has no time ceiling; Enter stops it
```

Local fallback ends when **Enter** is pressed or the ceiling expires.

Useful overrides:

```bash
export VNOTE_NOTES_FILE="$DEV_SHARED/voice-scratchpad.md"
export VNOTE_MAX_SECONDS=120
export VNOTE_MODEL="$HOME/models/ggml-tiny.en.bin"
export VNOTE_MODE=auto       # auto | native | local
```

The default notes path is:

```text
${DEV_SHARED:-$HOME/scratch}/voice-scratchpad.md
```

## Check

```bash
recipe check vnote
```

This checks the Termux package/command side and reports whether optional local
Whisper pieces are present. Android will still prompt for microphone permissions
when the API surface is first used.

## Remove

```bash
recipe remove vnote
```

Removal deletes only the recipe-owned payload and links. It does **not** remove
`termux-api`, `ffmpeg`, the Termux:API Android app, models, notes, or any other
shared/user state. Package cleanup is deliberately manual because dependencies
may be shared by other recipes or by the user.
