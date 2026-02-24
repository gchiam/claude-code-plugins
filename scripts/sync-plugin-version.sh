#!/usr/bin/env bash
#
# Syncs the "version" field from package.json into .claude-plugin/plugin.json
# for the current working directory.
#
# Usage: Called by semantic-release @semantic-release/exec in the prepare step.
#        Runs with cwd set to the package directory by multi-semantic-release.

set -euo pipefail

PACKAGE_JSON="package.json"
PLUGIN_JSON=".claude-plugin/plugin.json"

if [ ! -f "$PLUGIN_JSON" ]; then
  echo "No $PLUGIN_JSON found in $(pwd), skipping sync"
  exit 0
fi

VERSION=$(node -p "require('./$PACKAGE_JSON').version")

# Use node to update the version in plugin.json (preserves formatting)
node -e "
const fs = require('fs');
const path = './$PLUGIN_JSON';
const plugin = JSON.parse(fs.readFileSync(path, 'utf8'));
plugin.version = '$VERSION';
fs.writeFileSync(path, JSON.stringify(plugin, null, 2) + '\n');
"

echo "Synced $PLUGIN_JSON version to $VERSION"
