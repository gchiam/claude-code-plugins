---
name: logseq:capture-last
description: Capture the most recent Claude response to today's Logseq journal as a note
argument-hint: "[optional title override]"
allowed-tools:
  - mcp__graphthulhu__upsert_blocks
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

5. **Build the block**:
   - Parent: `<title> #claude-managed #note\ntype:: note\nsource:: claude-code`
   - First child: full response content (truncate to first 500 words if very long, add note if truncated)
   - If response contained code blocks, preserve them as children with the code fenced

6. **Write to today's journal** (`YYYY/MM/DD`) using `mcp__graphthulhu__upsert_blocks`

7. **Confirm** with: `Captured to YYYY/MM/DD — "<title>"`

## Examples

```
/logseq:capture-last
/logseq:capture-last Notes on MCP lifecycle
```
