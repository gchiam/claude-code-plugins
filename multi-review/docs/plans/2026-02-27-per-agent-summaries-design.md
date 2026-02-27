# Per-Agent Inline Summaries

**Date:** 2026-02-27
**Status:** Approved

## Problem

When multi-review runs, users see nothing between agent launch and the final aggregated summary. To understand what each reviewer found, they must read individual `.multi-reviews/review-*.md` files. There's no real-time feedback during the review process.

## Solution

Print a per-agent summary to the console as each review agent completes, giving real-time feedback with severity counts and top finding previews.

## Design

### Phase 2 Flow Change

**Current:** Launch all agents → wait for all → write all files.

**New:** Launch all agents → collect results one-by-one via sequential `TaskOutput` → print summary + write file per agent → proceed when all done.

Agents still launch in parallel (single Task message with `run_in_background: true`). Only the result collection becomes sequential — no speed penalty.

### Console Output Format

After each agent's `TaskOutput` returns:

```text
[✓] Phase 2: Reviews (1/3 complete)
    ┌── coderabbit ──────────────────────────
    │ 2 critical · 3 important · 1 minor
    │ • SQL injection in user query (auth/db.ts:42)
    │ • Missing rate limiting on /api/login (routes/auth.ts:18)
    └────────────────────────────────────────
```

- Progress counter updates with each agent (`1/3`, `2/3`, `3/3`)
- Box header shows the agent's short name
- First line: severity counts (only non-zero categories shown)
- Following lines: 1-line preview of each critical and important finding (file:line + summary)
- If no critical/important findings: `No critical or important issues found`

### Files Changed

1. **`SKILL.md`** — Update Phase 2 section to describe the new collection-with-summary behavior
2. **`references/phase-templates.md`** — Update "Collecting Results" section with sequential collection pattern, per-agent summary format template, and parsing instructions

### Unchanged

- Phase 1 (Discovery), Phase 3 (Validation), Phase 4 (Aggregation) — no changes
- Agents still launch in parallel
- Review files still written to `.multi-reviews/review-<short-name>.md`
- No new CLI options, files, or dependencies
