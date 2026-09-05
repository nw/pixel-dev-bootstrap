#!/usr/bin/env bash

# Catalog discovery parses these two single-line quoted literals without
# sourcing this file. Keep them simple and side-effect free.
recipe_name="vnote"
recipe_description="Quick voice notes through Android STT with an optional local Whisper fallback"
recipe_packages=(termux-api ffmpeg)

recipe_check() {
  local status=0

  for command_name in termux-speech-to-text termux-microphone-record ffmpeg; do
    if command -v "$command_name" >/dev/null 2>&1; then
      printf 'ok       command %s\n' "$command_name"
    else
      printf 'missing  command %s\n' "$command_name"
      status=1
    fi
  done

  if command -v whisper-cli >/dev/null 2>&1; then
    printf 'ok       optional whisper-cli\n'
  else
    printf 'optional whisper-cli not found; Android STT still works\n'
  fi

  local model="${VNOTE_MODEL:-$HOME/models/ggml-tiny.en.bin}"
  if [[ -f "$model" ]]; then
    printf 'ok       optional model %s\n' "$model"
  else
    printf 'optional local Whisper model not found: %s\n' "$model"
  fi

  printf 'note     Termux:API Android companion app must be installed from the same signing source as Termux.\n'
  return "$status"
}
