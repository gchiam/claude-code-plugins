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
