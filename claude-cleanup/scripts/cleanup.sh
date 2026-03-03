#!/usr/bin/env bash
set -euo pipefail

CLAUDE_JSON="$HOME/.claude.json"
MODE="${1:-}"

if [ "$MODE" != "--dry-run" ] && [ "$MODE" != "--clean" ]; then
  echo "Usage: cleanup.sh --dry-run | --clean" >&2
  exit 1
fi

# Check dependencies
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not found. Install with: brew install jq" >&2
  exit 1
fi

# Check file exists
if [ ! -f "$CLAUDE_JSON" ]; then
  echo "Error: $CLAUDE_JSON not found" >&2
  exit 1
fi

# Check projects key exists
if ! jq -e '.projects' "$CLAUDE_JSON" > /dev/null 2>&1; then
  echo "Nothing to clean — no 'projects' key found in $CLAUDE_JSON"
  exit 0
fi

# Find stale paths
STALE=()
while IFS= read -r path; do
  [ -n "$path" ] || continue
  [ -d "$path" ] || STALE+=("$path")
done < <(jq -r '.projects | keys[]' "$CLAUDE_JSON")

if [ ${#STALE[@]} -eq 0 ]; then
  echo "Nothing to clean — all project paths exist on disk."
  exit 0
fi

if [ "$MODE" = "--dry-run" ]; then
  echo "Stale project entries (${#STALE[@]} found):"
  for path in "${STALE[@]}"; do
    echo "  - $path"
  done
  exit 0
fi

# --clean mode: backup then remove stale entries atomically
cp "$CLAUDE_JSON" "${CLAUDE_JSON}.bak"
echo "Backup saved to ${CLAUDE_JSON}.bak"

STALE_JSON=$(printf '%s\n' "${STALE[@]}" | jq -R . | jq -s .)
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
jq --argjson stale "$STALE_JSON" \
  'reduce $stale[] as $p (.; del(.projects[$p]))' \
  "$CLAUDE_JSON" > "$TMP"
mv "$TMP" "$CLAUDE_JSON"

COUNT=${#STALE[@]}
WORD=$([ "$COUNT" -eq 1 ] && echo "entry" || echo "entries")
echo "Removed $COUNT stale $WORD from $CLAUDE_JSON"
