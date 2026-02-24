# Local Dev Workflow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add npm scripts for validating, testing, and scaffolding Claude Code plugins locally.

**Architecture:** Three bash scripts in `scripts/` wrapped by npm scripts in root `package.json`. A pre-commit husky hook runs validation. Scaffolding auto-registers new plugins in marketplace.json and commitlint.config.js.

**Tech Stack:** Bash, npm scripts, husky, jq (for JSON parsing in scaffold), Claude CLI (`claude plugin validate`, `--plugin-dir`)

---

### Task 1: Create validate.sh

**Files:**
- Create: `scripts/validate.sh`

**Step 1: Write the script**

```bash
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
```

**Step 2: Make it executable and test**

Run:
```bash
chmod +x scripts/validate.sh
bash scripts/validate.sh
```

Expected: "All validations passed" (both multi-review and jira-cli should pass).

**Step 3: Commit**

```bash
git add scripts/validate.sh
git commit -m "build(repo): add plugin validation script"
```

---

### Task 2: Wire up npm run validate

**Files:**
- Modify: `package.json:5-7` (scripts section)

**Step 1: Add the validate script to package.json**

In the `"scripts"` section of `package.json`, add:
```json
"validate": "bash scripts/validate.sh"
```

Keep the existing `"prepare": "husky"` script.

**Step 2: Test it**

Run:
```bash
npm run validate
```

Expected: Same output as running the script directly — "All validations passed".

**Step 3: Commit**

```bash
git add package.json
git commit -m "build(repo): add npm validate script"
```

---

### Task 3: Add pre-commit hook

**Files:**
- Create: `.husky/pre-commit`

**Step 1: Create the hook**

```bash
npm run validate
```

That's the entire file contents. Husky v9 hooks are just shell scripts — no shebang needed, husky handles execution.

**Step 2: Make it executable**

Run:
```bash
chmod +x .husky/pre-commit
```

**Step 3: Test the hook works**

Run:
```bash
git commit --allow-empty -m "test: verify pre-commit hook runs validation"
```

Expected: Validation output appears before the commit completes. The commit should succeed since all plugins are valid.

**Step 4: Commit**

```bash
git add .husky/pre-commit
git commit -m "build(repo): add pre-commit hook for plugin validation"
```

---

### Task 4: Create dev.sh

**Files:**
- Create: `scripts/dev.sh`

**Step 1: Write the script**

```bash
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
```

**Step 2: Make it executable and test help output**

Run:
```bash
chmod +x scripts/dev.sh
bash scripts/dev.sh
```

Expected: Usage message listing available plugins (multi-review, jira-cli).

**Step 3: Commit**

```bash
git add scripts/dev.sh
git commit -m "build(repo): add local dev session script"
```

---

### Task 5: Wire up npm run dev

**Files:**
- Modify: `package.json:5-7` (scripts section)

**Step 1: Add the dev script to package.json**

In the `"scripts"` section, add:
```json
"dev": "bash scripts/dev.sh"
```

**Step 2: Test it**

Run:
```bash
npm run dev
```

Expected: Usage message with available plugins.

Run (optional, interactive — skip in automated execution):
```bash
npm run dev -- multi-review
```

Expected: Validates multi-review, then launches an interactive Claude session with the plugin loaded.

**Step 3: Commit**

```bash
git add package.json
git commit -m "build(repo): add npm dev script"
```

---

### Task 6: Create scaffold.sh

**Files:**
- Create: `scripts/scaffold.sh`

**Step 1: Write the script**

```bash
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
```

**Step 2: Make it executable and test the help output**

Run:
```bash
chmod +x scripts/scaffold.sh
bash scripts/scaffold.sh
```

Expected: Usage message.

**Step 3: Test scaffolding a plugin, then clean up**

Run:
```bash
bash scripts/scaffold.sh test-plugin
```

Expected: "Plugin 'test-plugin' created successfully!" with file listing and next-steps.

Verify structure:
```bash
ls -la test-plugin/.claude-plugin/plugin.json test-plugin/package.json test-plugin/skills/test-plugin/SKILL.md
```

Verify marketplace.json was updated:
```bash
node -e "const m = require('./.claude-plugin/marketplace.json'); console.log(m.plugins.map(p => p.name))"
```

Expected: `[ 'multi-review', 'jira-cli', 'test-plugin' ]`

Verify commitlint.config.js was updated:
```bash
grep test-plugin commitlint.config.js
```

Expected: Line containing `'test-plugin'` in the scope-enum array.

Clean up test plugin:
```bash
rm -rf test-plugin
git checkout -- .claude-plugin/marketplace.json commitlint.config.js package.json
```

**Step 4: Commit**

```bash
git add scripts/scaffold.sh
git commit -m "build(repo): add plugin scaffolding script"
```

---

### Task 7: Wire up npm run scaffold

**Files:**
- Modify: `package.json:5-7` (scripts section)

**Step 1: Add the scaffold script to package.json**

In the `"scripts"` section, add:
```json
"scaffold": "bash scripts/scaffold.sh"
```

**Step 2: Test it**

Run:
```bash
npm run scaffold
```

Expected: Usage message.

**Step 3: Commit**

```bash
git add package.json
git commit -m "build(repo): add npm scaffold script"
```

---

### Task 8: Update CLAUDE.md with dev workflow docs

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Add dev workflow section**

Append a new section after the existing content in `CLAUDE.md`:

```markdown

## Dev Workflow

### Validate all plugins
```
npm run validate
```

### Test a plugin locally
```
npm run dev -- <plugin-name>
```
Launches a Claude session with the plugin loaded from your working tree. Edit files, re-run — no install needed.

### Scaffold a new plugin
```
npm run scaffold -- <plugin-name>
```
Creates the directory structure and registers the plugin in marketplace.json, commitlint.config.js, and package.json workspaces.
```

**Step 2: Verify CLAUDE.md is valid markdown**

Read the file and confirm the new section renders correctly.

**Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(repo): add dev workflow commands to CLAUDE.md"
```

---

### Task 9: End-to-end verification

**Step 1: Run full validation**

```bash
npm run validate
```

Expected: "All validations passed"

**Step 2: Test scaffold + validate cycle**

```bash
npm run scaffold -- e2e-test-plugin
npm run validate
```

Expected: Scaffold succeeds, validation passes with the new plugin included.

**Step 3: Test dev help output**

```bash
npm run dev
```

Expected: Lists all plugins including the newly scaffolded e2e-test-plugin.

**Step 4: Clean up test plugin**

```bash
rm -rf e2e-test-plugin
git checkout -- .claude-plugin/marketplace.json commitlint.config.js package.json
```

**Step 5: Final validation**

```bash
npm run validate
```

Expected: "All validations passed" (back to original state).
