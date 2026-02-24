---
description: Run multi-perspective code review with validation and aggregation
argument-hint: "[--pr <number>] [--confidence <0-100>] [--max-reviewers <N>] [--output-dir <path>]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Write", "Task"]
---

# Multi Review Command

Run a comprehensive PR review using multiple independent review commands in parallel.

**Arguments:** $ARGUMENTS

## Instructions

Use the `multi-review` skill to execute a multi-phase review:

1. Discover available review commands in the environment (exclude multi-review itself)
2. Run discovered review commands in parallel (up to `--max-reviewers`, default 3)
3. Validate findings to filter false positives
4. Aggregate into a deduplicated summary

Pass through any arguments provided: $ARGUMENTS

**Important:** Do NOT post comments to the PR. Save all output to markdown files.
