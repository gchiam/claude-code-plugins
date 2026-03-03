# claude-cleanup Plugin Design

**Date:** 2026-03-03
**Status:** Approved

## Overview

A plugin that scans `~/.claude.json` for project entries whose directories no
longer exist on disk, optionally runs `/insights` for a session overview, then
removes the stale entries.

## Plugin Structure

```
claude-cleanup/
  .claude-plugin/
    plugin.json
  package.json
  scripts/
    cleanup.sh
  skills/
    claude-cleanup/
      SKILL.md
```

Registered in `marketplace.json`, `commitlint.config.js`, and `package.json`
workspaces via the scaffold tooling.

## `cleanup.sh` Contract

**Language:** bash + jq (no python3 dependency)

### Modes

**`cleanup.sh --dry-run`**
- Reads `~/.claude.json`
- Extracts all keys under `.projects` with `jq -r '.projects | keys[]'`
- Checks each path with bash `[ -d "$path" ]`
- Prints a summary table of stale paths to stdout
- Exits 0 even when no stale entries found

**`cleanup.sh --clean`**
- Same scan as `--dry-run`
- Copies `~/.claude.json` → `~/.claude.json.bak` (backup)
- Builds cleaned JSON via `jq --argjson stale '...' 'reduce $stale[] as $p (.; del(.projects[$p]))'`
- Writes atomically: output to temp file, then `mv` to `~/.claude.json`

### Edge Cases

- `~/.claude.json` missing → exit with clear error message
- No `projects` key → report "Nothing to clean"
- Zero stale entries → report "Nothing to clean", skip backup/write
- `jq` not found → exit with install instructions

## Skill Flow (SKILL.md)

**Phase 1 — Scan**
Run `cleanup.sh --dry-run`. If output is "Nothing to clean", report and stop.
Otherwise display stale paths in a formatted table.

**Phase 2 — Insights prompt**
Use `AskUserQuestion` to ask: "Run /insights before cleaning up?" with options
Yes / No.

**Phase 3 — Insights (conditional)**
If yes, invoke the `/insights` built-in via the `Skill` tool and wait for
completion before proceeding.

**Phase 4 — Clean**
Run `cleanup.sh --clean`. Report count of removed entries and confirm backup
written to `~/.claude.json.bak`.
