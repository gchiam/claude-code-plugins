---
name: logseq:quick-capture
description: Quickly capture raw text to today's Logseq journal with minimal friction — pass content as argument
argument-hint: "<text to capture>"
allowed-tools:
  - mcp__graphthulhu__upsert_blocks
  - Read
---

Capture the provided text immediately to today's Logseq journal with no prompting.

Follow this workflow:

1. **Check MCP availability**: Verify `mcp__graphthulhu__upsert_blocks` is accessible. If not, show a brief inline message:
   > graphthulhu MCP is not connected. Run the `logseq-setup` agent or see setup instructions in the logseq-capture skill.
   Then stop.

2. **Take the argument as content**: The entire argument string is the content to capture.

3. **Infer entry type from content**:
   - Starts with `TODO` or `LATER` → task (keep the prefix)
   - Contains a fenced code block (` ``` `) → code snippet
   - Otherwise → note

4. **Check `.claude/logseq.local.md`** for `default_page` or `default_tags` settings. Apply them if present.

5. **Build a minimal block**:
   - Parent: `<content> #claude-managed #<inferred-type>\ntype:: <inferred-type>\nsource:: claude-code`
   - No child blocks (this is a quick capture — no nesting)

6. **Write to today's journal** (`YYYY/MM/DD`) using `mcp__graphthulhu__upsert_blocks`

7. **Confirm** with a single line: `Captured to YYYY/MM/DD`

## Examples

```
/logseq:quick-capture Interesting idea about MCP session lifecycle
/logseq:quick-capture TODO Review the auth PR before EOD
/logseq:quick-capture ```python\nprint("hello world")\n```
```
