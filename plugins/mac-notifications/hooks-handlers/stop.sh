#!/usr/bin/env bash
INPUT=$(cat)
SID=$(echo "$INPUT" | jq -r '.session_id')
CWD=$(jq -r --arg sid "$SID" 'select(.sessionId == $sid) | .cwd' ~/.claude/sessions/*.json 2>/dev/null | head -1)
CWD=${CWD:-$PWD}
SESS=$(basename "$CWD")
afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
osascript -e "display notification \"Task completed\" with title \"Claude Code [$SESS]\"" 2>/dev/null; true
