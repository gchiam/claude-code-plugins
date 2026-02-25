# jira-cli SKILL.md Improvements — Design

Date: 2026-02-25

## Goal

Improve the jira-cli plugin's SKILL.md with three high-impact additions that
address gaps in setup guidance, output parsing, and defensive patterns for
batch operations.

## Approach

Inline additions to the existing SKILL.md (Approach A). No structural
reorganization. Adds ~70 lines total.

## Changes

### 1. Prerequisites/Setup Section (~14 lines)

**Placement**: After intro paragraph (line 22), before "Critical Rules".

Adds a quick checklist:
1. Install via brew (with link to full install docs)
2. Run `jira init`
3. Export `JIRA_API_TOKEN`
4. Verify with `jira serverinfo --plain`

Includes troubleshooting for failed verification (token, config path, network).

### 2. Expanded Output Parsing (~25 lines)

**Placement**: Appended to existing "Reading Output" section (after line 82).

Three subsections:
- **Parsing Plain Output** — `awk -F'\t'` patterns for extracting columns,
  filtering rows
- **Parsing JSON Output** — `jq` patterns for description, custom fields,
  list-to-array
- **Special Characters** — guidance to prefer `--raw` for freeform text fields

### 3. Defensive Patterns Section (~30 lines)

**Placement**: New section before "Error Handling" (before line 333).

Three subsections:
- **Pagination** — explicit `--paginate` with stop condition
- **Rate Limiting** — 429 handling, spacing sequential commands, preferring
  batch flags
- **Retry on Transient Errors** — retry loop for timeouts/5xx, no retry on 4xx

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Setup depth | Quick checklist | Users can follow jira-cli docs for platform details |
| Batch focus | Defensive patterns only | Teaches good API citizenship without complex orchestration |
| Structure | Inline in SKILL.md | Claude always sees the guidance; no extra file reads |

## Files Modified

- `jira-cli/skills/jira-cli/SKILL.md` — three additions as described above
