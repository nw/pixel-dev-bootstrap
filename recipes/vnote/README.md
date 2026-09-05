# vnote recipe

A deliberately small Termux/Android integration for appending spoken thoughts to
Markdown from the CLI.

```bash
recipe install vnote
vnote
```

`vnote` first uses Android speech-to-text through Termux:API. If native STT is
unavailable or fails, it can fall back to a local `whisper-cli` workflow.
Cancelling the Android dialog, or completing it without recognized speech,
exits cleanly without creating a note or starting local recording.

The recipe also installs a foreground Termux launcher/widget shortcut at
`~/.shortcuts/vnote`. It is a real file rather than a symlink so it satisfies
Termux shortcut path validation. On current Google Play Termux, Widget support is
built into the main app; other Termux distributions may require the matching
Termux:Widget plugin. Refresh the widget after recipe changes when necessary.

## What the recipe installs

Termux packages ensured on install:

```text
termux-api
ffmpeg
```

The **Termux:API Android companion app is required on distributions that use the
separate plugin**, and it must come from the same signing/distribution source as
Termux. Current Google Play Termux exposes the speech/microphone commands used by
this recipe directly. A recipe can install Termux packages; it cannot install or
own Android applications.

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

Removal deletes only the recipe-owned payload, links, and an unchanged
`~/.shortcuts/vnote` copy. If the shortcut was edited by the user, removal leaves
it alone. It does **not** remove `termux-api`, `ffmpeg`, the Termux:API Android
app, models, notes, or any other shared/user state. Package cleanup is deliberately
manual because dependencies may be shared by other recipes or by the user.
