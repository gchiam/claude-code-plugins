---
name: logseq:new-work-page
description: Create a new Logseq page for a JIRA ticket, pull request, or repo/service with a structured property template
argument-hint: "[type] [identifier] — e.g. 'jira PROJ-123', 'pr myrepo 42', 'repo my-service'"
allowed-tools:
  - mcp__graphthulhu__upsert_blocks
  - mcp__graphthulhu__get_page
  - Read
---

Create a named Logseq page for a JIRA ticket, PR, or repo/service, pre-populated with a structured property template.

Follow the Work Tracking Conventions in the logseq SKILL.md for page naming and property templates.

## Workflow

1. **Check MCP availability**: Verify `mcp__graphthulhu__upsert_blocks` is accessible. If not, show:
   > graphthulhu MCP is not connected. Run the `logseq-setup` agent or see setup instructions in the logseq skill.
   Then stop.

2. **Resolve type and identifier**:
   - If arguments were provided, parse them: first token is type (`jira`, `pr`, `repo`), remaining tokens are the identifier
   - If no arguments, prompt: "What type of page? (jira / pr / repo) and what is the identifier?"

3. **Derive page name** using Work Tracking Conventions in SKILL.md:
   - `jira PROJ-123` -> `JIRA/PROJ-123`
   - `pr myrepo 42` -> `PR/myrepo/42`
   - `repo my-service` -> `Repo/my-service`

4. **Check if page exists**: Call `mcp__graphthulhu__get_page` with the derived page name.
   - If the page already exists: warn the user and stop.
     > Page `JIRA/PROJ-123` already exists. To start fresh, manually clear or rename it in Logseq, then re-run this command.
   - If the page does not exist: proceed.

5. **Write the page**: Call `mcp__graphthulhu__upsert_blocks` with the type-specific template. See `plugins/logseq/skills/logseq/references/block-examples.md` sections "Work Page: JIRA ticket", "Work Page: Pull Request", and "Work Page: Repo/Service" for the exact JSON. Use today's date for the `opened::` property on PR pages (format: `[[YYYY-MM-DD]]`).

6. **Confirm**:
   > Created page `JIRA/PROJ-123`

## Examples

```
/logseq:new-work-page jira PROJ-123
/logseq:new-work-page pr myrepo 42
/logseq:new-work-page repo my-service
/logseq:new-work-page
```
