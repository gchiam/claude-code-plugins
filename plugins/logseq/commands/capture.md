---
name: logseq:capture
description: Structured capture to Logseq — prompts for page, entry type, title, content, and tags before writing
argument-hint: "[page name] (optional — defaults to today's journal)"
allowed-tools:
  - mcp__graphthulhu__upsert_blocks
  - mcp__graphthulhu__get_page
  - mcp__graphthulhu__list_pages
  - Read
---

Capture a structured entry to the user's Logseq graph using the logseq-capture skill.

Follow this workflow:

1. **Check MCP availability**: Verify `mcp__graphthulhu__upsert_blocks` is accessible. If not, show the setup instructions from the logseq-capture skill's `references/setup-guide.md` and stop.

2. **Determine target page**:
   - If an argument was provided, use it as the page name
   - Check `.claude/logseq.local.md` then `~/.claude/logseq.local.md` for a `default_page` setting (project takes precedence)
   - Otherwise, resolve journal page format: check `.claude/logseq.local.md` then `~/.claude/logseq.local.md` for `journal_format` and use it if present; else call `mcp__graphthulhu__list_pages` (sortBy: modified, limit: 20), find the first entry with `"journal": true`, infer the format from its name matched against today's known date; fall back to `YYYY/MM/DD` if none found.

3. **Collect entry details** (ask the user in a single message):
   - **Entry type**: note / task / code snippet / meeting note / insight (default: note)
   - **Title or summary**: one-line description
   - **Content**: the main body (can be multi-line)
   - **Additional tags**: beyond `#claude-managed` (optional)
   - **Page override**: confirm or change the target page

4. **Build the block** following the logseq-capture skill conventions:
   - Properties and tags inline on the parent block
   - Always include `#claude-managed` and `type:: <entry-type>`
   - Include `source:: claude-code`
   - Nest detail as child blocks

5. **Write to Logseq** using `mcp__graphthulhu__upsert_blocks`

6. **Confirm success**: Show the user the page name and a preview of the block content written.

If the write fails, check whether Logseq is running with the HTTP API enabled and suggest running the `logseq-setup` agent.

## Examples

```
/logseq:capture
/logseq:capture Projects/my-project
/logseq:capture Work/meetings
```
