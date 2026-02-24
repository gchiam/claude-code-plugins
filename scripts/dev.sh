#!/usr/bin/env bash
#
# Launches a Claude session with a local plugin loaded from the working tree.
#
# Usage: npm run dev -- <plugin-name>
# Example: npm run dev -- multi-review

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ $# -eq 0 ]; then
  echo "Usage: npm run dev -- <plugin-name>"
  echo ""
  echo "Available plugins:"
  for dir in "$REPO_ROOT"/*/; do
    if [ -f "$dir/.claude-plugin/plugin.json" ]; then
      echo "  $(basename "$dir")"
    fi
  done
  exit 1
fi

PLUGIN_NAME="$1"
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
