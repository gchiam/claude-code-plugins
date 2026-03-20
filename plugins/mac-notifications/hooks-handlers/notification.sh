#!/usr/bin/env bash
INPUT=$(cat)
MSG=$(echo "$INPUT" | jq -r '.message // "Authorization needed"')
echo "$INPUT" | "$(dirname "$0")/notify.sh" Sosumi.aiff "$MSG"
