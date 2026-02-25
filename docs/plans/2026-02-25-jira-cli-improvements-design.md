# jira-cli SKILL.md Restructure — Design

Date: 2026-02-25

## Goal

Restructure jira-cli SKILL.md to be a focused agent guide. Remove duplicate
reference material (already in commands.md), reorganize sections for agent
readability, and add missing patterns for discovery and batch operations.

## Approach

Restructure (Approach A). SKILL.md becomes a workflow/patterns guide;
commands.md remains the flag reference. Net result: slightly shorter document
with better coverage.

## New Structure

```
1. Prerequisites           (keep as-is)
2. Critical Rules          (keep as-is)
3. Foundations
   a. Choosing Flags vs JQL  (keep)
   b. Reading Output         (trim — keep parsing examples, remove flag lists)
   c. Defensive Patterns     (MOVE UP from end of document)
4. Discovery Patterns        (NEW)
   - Project keys, sprint IDs, status names, custom field IDs, issue types
5. Common Workflows          (EXPAND from 4 to 8)
   - Existing: Start of Day, Pick Up Issue, Complete Issue, Create Bug
   - New: Batch Create, Batch Transition, Triage Backlog, Sprint Planning
6. Issue Operations          (TRIM — one example per op, remove flag catalogs)
7. Epics / Sprints / Projects (TRIM — one example each, refer to commands.md)
8. Error Handling            (expand — add custom field errors, partial batch)
9. Footer: "See references/commands.md for full flag documentation"
```

## Changes in Detail

### 1. Move Defensive Patterns Up

Move pagination, rate limiting, and retry patterns from end of document to
section 3c (Foundations). Agents need these patterns *before* attempting
operations, not as an afterthought.

### 2. Add Discovery Patterns (New Section)

Teaches the agent how to find IDs and names before running commands:

- **Project keys** — `jira project list --plain` with awk extraction
- **Sprint IDs** — extract from `jira sprint list --state active --table --plain`
- **Status names** — `jira issue view --raw | jq` for valid transitions
- **Custom field IDs** — `--raw | jq '.fields | keys[]'` discovery
- **Issue types** — note types vary by project, suggest safe defaults

### 3. Expand Common Workflows (4 New)

- **Batch Create Issues** — loop with sleep 1 for rate limiting, capture keys
  with `--raw | jq -r '.key'`
- **Batch Transition Issues** — pipe keys from list query through loop, continue
  on failure, report failures
- **Triage Backlog** — query unassigned issues, assign/prioritize/label
- **Sprint Planning** — find sprint ID, query candidates, add to sprint

### 4. Trim Duplicate Content

Remove ~80 lines of flag documentation that repeats commands.md:

- **Reading Output** — remove column list and flag explanations, keep only
  awk/jq parsing examples
- **Issue Operations** — keep one example per operation, remove flag-by-flag
  demonstrations
- **Epics/Sprints/Projects** — trim to one example each, add commands.md
  reference

### 5. Expand Error Handling

Add two error types:

- **Custom field errors** — link to discovery pattern
- **Partial batch failure** — report successes and failures, retry only failures

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Defensive patterns placement | Section 3 (Foundations) | Agents need these before operations |
| Duplication strategy | Remove from SKILL.md | commands.md is the single source for flags |
| Batch patterns | Loop with sleep + error handling | Teaches rate-limit-safe operations |
| Discovery section | Separate section 4 | Cross-cutting concern, not tied to one command |
| Issue ops examples | One per operation | Patterns over reference; commands.md has full details |

## Files Modified

- `jira-cli/skills/jira-cli/SKILL.md` — restructure as described above
