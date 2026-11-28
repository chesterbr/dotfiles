#!/usr/bin/env bash
# Claude Code sound notifications, same events and sounds on every machine.
#   notify.sh done       Stop hook
#   notify.sh attention  Notification hook
# To change a sound, replace the .wav in claude/sounds/.
sound="$(cd "$(dirname "$0")" && pwd)/sounds/${1:?usage: notify.sh done|attention}.wav"

for player in afplay pw-play paplay aplay; do   # afplay is macOS; the rest are Linux
  if command -v "$player" >/dev/null 2>&1; then
    "$player" "$sound" >/dev/null 2>&1
    exit 0
  fi
done
