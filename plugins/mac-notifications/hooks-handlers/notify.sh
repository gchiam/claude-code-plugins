#!/usr/bin/env bash
# Shared notification helper
# Usage: notify.sh <sound-filename> <message>
# Example: notify.sh Glass.aiff "Task completed"

SOUND=$1
MSG=$2

INPUT=$(cat)
SID=$(echo "$INPUT" | jq -r '.session_id')
CWD=$(jq -r --arg sid "$SID" 'select(.sessionId == $sid) | .cwd' ~/.claude/sessions/*.json 2>/dev/null | head -1)
CWD=${CWD:-$PWD}
SESS=$(basename "$CWD")

afplay "/System/Library/Sounds/$SOUND" 2>/dev/null &

# TODO(human): call osascript safely using $MSG and $SESS without string interpolation injection
