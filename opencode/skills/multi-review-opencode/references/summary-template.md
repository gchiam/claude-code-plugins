# Summary Report Template

When writing `.multi-reviews/review-summary.md`, use the following structure:

```markdown
# Multi-Perspective Code Review Summary

**Target:** [PR #123 | branch feat/x | custom files]
**Reviewers:** [Correctness, Security, Test-Coverage]
**Date:** YYYY-MM-DD

## Executive Summary
- Total Findings: [N]
- Critical: [C] | Important: [I] | Suggestions: [S]

## Critical Issues (Must Address)
| File | Line | Reviewer(s) | Title | Description | Suggested Fix |
|---|---|---|---|---|---|
| path/to/file.ts | 42 | correctness, security | ... | ... | ... |

## Important Issues (Should Address)
| File | Line | Reviewer(s) | Title | Description | Suggested Fix |
|---|---|---|---|---|---|
| path/to/file.ts | 88 | test-coverage | ... | ... | ... |

## Suggestions & Improvements
- [ ] `path/to/file.ts:15`: Suggestion detail

## Review Agreement Analysis
- Findings confirmed by 2+ reviewers: [N]
```
