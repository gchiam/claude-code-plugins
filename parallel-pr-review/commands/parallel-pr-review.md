---
description: Run parallel PR review with two complementary methodologies
argument-hint: "[--pr <number>] [--confidence <0-100>] [--max-reviewers <N>] [--output-dir <path>]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Write", "Task"]
---

# Parallel PR Review Command

Run a comprehensive PR review using multiple independent review commands in parallel.

**Arguments:** $ARGUMENTS

## Instructions

Use the `parallel-pr-review` skill to execute a multi-phase review:

1. Discover available review commands in the environment (exclude parallel-pr-review itself)
2. Run discovered review commands in parallel (up to `--max-reviewers`, default 3)
3. Validate findings to filter false positives
4. Aggregate into a deduplicated summary

Pass through any arguments provided: $ARGUMENTS

**Important:** Do NOT post comments to the PR. Save all output to markdown files.
