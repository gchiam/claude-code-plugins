---
description: Run parallel PR review with two methodologies
argument-hint: "[--pr <number>] [--confidence <0-100>] [--output-dir <path>]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Write", "Task"]
---

# Parallel PR Review Command

Run a comprehensive PR review using two independent review skills in parallel.

**Arguments:** $ARGUMENTS

## Instructions

Use the `parallel-pr-review` skill to execute a multi-phase review:

1. Validate required skills are installed
2. Run code-review:code-review and pr-review-toolkit:review-pr in parallel
3. Validate findings to filter false positives
4. Aggregate into a deduplicated summary

Pass through any arguments provided: $ARGUMENTS

**Important:** Do NOT post comments to the PR. Save all output to markdown files.
