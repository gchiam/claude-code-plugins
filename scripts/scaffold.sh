#!/usr/bin/env bash
#
# Scaffolds a new Claude Code plugin with the correct directory structure
# and registers it in marketplace.json, commitlint.config.js, and package.json workspaces.
#
# Usage: npm run scaffold -- <plugin-name>
# Example: npm run scaffold -- my-new-plugin

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

for cmd in node; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is required but not found on PATH"
    exit 1
  fi
done

if [ $# -eq 0 ]; then
  echo "Usage: npm run scaffold -- <plugin-name>"
  exit 1
fi

PLUGIN_NAME="$1"

# Validate name: lowercase, alphanumeric + hyphens
if ! echo "$PLUGIN_NAME" | grep -qE '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
  echo "Error: Plugin name must be lowercase alphanumeric with hyphens (e.g., 'my-plugin')"
  exit 1
fi

PLUGIN_DIR="$REPO_ROOT/$PLUGIN_NAME"

if [ -d "$PLUGIN_DIR" ]; then
  echo "Error: Directory '$PLUGIN_NAME' already exists"
  exit 1
fi

echo "=== Scaffolding plugin: $PLUGIN_NAME ==="

# Clean up on failure: remove created directory and restore modified config files
BACKUP_DIR=$(mktemp -d)
CLEANUP_FILES=()

cleanup_on_failure() {
  echo ""
  echo "Error: Scaffold failed. Rolling back changes..."
  if [ -d "$PLUGIN_DIR" ]; then
    rm -rf "$PLUGIN_DIR"
    echo "  Removed $PLUGIN_DIR"
  fi
  for f in "${CLEANUP_FILES[@]}"; do
    local backup="$BACKUP_DIR/$(basename "$f")"
    if [ -f "$backup" ]; then
      cp "$backup" "$f"
      echo "  Restored $f"
    fi
  done
  rm -rf "$BACKUP_DIR"
  echo "Rollback complete."
}

trap cleanup_on_failure ERR

# Create directory structure
mkdir -p "$PLUGIN_DIR/.claude-plugin"
mkdir -p "$PLUGIN_DIR/skills/$PLUGIN_NAME"

# plugin.json
cat > "$PLUGIN_DIR/.claude-plugin/plugin.json" << EOF
{
  "name": "$PLUGIN_NAME",
  "version": "1.0.0",
  "description": "TODO: Add plugin description",
  "author": {
    "name": "gchiam"
  }
}
EOF

# package.json
cat > "$PLUGIN_DIR/package.json" << EOF
{
  "name": "$PLUGIN_NAME",
  "version": "1.0.0",
  "private": true,
  "description": "TODO: Add plugin description"
}
EOF

# SKILL.md
cat > "$PLUGIN_DIR/skills/$PLUGIN_NAME/SKILL.md" << EOF
---
name: $PLUGIN_NAME
description: >-
  TODO: Add skill description
---

# $(echo "$PLUGIN_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

TODO: Add skill instructions here.

## Rules

1. TODO: Add rules

## Usage

TODO: Describe how to use this skill.
EOF

# Register in marketplace.json
cp "$REPO_ROOT/.claude-plugin/marketplace.json" "$BACKUP_DIR/"
CLEANUP_FILES+=("$REPO_ROOT/.claude-plugin/marketplace.json")
PLUGIN_NAME="$PLUGIN_NAME" REPO_ROOT="$REPO_ROOT" node -e "
const fs = require('fs');
const pluginName = process.env.PLUGIN_NAME;
const repoRoot = process.env.REPO_ROOT;
const filePath = repoRoot + '/.claude-plugin/marketplace.json';
const m = JSON.parse(fs.readFileSync(filePath, 'utf8'));
if (!Array.isArray(m.plugins)) {
  console.error('Error: marketplace.json is missing a plugins array');
  process.exit(1);
}
if (m.plugins.some(p => p.name === pluginName)) {
  console.error('Error: Plugin ' + pluginName + ' already exists in marketplace.json');
  process.exit(1);
}
m.plugins.push({
  name: pluginName,
  source: './' + pluginName,
  description: 'TODO: Add plugin description'
});
fs.writeFileSync(filePath, JSON.stringify(m, null, 2) + '\n');
"

# Register scope in commitlint.config.js
cp "$REPO_ROOT/commitlint.config.js" "$BACKUP_DIR/"
CLEANUP_FILES+=("$REPO_ROOT/commitlint.config.js")
PLUGIN_NAME="$PLUGIN_NAME" REPO_ROOT="$REPO_ROOT" node -e "
const fs = require('fs');
const pluginName = process.env.PLUGIN_NAME;
const repoRoot = process.env.REPO_ROOT;
const filePath = repoRoot + '/commitlint.config.js';
let content = fs.readFileSync(filePath, 'utf8');
const before = content;
content = content.replace(
  /('scope-enum':\s*\[2,\s*'always',\s*\[)([\s\S]*?)(\]\])/,
  (match, prefix, scopes, suffix) => {
    const scopeList = scopes.split(',').map(s => s.trim());
    scopeList.push(\"'\" + pluginName + \"'\");
    return prefix + scopeList.join(', ') + suffix;
  }
);
if (content === before) {
  console.error('Error: Failed to register scope in commitlint.config.js — scope-enum pattern not found');
  process.exit(1);
}
fs.writeFileSync(filePath, content);
"

# Register as npm workspace
cp "$REPO_ROOT/package.json" "$BACKUP_DIR/"
CLEANUP_FILES+=("$REPO_ROOT/package.json")
PLUGIN_NAME="$PLUGIN_NAME" REPO_ROOT="$REPO_ROOT" node -e "
const fs = require('fs');
const pluginName = process.env.PLUGIN_NAME;
const repoRoot = process.env.REPO_ROOT;
const filePath = repoRoot + '/package.json';
const pkg = JSON.parse(fs.readFileSync(filePath, 'utf8'));
if (!Array.isArray(pkg.workspaces)) {
  console.error('Error: package.json is missing a workspaces array');
  process.exit(1);
}
if (!pkg.workspaces.includes(pluginName)) {
  pkg.workspaces.push(pluginName);
}
fs.writeFileSync(filePath, JSON.stringify(pkg, null, 2) + '\n');
"

rm -rf "$BACKUP_DIR"
trap - ERR

echo ""
echo "Plugin '$PLUGIN_NAME' created successfully!"
echo ""
echo "Created:"
echo "  $PLUGIN_NAME/.claude-plugin/plugin.json"
echo "  $PLUGIN_NAME/package.json"
echo "  $PLUGIN_NAME/skills/$PLUGIN_NAME/SKILL.md"
echo ""
echo "Registered in:"
echo "  .claude-plugin/marketplace.json"
echo "  commitlint.config.js (scope: '$PLUGIN_NAME')"
echo "  package.json (workspace: '$PLUGIN_NAME')"
echo ""
echo "Next steps:"
echo "  1. Edit $PLUGIN_NAME/.claude-plugin/plugin.json — update description"
echo "  2. Edit $PLUGIN_NAME/skills/$PLUGIN_NAME/SKILL.md — write skill instructions"
echo "  3. Run: npm run validate"
echo "  4. Run: npm run dev -- $PLUGIN_NAME"
