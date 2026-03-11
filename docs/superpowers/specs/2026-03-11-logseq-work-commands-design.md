# Design: Logseq Work Commands

**Date:** 2026-03-11
**Plugin:** logseq
**Status:** Approved

## Overview

Add two new commands to the logseq plugin to support structured work tracking in Logseq:

- `/logseq:work-log` — append timestamped entries to today's journal under structured sections (In Progress / Done / Blocked / Next)
- `/logseq:new-work-page` — create a named page for a JIRA ticket, PR, or repo/service from a property template

## Architecture

Both commands follow the existing plugin pattern: markdown command files that delegate shared conventions to `SKILL.md`. The skill is updated to become the single source of truth for work-tracking conventions (page naming, property templates, timestamp format, section names).

### Files Changed

| File | Change |
|------|--------|
| `plugins/logseq/commands/work-log.md` | New command |
| `plugins/logseq/commands/new-work-page.md` | New command |
| `plugins/logseq/skills/logseq/SKILL.md` | Add work-tracking conventions section |
| `plugins/logseq/skills/logseq/references/block-examples.md` | Add worked examples for new entry types |

## Command: `/logseq:work-log`

### Purpose

Append new work items to today's journal page under section headings, with a `[HH:MM]` timestamp on each entry to enable progress tracking over time.

### Workflow

1. Check MCP availability (`mcp__graphthulhu__upsert_blocks` must be accessible)
2. Detect journal page format using the same procedure as `/logseq:capture`: check `.claude/logseq.local.md` for `journal_format`, then `~/.claude/logseq.local.md`, then auto-detect via `mcp__graphthulhu__list_pages` (sortBy: modified, limit: 20, find first entry with `"journal": true`), then fall back to `YYYY/MM/DD`. (`list_pages` is listed in allowed tools specifically to support this detection step.)
3. Read today's journal page with `mcp__graphthulhu__get_page`
4. Scan existing blocks to identify which section headings exist (`## In Progress`, `## Done`, `## Blocked`, `## Next`)
5. Prompt user: ask what new items to add (a single message covering all sections)
6. For each new item:
   - Append as a child block under the appropriate section heading
   - Include a `[HH:MM]` timestamp inline on the block
   - If the section heading doesn't exist yet, create it first, then add the item beneath it
7. Confirm with a summary of what was appended

### Block Structure

Each appended item follows this format:
```
[[JIRA/PROJ-123]] investigating auth bug #claude-managed #work-log [09:32]
```

- Tags (`#claude-managed #work-log`) come immediately after the description, before the timestamp — consistent with SKILL.md's tag placement convention
- Timestamp `[HH:MM]` appended at the end of the content string, after tags
- Page references use `[[double brackets]]` for Logseq auto-linking
- Work-log entries intentionally omit `type::` and `source:: claude-code` properties — they are high-frequency inline journal entries, not standalone notes, so the reduced verbosity is preferable. The `#work-log` tag serves as the type signal.

### Section Creation

When a section heading doesn't yet exist on today's journal, both the heading and the first item are written in a **single `upsert_blocks` call**, with the section heading as the parent block and the item as its child — consistent with SKILL.md's Section Grouping pattern:

```json
{
  "page": "2026/03/11",
  "blocks": [
    {
      "content": "## In Progress",
      "children": [
        { "content": "[[JIRA/PROJ-123]] investigating auth bug #claude-managed #work-log [09:32]" }
      ]
    }
  ]
}
```

When the section heading already exists, append the item as a child under that heading in a new `upsert_blocks` call.

### Constraints

- **Additive only** — existing blocks are never modified or deleted
- **Sections created on demand** — if a section heading doesn't exist on today's journal, it is created before appending
- **No journal structure assumed** — works with a blank journal page or one that already has content

### Allowed Tools

- `mcp__graphthulhu__upsert_blocks`
- `mcp__graphthulhu__get_page`
- `mcp__graphthulhu__list_pages`
- `Read` (for settings files)

## Command: `/logseq:new-work-page`

### Purpose

Create a named Logseq page for a JIRA ticket, PR, or repo/service, pre-populated with a structured property template.

### Workflow

1. Check MCP availability
2. Resolve page type and identifier:
   - From inline args if provided (e.g. `/logseq:new-work-page jira PROJ-123`)
   - Otherwise prompt interactively
3. Derive page name:
   - `jira PROJ-123` → `JIRA/PROJ-123`
   - `pr myrepo 42` → `PR/myrepo/42`
   - `repo my-service` → `Repo/my-service`
4. Check if page already exists via `mcp__graphthulhu__get_page` — if so, warn the user and stop. Do not overwrite. Tell the user to manually clear or rename the page if they want to start fresh. (`upsert_blocks` is an append/merge operation and cannot reliably replace existing page content.)
5. Write the page using `mcp__graphthulhu__upsert_blocks` with the type-specific template
6. Confirm with the created page name

### Property Templates

Each template is written as the `content` of the first (and only) block in the `upsert_blocks` call. Properties are inline on that block, consistent with SKILL.md conventions.

**JIRA page (`JIRA/<ticket-id>`):**
```json
{
  "page": "JIRA/PROJ-123",
  "blocks": [
    {
      "content": "JIRA/PROJ-123 #claude-managed #jira\nstatus:: in-progress\nsprint::\nrepo::\nprs::"
    }
  ]
}
```

**PR page (`PR/<repo>/<number>`):**
```json
{
  "page": "PR/myrepo/42",
  "blocks": [
    {
      "content": "PR/myrepo/42 #claude-managed #pr\nstatus:: open\njira::\nrepo:: [[Repo/myrepo]]\nopened:: [[YYYY-MM-DD]]\nmerged::"
    }
  ]
}
```

**Repo page (`Repo/<service-name>`):**
```json
{
  "page": "Repo/my-service",
  "blocks": [
    {
      "content": "Repo/my-service #claude-managed #repo\nteam::\nstack::"
    }
  ]
}
```

### Inline Argument Format

```
/logseq:new-work-page jira PROJ-123
/logseq:new-work-page pr myrepo 42
/logseq:new-work-page repo my-service
```

If no args are provided, Claude prompts for type and identifier.

### Constraints

- **No journal update** — creating a work page does not touch today's journal
- **Existing pages are not overwritten** — if the page already exists, the command warns and stops; `upsert_blocks` cannot reliably replace existing content

### Allowed Tools

- `mcp__graphthulhu__upsert_blocks`
- `mcp__graphthulhu__get_page`
- `Read` (for settings files)

## SKILL.md Updates

Add a **Work Tracking Conventions** section covering:

- Page naming scheme: `JIRA/<id>`, `PR/<repo>/<num>`, `Repo/<name>`
- Section heading names for work-log: `## In Progress`, `## Done`, `## Blocked`, `## Next`
- Timestamp format: `[HH:MM]` inline on the block
- Required tags: `#claude-managed #work-log` for journal entries, `#claude-managed #<type>` for work pages
- Property keys per page type (as reference for both commands)

## block-examples.md Updates

Add worked `upsert_blocks` examples for:

1. Appending a work-log entry under an existing section
2. Creating a section heading + first entry when section doesn't exist
3. Creating a JIRA page
4. Creating a PR page
5. Creating a Repo page

## Success Criteria

- `/logseq:work-log` reads today's page, prompts for new items, and appends them with `[HH:MM]` timestamps under the correct section headings
- Running `/logseq:work-log` multiple times in a day accumulates entries — nothing is overwritten
- `/logseq:new-work-page jira PROJ-123` creates a `JIRA/PROJ-123` page with all required properties filled as empty values
- Work-log entry block content contains `[[JIRA/PROJ-123]]` double-bracket syntax (Logseq renders these as links automatically)
- All new commands follow the same MCP availability check and journal format detection as existing commands
