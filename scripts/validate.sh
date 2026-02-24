#!/usr/bin/env bash
#
# Validates all plugins and the marketplace manifest.
# Checks both claude plugin validity and expected file structure.
#
# Usage: npm run validate

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
ERRORS=0

for cmd in claude node; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is required but not found on PATH"
    exit 1
  fi
done

echo "=== Validating marketplace manifest ==="
if ! claude plugin validate "$REPO_ROOT"; then
  echo "FAIL: Marketplace manifest validation failed"
  ERRORS=$((ERRORS + 1))
fi

# Extract plugin names and source dirs from marketplace.json
if ! PLUGINS=$(MARKETPLACE="$MARKETPLACE" node -e "
const fs = require('fs');
const filePath = process.env.MARKETPLACE;
let raw;
try { raw = fs.readFileSync(filePath, 'utf8'); }
catch (e) { console.error('Error: Cannot read ' + filePath + ': ' + e.message); process.exit(1); }
let m;
try { m = JSON.parse(raw); }
catch (e) { console.error('Error: Invalid JSON in ' + filePath + ': ' + e.message); process.exit(1); }
if (!Array.isArray(m.plugins)) {
  console.error('Error: marketplace.json missing \"plugins\" array');
  process.exit(1);
}
m.plugins.forEach((p, i) => {
  if (!p.name || !p.source) {
    console.error('Error: Plugin entry at index ' + i + ' missing name or source');
    process.exit(1);
  }
  console.log(p.name + ' ' + p.source);
});
"); then
  echo "FAIL: Could not parse marketplace.json"
  exit 1
fi

if [ -z "$PLUGINS" ]; then
  echo "Warning: No plugins found in marketplace manifest"
fi

while IFS=' ' read -r NAME SOURCE; do
  [ -z "$NAME" ] && continue
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
