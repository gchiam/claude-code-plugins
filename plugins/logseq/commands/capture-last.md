---
name: logseq:capture-last
description: Capture the most recent Claude response to today's Logseq journal as a note
argument-hint: "[optional title override]"
allowed-tools:
  - mcp__graphthulhu__upsert_blocks
  - mcp__graphthulhu__list_pages
  - Read
---

Capture the most recent Claude response from this conversation to today's Logseq journal.

Follow this workflow:

1. **Check MCP availability**: Verify `mcp__graphthulhu__upsert_blocks` is accessible. If not, show a brief inline message:
   > graphthulhu MCP is not connected. Run the `logseq-setup` agent or see setup instructions in the logseq-capture skill.
   Then stop.

2. **Identify content**: Use the last substantive assistant response in this conversation (skip tool outputs and single-line confirmations).

3. **Build a title**:
   - If an argument was provided, use it as the title
   - Otherwise, summarize the response in ≤10 words as the title

4. **Check `.claude/logseq.local.md`** for `default_page` or `default_tags`. Apply if present.

5. **Detect journal page format**: Call `mcp__graphthulhu__list_pages` (sortBy: modified, limit: 20), find the first entry with `"journal": true`, and infer the date format from its name matched against today's known date. Fall back to `YYYY/MM/DD` if no journal pages are found.

6. **Build the block**:
   - Parent: `<title> #claude-managed #note\ntype:: note\nsource:: claude-code`
   - First child: full response content (truncate to first 500 words if very long, add note if truncated)
   - If response contained code blocks, preserve them as children with the code fenced

7. **Write to today's journal** using the detected page name via `mcp__graphthulhu__upsert_blocks`

8. **Confirm** with: `Captured to <today's journal page name> — "<title>"`

## Examples

```
/logseq:capture-last
/logseq:capture-last Notes on MCP lifecycle
```
