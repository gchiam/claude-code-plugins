#!/usr/bin/env bash
#
# Launches a Claude session with a local plugin loaded from the working tree.
#
# Usage: npm run dev -- <plugin-name>
# Example: npm run dev -- multi-review

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

for cmd in claude node; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is required but not found on PATH"
    exit 1
  fi
done

if [ $# -eq 0 ]; then
  echo "Usage: npm run dev -- <plugin-name>"
  echo ""
  echo "Available plugins:"
  found=0
  for dir in "$REPO_ROOT"/*/; do
    if [ -f "$dir/.claude-plugin/plugin.json" ]; then
      echo "  $(basename "$dir")"
      found=1
    fi
  done
  if [ "$found" -eq 0 ]; then
    echo "  (none found — run 'npm run scaffold -- <name>' to create one)"
  fi
  exit 1
fi

PLUGIN_NAME="$1"

# Validate name: lowercase, alphanumeric + hyphens
if ! echo "$PLUGIN_NAME" | grep -qE '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
  echo "Error: Plugin name must be lowercase alphanumeric with hyphens (e.g., 'my-plugin')"
  exit 1
fi

PLUGIN_DIR="$REPO_ROOT/$PLUGIN_NAME"

if [ ! -d "$PLUGIN_DIR/.claude-plugin" ]; then
  echo "Error: '$PLUGIN_NAME' is not a valid plugin directory"
  echo "(expected $PLUGIN_DIR/.claude-plugin/ to exist)"
  exit 1
fi

echo "=== Validating $PLUGIN_NAME before launch ==="
if ! claude plugin validate "$PLUGIN_DIR"; then
  echo "Validation failed — fix errors before launching dev session"
  exit 1
fi

echo ""
echo "=== Launching Claude with local plugin: $PLUGIN_NAME ==="
echo ""
exec claude --plugin-dir "$PLUGIN_DIR"
