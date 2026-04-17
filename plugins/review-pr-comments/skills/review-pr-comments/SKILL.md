---
name: review-pr-comments
description: >-
  Use when the user wants to review, triage, or action PR review comments on a
  pull request. Fetches all open review comments from a PR, summarises them by
  severity and file, and helps the user decide which comments to address, dismiss,
  or defer.
user-invocable: true
disable-model-invocation: false
argument-hint: "[--pr <number>] [--repo <owner/repo>]"
metadata:
  owner: gchiam
  use_cases:
    - engineering
    - code-review
    - pr-review
  complexity: standard
---

# Review PR Comments

TODO: Add full skill instructions here.

## Rules

1. Always fetch comments from the PR before summarising.
2. Group comments by file and severity.
3. Never auto-dismiss or auto-resolve comments without user confirmation.

## When NOT to Use

- When the PR has no open review comments.
- When the user wants to write a new code review (use `multi-review` instead).
- When the user wants to review the PR description (use `pr-desc-review` instead).
