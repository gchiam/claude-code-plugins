---
name: logseq:work-log
description: Append timestamped work-log entries to today's Logseq journal under structured sections (In Progress / Done / Blocked / Next)
argument-hint: "[optional: pre-fill entries, e.g. 'done: [[JIRA/PROJ-123]] fixed auth bug']"
allowed-tools:
  - mcp__graphthulhu__upsert_blocks
  - mcp__graphthulhu__get_page
  - mcp__graphthulhu__list_pages
  - Read
---

Append new work items to today's Logseq journal under section headings.

Follow the Work Tracking Conventions in the logseq SKILL.md for section names, entry format, and timestamp format.

## Workflow

1. **Check MCP availability**: Verify `mcp__graphthulhu__upsert_blocks` is accessible. If not, show:
   > graphthulhu MCP is not connected. Run the `logseq-setup` agent or see setup instructions in the logseq skill.
   Then stop.

2. **Detect journal page format**: Follow the four-step detection in SKILL.md (check `.claude/logseq.local.md`, then `~/.claude/logseq.local.md`, then auto-detect via `mcp__graphthulhu__list_pages`, then fall back to `YYYY/MM/DD`).

3. **Read today's journal**: Call `mcp__graphthulhu__get_page` with today's journal page name. Note which of the four section headings already exist: `## In Progress`, `## Done`, `## Blocked`, `## Next`. If the page does not exist yet (fresh day) or returns empty, treat all four headings as absent and proceed normally.

4. **Prompt for new items**: Ask the user in a single message what they would like to add. If arguments were provided, parse them as pre-filled items and confirm before writing.

5. **Append each item**:
   - Determine the correct section for each item
   - Get the current local time in `HH:MM` format
   - Format the block as: `<description> #claude-managed #work-log [HH:MM]`
     - If the content references a JIRA ticket or PR, use `[[JIRA/TICKET-ID]]` or `[[PR/repo/num]]` page references
   - If the section heading **exists**: append the item as a child of that heading block
   - If the section heading **does not exist**: write a single `upsert_blocks` call with the heading as parent and the item as its child (see `plugins/logseq/skills/logseq/references/block-examples.md`, section "Work Log Entry (section does not exist)" for the exact JSON shape)

6. **Confirm**: Summarise what was appended, e.g.:
   > Added to 2026/03/12:
   > - In Progress: [[JIRA/PROJ-123]] investigating auth bug [09:32]
   > - Done: [[PR/myrepo/42]] merged auth refactor [09:33]

## Examples

```
/logseq:work-log
/logseq:work-log done: [[JIRA/PROJ-123]] fixed auth bug
```
