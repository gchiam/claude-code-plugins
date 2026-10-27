# Summary Report Template

When writing `.review-panel/review-summary.md`, use the following structure:

```markdown
# Multi-Perspective Code Review Summary

**Target:** [PR #123 | branch feat/x | custom files]
**Base:** [resolved base ref]
**Review lanes:** [arbiter (Opus 5.5), hunter (session model), proctor (session model), …]
**Degraded lanes:** [none | paladin — unavailable, reviewed inline]
**Date:** YYYY-MM-DD

## Executive Summary
- Total Findings: [N]
- Critical: [C] | Important: [I] | Suggestions: [S]
- Validation: [X confirmed, Y downgraded, Z false positives discarded]

## Critical Issues (Must Address)
| File | Line | Agent(s) | Verdict | Title | Description | Suggested Fix |
|---|---|---|---|---|---|---|
| path/to/file.ts | 42 | arbiter, paladin | CONFIRMED | ... | ... | ... |

## Important Issues (Should Address)
| File | Line | Agent(s) | Verdict | Title | Description | Suggested Fix |
|---|---|---|---|---|---|---|
| path/to/file.ts | 88 | proctor | DOWNGRADED | ... | ... | ... |

## Suggestions & Improvements
- [ ] `path/to/file.ts:15` (agent): Suggestion detail

## Review Agreement Analysis
- Findings confirmed by 2+ lanes: [N]

## Council Verdicts (only if user opted in)
- [Finding title]: [verdict + councillors' positions]

## Follow-up
- Remediation available on request via `fixer` (out of review scope).
```

Notes:
- `Agent(s)` and `Verdict` columns are required; verdict is one of CONFIRMED,
  DOWNGRADED, FALSE_POSITIVE (FALSE_POSITIVE rows are removed from the tables
  and only counted in the Executive Summary).
- SUGGESTION findings skip validation; show them without a verdict.
- Omit the Council section entirely unless a council pass ran.
