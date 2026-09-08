---
name: multi-review
description: Use when reviewing a PR, branch diff, or set of changed files with multiple parallel specialist perspectives (correctness, security, test coverage, and performance).
---

# OpenCode Multi-Review

Run multi-perspective code reviews using parallel OpenCode subagents, independent validation passes, and aggregated summary reports.

## Core Rules

1. Scope: code review only. Never modify source files or apply automated fixes during review.
2. Never assume main is the base branch. Resolve base branch from PR metadata or git tracking.
3. Use background tasks for parallel review execution.
4. Normalize and validate findings before reporting.
5. Store artifacts in .multi-reviews/.
