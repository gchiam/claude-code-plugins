# Claude Cleanup Plugin Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a `claude-cleanup` plugin with a companion shell script that scans `~/.claude.json` for stale project entries and removes them via a 4-phase interactive skill.

**Architecture:** A bash+jq script handles all JSON manipulation (scan, backup, atomic write). A SKILL.md orchestrates the user-facing flow: scan → optional /insights → delete. The scaffold tooling registers the plugin in marketplace, commitlint, and workspaces automatically.

**Tech Stack:** bash, jq, Claude Code skill (SKILL.md), npm workspaces

---

### Task 1: Scaffold the plugin

**Files:**
- Create: `claude-cleanup/` (via scaffold script)
- Modify: `.claude-plugin/marketplace.json`, `commitlint.config.js`, `package.json` (via scaffold script)

**Step 1: Run the scaffold script**

```bash
npm run scaffold -- claude-cleanup
```

Expected output:
```
=== Scaffolding plugin: claude-cleanup ===

Plugin 'claude-cleanup' created successfully!

Created:
  claude-cleanup/.claude-plugin/plugin.json
  claude-cleanup/package.json
  claude-cleanup/skills/claude-cleanup/SKILL.md

Registered in:
  .claude-plugin/marketplace.json
  commitlint.config.js (scope: 'claude-cleanup')
  package.json (workspace: 'claude-cleanup')
```

**Step 2: Update the plugin description in `claude-cleanup/.claude-plugin/plugin.json`**

Replace the TODO description:

```json
{
  "name": "claude-cleanup",
  "version": "1.0.0",
  "description": "Clean up stale project entries in ~/.claude.json whose directories no longer exist on disk",
  "author": {
    "name": "gchiam"
  }
}
```

**Step 3: Update the plugin description in `claude-cleanup/package.json`**

```json
{
  "name": "claude-cleanup",
  "version": "1.0.0",
  "private": true,
  "description": "Clean up stale project entries in ~/.claude.json whose directories no longer exist on disk"
}
```

**Step 4: Commit**

```bash
git add claude-cleanup/ .claude-plugin/marketplace.json commitlint.config.js package.json
git commit -m "feat(claude-cleanup): scaffold plugin"
```

---

### Task 2: Create `scripts/cleanup.sh`

**Files:**
- Create: `claude-cleanup/scripts/cleanup.sh`

**Step 1: Create the scripts directory and write the script**

Create `claude-cleanup/scripts/cleanup.sh` with this exact content:

```bash
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
jq --argjson stale "$STALE_JSON" \
  'reduce $stale[] as $p (.; del(.projects[$p]))' \
  "$CLAUDE_JSON" > "$TMP"
mv "$TMP" "$CLAUDE_JSON"

COUNT=${#STALE[@]}
WORD=$([ "$COUNT" -eq 1 ] && echo "entry" || echo "entries")
echo "Removed $COUNT stale $WORD from $CLAUDE_JSON"
```

**Step 2: Make the script executable**

```bash
chmod +x claude-cleanup/scripts/cleanup.sh
```

**Step 3: Smoke-test the script**

```bash
bash claude-cleanup/scripts/cleanup.sh --dry-run
```

Expected: Either lists stale paths with count, or prints "Nothing to clean — all project paths exist on disk."

**Step 4: Commit**

```bash
git add claude-cleanup/scripts/cleanup.sh
git commit -m "feat(claude-cleanup): add cleanup.sh with dry-run and clean modes"
```

---

### Task 3: Write the SKILL.md

**Files:**
- Modify: `claude-cleanup/skills/claude-cleanup/SKILL.md`

**Step 1: Replace the scaffolded stub with the full skill**

Overwrite `claude-cleanup/skills/claude-cleanup/SKILL.md` with:

```markdown
---
name: claude-cleanup
description: >-
  Clean up stale project entries in ~/.claude.json whose directories no longer
  exist on disk. Use when the user says "clean up claude.json", "remove stale
  projects", "prune old project entries", or "clean up my Claude project history".
---

# Claude Cleanup

Remove project entries from `~/.claude.json` whose directories no longer exist
on disk.

## Rules

1. **Always run Phase 1 first.** Never skip straight to cleanup.
2. **Never delete entries without the user seeing the stale list.**
3. **Stop after Phase 1 if nothing is stale.** Do not ask about /insights.

## Setup: Resolve the script path

The system-reminder at load time contains: `Base directory for this skill: <path>`

Use that value to derive the plugin root:

```bash
# SKILL_BASE = the base directory shown in the system context
PLUGIN_ROOT="${SKILL_BASE%/skills/claude-cleanup}"
SCRIPT="$PLUGIN_ROOT/scripts/cleanup.sh"
```

Use `$SCRIPT` for all bash invocations below.

## Phase 1 — Scan

Run:

```bash
bash "$SCRIPT" --dry-run
```

- If output is "Nothing to clean — all project paths exist on disk.", report
  this to the user and **stop**.
- Otherwise display the stale paths listed in the output.

## Phase 2 — Insights prompt

Ask the user with `AskUserQuestion`:

- **Question:** "Run /insights before cleaning up?"
- **Options:** Yes, No

## Phase 3 — Insights (conditional)

If the user chose **Yes**, invoke the `/insights` built-in using the `Skill`
tool with skill name `insights`. Wait for it to complete before proceeding.

## Phase 4 — Clean

Run:

```bash
bash "$SCRIPT" --clean
```

Report the output to the user: number of entries removed and backup location
(`~/.claude.json.bak`).
```

**Step 2: Commit**

```bash
git add claude-cleanup/skills/claude-cleanup/SKILL.md
git commit -m "feat(claude-cleanup): add SKILL.md with 4-phase flow"
```

---

### Task 4: Validate and finish

**Step 1: Run the full validation suite**

```bash
npm run validate
```

Expected: All plugins pass. No errors about `claude-cleanup`.

**Step 2: Fix any validation issues then commit**

If `npm run validate` reports errors, fix them:

```bash
git add -p
git commit -m "fix(claude-cleanup): fix validation issues"
```

**Step 3: Verify the dev harness loads the skill**

```bash
npm run dev -- claude-cleanup
```

In the opened session, type: "clean up my Claude project history"

Confirm:
- Phase 1 runs `--dry-run` and shows stale entries (or "Nothing to clean")
- Phase 2 asks about `/insights`
- Phase 4 runs `--clean` and reports removal count + backup path
