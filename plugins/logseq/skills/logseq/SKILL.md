---
name: Logseq Capture
description: Use when the user asks to capture to Logseq, save to Logseq, add to their Logseq journal, create a Logseq entry, log something to Logseq, write to Logseq, note something in Logseq, or mentions saving notes, tasks, code snippets, or meeting notes to Logseq. Also use when the user runs /logseq:capture or /logseq:quick-capture commands.
version: 0.1.0
---

# Logseq Capture

Use this skill to create well-structured entries in a Logseq graph via the graphthulhu MCP server.

## Prerequisites

Before capturing, verify graphthulhu MCP is connected. The `mcp__graphthulhu__*` tools must be available. If they are not, inform the user and show the setup instructions from `references/setup-guide.md`.

## Core Tool: upsert_blocks

All writes to Logseq use `mcp__graphthulhu__upsert_blocks`. This tool creates or updates blocks on a page.

Key parameters:
- `page` — target page name (e.g., `"2026/03/10"` or `"My Notes"`)
- `blocks` — array of block objects with `content` and optional `children`

For today's journal page, detect the format first (see **Detecting Journal Page Format** below).

## Block Structure

Logseq uses an outliner model — every piece of content is a block, and blocks can nest. Structure entries as follows:

### Standard Entry Pattern

```json
{
  "page": "2026/03/10",
  "blocks": [
    {
      "content": "Entry title or summary #claude-managed #relevant-tag\ntype:: note\nsource:: claude-code",
      "children": [
        { "content": "Main content goes here" },
        { "content": "Additional detail or sub-point",
          "children": [
            { "content": "Nested detail if needed" }
          ]
        }
      ]
    }
  ]
}
```

Properties (`key:: value`) and tags (`#tag`) go **inline on the parent block**, not as separate child blocks.

### Entry Types and Templates

**Note:**
```
Summary of the note #claude-managed #note
type:: note
source:: claude-code
```

**Task:**
```
TODO Task description #claude-managed #task
type:: task
priority:: A
```
Use `TODO` prefix for tasks. Priority values: A (high), B (medium), C (low).

**Code Snippet:**
```
Code snippet: brief description #claude-managed #code
type:: code
language:: python
source:: claude-code
```
Put the actual code block as a child using standard markdown fenced code blocks.

**Meeting Note:**
```
Meeting: [topic/title] #claude-managed #meeting
type:: meeting
date:: [[2026-03-10]]
attendees::
```

**Insight/Learning:**
```
Insight: [brief summary] #claude-managed #insight
type:: insight
source:: claude-code
```

## Section Grouping (Optional)

For structured journal pages, entries can be nested under a section heading block to group related content. This makes the daily journal more scannable:

```json
{
  "page": "2026/03/10",
  "blocks": [
    {
      "content": "## Meetings",
      "children": [
        {
          "content": "Meeting: 1:1 with manager #claude-managed #meeting\ntype:: meeting\ndate:: [[2026-03-10]]",
          "children": [...]
        }
      ]
    }
  ]
}
```

Use section headings when the user's journal already uses this convention, or when capturing multiple entries of the same type in one call. For single quick captures, a flat top-level block is preferred — less friction, easier to scan in reverse chronological order.

Common section names: `## Meetings`, `## Tasks`, `## Notes`, `## Captures`

## Tagging Conventions

- Always include `#claude-managed` on every entry created by Claude
- Add 1-3 additional semantic tags based on content
- Use lowercase kebab-case for custom tags: `#my-tag`, `#project-alpha`
- Reference Logseq pages with double brackets: `[[Page Name]]`

## Date Handling

- Today's journal page: compute from current date using the detected format (see below)
- Date references in properties: use `[[YYYY-MM-DD]]` format
- Never hardcode dates — always compute from the current session date

## Detecting Journal Page Format

Logseq's journal page name format is user-configurable (e.g. `yyyy/MM/dd`, `MM-dd-yyyy`, `yyyyMMdd`). Resolve it using this priority order:

1. **Project setting** — check `.claude/logseq.local.md` for `journal_format`. If present, use it directly.
2. **Global setting** — check `~/.claude/logseq.local.md` for `journal_format`. If present, use it directly.
3. **Auto-detect** — call `mcp__graphthulhu__list_pages` (sortBy: modified, limit: 20), find the first entry where `"journal": true`, and match its name against today's known date to infer the format.
4. **Fallback** — if no journal pages are found (new graph), use `YYYY/MM/DD`.

**Example:** if today is 2026-03-11 and a journal page is named `"2026/03/11"`, the format is `YYYY/MM/DD`.

## Reading Settings

Before capturing, check for settings in order: `.claude/logseq.local.md` (project-level) then `~/.claude/logseq.local.md` (global). Project settings take precedence. Parse for:
- `default_page` — override the default target page
- `journal_format` — explicit journal page name format (e.g. `YYYY/MM/DD`, `MM-dd-yyyy`); skips auto-detection when set
- `api_url` — custom Logseq API URL (if not using default)

See `references/setup-guide.md` for settings file format.

## Capture Workflow

**For structured capture (`/logseq:capture`):**
1. Determine target page (user-specified or today's journal)
2. Identify entry type from context
3. Prompt for any missing required fields (title, content)
4. Construct block with inline properties and tags
5. Call `mcp__graphthulhu__upsert_blocks`
6. Confirm success with page name and block preview

**For quick capture (`/logseq:quick-capture`):**
1. Take the provided text as content
2. Infer type from text (TODO prefix → task, code blocks → code snippet, else → note)
3. Write to today's journal with minimal properties
4. Confirm with a one-line summary

**For last-response capture (`/logseq:capture-last`):**
1. Use the most recent Claude response as content
2. Summarize it into a title (first sentence or 10 words)
3. Write as a note entry to today's journal
4. Include `source:: claude-code` property

## Error Handling

If `upsert_blocks` fails:
- Check if graphthulhu MCP tools are listed — if not, show setup guide
- Check if Logseq is running with HTTP API enabled
- Suggest running the `logseq-setup` agent for automated diagnostics

## When NOT to Use

- When the user wants to **read** from Logseq (use `mcp__graphthulhu__get_page`, `journal_range`, or `search` directly)
- When the user wants to **manage or reorganize** Logseq pages (use graphthulhu tools directly)
- When capturing to a non-Logseq note-taking system

## Work Tracking Conventions

Commands that implement work tracking use the following conventions. Both `/logseq:work-log` and `/logseq:new-work-page` delegate to these definitions.

### Work Log Sections

Work-log entries are appended to today's journal under these section headings (created on demand if absent):

- `## In Progress` — active work items
- `## Done` — completed items
- `## Blocked` — items waiting on something
- `## Next` — planned upcoming work

Section headings are created as parent blocks; work items are their children.

### Work Log Entry Format

```
[[JIRA/PROJ-123]] description of work #claude-managed #work-log [HH:MM]
```

- Tags come immediately after the description, before the timestamp
- Timestamp `[HH:MM]` (local time, 24h) is appended at the end
- Page references use `[[double brackets]]` for Logseq auto-linking
- No `type::` or `source::` properties — high-frequency journal entries use the `#work-log` tag as the type signal

### Work Page Naming

| Type | Argument | Page name |
|------|----------|-----------|
| JIRA ticket | `jira PROJ-123` | `JIRA/PROJ-123` |
| Pull Request | `pr myrepo 42` | `PR/myrepo/42` |
| Repo/service | `repo my-service` | `Repo/my-service` |

### Work Page Properties

**JIRA page:**
```
JIRA/PROJ-123 #claude-managed #jira
status:: in-progress
sprint::
repo::
prs::
```

**PR page:**
```
PR/myrepo/42 #claude-managed #pr
status:: open
jira::
repo:: [[Repo/myrepo]]
opened:: [[YYYY-MM-DD]]
merged::
```

**Repo page:**
```
Repo/my-service #claude-managed #repo
team::
stack::
```

## Additional Resources

- **`references/setup-guide.md`** — graphthulhu installation, Logseq API setup, settings file format
- **`references/block-examples.md`** — worked upsert_blocks examples for all entry types
