---
name: multi-review
description: >-
  Use when reviewing a PR with parallel multi-agent code reviews,
  validated findings, and an aggregated deduplicated summary
user-invocable: true
disable-model-invocation: false
allowed-tools:
  - Bash(mkdir -p .multi-reviews)
  - Read(.multi-reviews/**)
  - Write(.multi-reviews/**)
  - Edit(.multi-reviews/**)
argument-hint: "[--pr <number>] [--branch <name>] [--files <paths>]"
model:
context:
agent:
hooks:
metadata:
  owner: gchiam
  use_cases:
    - engineering
    - code-review
    - pr-review
  complexity: standard
---

# Multi Review

> **STOP. Phase 1 first. Do NOT launch agents until the discovery report is printed.**

## Rules

1. **Phase 1 first.** Print the discovery report before anything else.
2. **Wait for all agents.** `TaskOutput` with `block: true` on every agent ID before writing files or starting the next phase.

## Phase 1: Discover Available Review Agents

1. **Extract** review-related agent types from the Task tool's `subagent_type` list (names/descriptions mentioning "review", "code review", "PR review", "code quality").
2. **Filter** — exclude `multi-review`; pick most review-focused per plugin; select up to `--max-reviewers` (default 3) preferring diversity.
3. **Print** the discovery report in this exact format:

```text
Multi Review - PR #<NUMBER>
════════════════════════════════════════

[✓] Phase 1: Discovered <N> review agents (max-reviewers: <MAX>):
    ├── [selected] <agent-type>
    ├── [selected] <agent-type>
    ├── [selected] <agent-type>
    └── [skipped]  <agent-type>       # one line per agent; └── for last
```

   If zero agents found, **STOP** and inform the user to install review plugins.

4. **Confirm** — if `--no-input`, skip. Otherwise ask accept/customize via `AskUserQuestion`. Do NOT proceed until confirmed.

## Phase 2: Parallel Review Execution

Launch one agent per selected type in a single Task message with `run_in_background: true`. Wait for all via `TaskOutput`. Write results to `review-<short-name>.md`.

See [references/phase-templates.md](references/phase-templates.md) for prompt templates and output file format.

## Phase 3: Parallel Validation

Launch one validator per review output. Filter false positives, assess severity and confidence. Write to `validated-<short-name>.md`. Skip if `--skip-validation`.

See [references/phase-templates.md](references/phase-templates.md) for validator prompt.

## Phase 4: Aggregate Summary

Deduplicate, categorize by severity, cross-reference sources, write `pr-review-summary.md`.

See [references/phase-templates.md](references/phase-templates.md) for aggregation rules.

## Post-Review Actions

Offer: view summary, generate fixes, create GitHub issues, post to PR (requires approval), re-run on specific files, or exit.

## References

- [Phase Templates](references/phase-templates.md) — Prompt templates, output formats, aggregation rules
- [Options & Error Handling](references/options-and-errors.md) — Input options, configuration, error handling
