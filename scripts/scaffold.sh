#!/usr/bin/env bash
#
# Scaffolds a new Claude Code plugin with the correct directory structure
# and registers it in marketplace.json and commitlint.config.js.
#
# Usage: npm run scaffold -- <plugin-name>
# Example: npm run scaffold -- my-new-plugin

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ $# -eq 0 ]; then
  echo "Usage: npm run scaffold -- <plugin-name>"
  exit 1
fi

PLUGIN_NAME="$1"

# Validate name: lowercase, alphanumeric + hyphens
if ! echo "$PLUGIN_NAME" | grep -qE '^[a-z][a-z0-9-]*$'; then
  echo "Error: Plugin name must be lowercase alphanumeric with hyphens (e.g., 'my-plugin')"
  exit 1
fi

PLUGIN_DIR="$REPO_ROOT/$PLUGIN_NAME"

if [ -d "$PLUGIN_DIR" ]; then
  echo "Error: Directory '$PLUGIN_NAME' already exists"
  exit 1
fi

echo "=== Scaffolding plugin: $PLUGIN_NAME ==="

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
node -e "
const fs = require('fs');
const path = '$REPO_ROOT/.claude-plugin/marketplace.json';
const m = JSON.parse(fs.readFileSync(path, 'utf8'));
m.plugins.push({
  name: '$PLUGIN_NAME',
  source: './$PLUGIN_NAME',
  description: 'TODO: Add plugin description'
});
fs.writeFileSync(path, JSON.stringify(m, null, 2) + '\n');
"

# Register scope in commitlint.config.js
node -e "
const fs = require('fs');
const path = '$REPO_ROOT/commitlint.config.js';
let content = fs.readFileSync(path, 'utf8');
// Find the scope-enum array and add the new scope
content = content.replace(
  /('scope-enum':\s*\[2,\s*'always',\s*\[)(.*?)(\]\])/,
  (match, prefix, scopes, suffix) => {
    const scopeList = scopes.split(',').map(s => s.trim());
    scopeList.push(\"'$PLUGIN_NAME'\");
    return prefix + scopeList.join(', ') + suffix;
  }
);
fs.writeFileSync(path, content);
"

# Register as npm workspace
node -e "
const fs = require('fs');
const path = '$REPO_ROOT/package.json';
const pkg = JSON.parse(fs.readFileSync(path, 'utf8'));
if (!pkg.workspaces.includes('$PLUGIN_NAME')) {
  pkg.workspaces.push('$PLUGIN_NAME');
}
fs.writeFileSync(path, JSON.stringify(pkg, null, 2) + '\n');
"

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
