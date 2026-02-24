#!/usr/bin/env bash
#
# Validates all plugins and the marketplace manifest.
# Checks both claude plugin validity and expected file structure.
#
# Usage: npm run validate

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
ERRORS=0

echo "=== Validating marketplace manifest ==="
if ! claude plugin validate "$REPO_ROOT"; then
  echo "FAIL: Marketplace manifest validation failed"
  ERRORS=$((ERRORS + 1))
fi

# Extract plugin names and source dirs from marketplace.json
PLUGINS=$(node -e "
const m = require('$MARKETPLACE');
m.plugins.forEach(p => console.log(p.name + ' ' + p.source));
")

while IFS=' ' read -r NAME SOURCE; do
  PLUGIN_DIR="$REPO_ROOT/${SOURCE#./}"
  echo ""
  echo "=== Validating plugin: $NAME ==="

  # Claude CLI validation
  if ! claude plugin validate "$PLUGIN_DIR"; then
    echo "FAIL: claude plugin validate failed for $NAME"
    ERRORS=$((ERRORS + 1))
  fi

  # File structure checks
  for EXPECTED in ".claude-plugin/plugin.json" "skills/$NAME/SKILL.md" "package.json"; do
    if [ ! -f "$PLUGIN_DIR/$EXPECTED" ]; then
      echo "FAIL: Missing $EXPECTED in $NAME"
      ERRORS=$((ERRORS + 1))
    fi
  done
done <<< "$PLUGINS"

echo ""
if [ "$ERRORS" -gt 0 ]; then
  echo "Validation failed with $ERRORS error(s)"
  exit 1
fi

echo "All validations passed"
