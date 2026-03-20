#!/usr/bin/env bash
# Shared notification helper — reads hook JSON from stdin
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

MSG_SAFE=$(echo "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')
SESS_SAFE=$(echo "$SESS" | sed 's/\\/\\\\/g; s/"/\\"/g')
osascript <<EOF 2>/dev/null; true
display notification "$MSG_SAFE" with title "Claude Code [$SESS_SAFE]"
EOF
