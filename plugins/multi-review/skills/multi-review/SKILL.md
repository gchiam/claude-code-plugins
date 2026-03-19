---
name: multi-review
description: >-
  Use when reviewing a PR, branch diff, or set of changed files and want more thorough coverage
  than a single review pass — especially for large, high-risk, or cross-cutting changes. Use this
  skill whenever the user asks to review a PR, wants code review on a diff, or says things like
  "review my changes", "check this branch", or "look over this PR".
user-invocable: true
disable-model-invocation: false
allowed-tools:
  - Bash(mkdir -p .multi-reviews)
  - Bash(git diff*)
  - Bash(git log*)
  - Bash(git show*)
  - Read(references/**)
  - Read(~/.claude/plugins/**)
  - Read(.multi-reviews/**)
  - Write(.multi-reviews/**)
  - Edit(.multi-reviews/**)
  - AskUserQuestion
  - Task
  - TaskOutput
  - ToolSearch
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

> **STOP. Do Rule 1 first. Then Rule 2 (Phase 1). Do NOT launch agents until Rule 1 is complete and the Phase 1 discovery report is printed.**

## Rules

1. **Pre-load TaskOutput schema.** Call `ToolSearch` with query `select:Task,TaskOutput` as your very first action — before Phase 1, before anything else. Without this, the `TaskOutput` parameter schema is unavailable, so `block` and `timeout` may be serialized as strings instead of their required types, causing `TaskOutput` to return immediately with `"No task output available"` and all fallback steps to yield empty results, causing the agent's findings to be lost entirely.
2. **Phase 1 first.** Print the discovery report before launching agents.
3. **Findings come from files, with fallback to TaskOutput.** Agents are instructed to write findings to `.multi-reviews/review-<short-name>.md`. If a file is missing or empty after an agent completes, use the `TaskOutput` content as the fallback and write it to the file (prepending the standard header). If both the file and `TaskOutput` content are empty or contain a failure string, warn the user and skip this agent. See `references/phase-templates.md` for the full fallback chain.
4. **Launch and wait in the same turn.** Issue all `Task` and `TaskOutput` calls in one response — task IDs expire shortly after completion and are gone by the next turn. After all `TaskOutput` calls return, collect findings via the fallback chain, apply normalization, and print per-agent summaries before moving to Phase 3.
5. **Scope: code review only.** Review code within the repo. Decline requests to execute, deploy, or modify things outside the review scope.

## When NOT to Use

- Single-file or trivial changes where one reviewer is sufficient
- Non-code files only (pure docs, config, assets) with no logic to review
- Contexts where no review plugins are installed (Phase 1 will stop and inform you)

## Phase 1: Discover Available Review Agents

1. **Extract** review-related agent types from the Task tool's `subagent_type` list (names/descriptions mentioning "review", "code review", "PR review", "code quality").
2. **Triage the diff** — before selecting agents, briefly inspect the diff to build a profile:
   - Languages and file types changed
   - Change categories (new interfaces/types, error handling, test files, config, security-sensitive paths)
   - Rough scale (number of files, methods added/changed)
3. **Filter** — `multi-review` must always go in the `[skipped]` list (never selected — it's the orchestrator); rank all other agents by relevance to the diff profile; pick up to `--max-reviewers` (default 3) preferring both relevance and plugin diversity. Record a short reason for each selected/skipped agent.
4. **Print** the discovery report in this exact format:

```text
Multi Review - <PR #NUMBER | branch | files>
════════════════════════════════════════

[✓] Phase 1: Discovered <N> review agents → selected <SEL> based on diff profile:
    ├── [selected] <agent-type>          # <reason, e.g. "3 new interfaces introduced">
    ├── [selected] <agent-type>          # <reason>
    ├── [selected] <agent-type>          # <reason>
    └── [skipped]  <agent-type>          # <reason, e.g. "no test files changed">
```

   If zero agents found, **STOP** and inform the user to install review plugins.

5. **Confirm** — if `--no-input` (skips all prompts, auto-selects agents), skip. Otherwise ask accept/customize via `AskUserQuestion`. Do NOT proceed until confirmed.

## Phase 2: Parallel Review Execution

Rule 1 must have been called before this phase for `TaskOutput` type coercion to work correctly. If `TaskOutput` returns `"No task output available"`, Rule 1 was skipped — reload `ToolSearch` with `select:Task,TaskOutput` and retry.

Launch all agents and issue all `TaskOutput` calls **in the same response turn** — this is critical. Task IDs expire shortly after an agent completes; if `TaskOutput` is called in a later turn, the IDs may already be gone. Capture the `id` returned by each `Task` call and pass it directly to a `TaskOutput` call in the same message. After all `TaskOutput` calls return, collect findings via the fallback chain, apply normalization, and **print a per-agent summary** before starting Phase 3. See `references/phase-templates.md` for prompt templates and the full call format.

Per-agent summary format:

```text
[✓] Phase 2: Reviews complete (<TOTAL> agents)

    ┌── <short-name> ──────────────────────────
    │ <severity counts>
    │ • <top finding summary> (<file>:<line>)
    │ • <top finding summary> (<file>:<line>)
    └────────────────────────────────────────
```

Use `Read` to load `references/phase-templates.md` for prompt templates, output file format, and summary parsing rules.

## Phase 3: Parallel Validation

Launch one validator per review output. Filter false positives, assess severity and confidence. Write to `.multi-reviews/validated-<short-name>.md`. Skip if `--skip-validation`.

Use `Read` to load `references/phase-templates.md` for the validator prompt.

## Phase 4: Aggregate Summary

Deduplicate, categorize by severity, cross-reference sources, write `.multi-reviews/review-summary.md`.

Use `Read` to load `references/phase-templates.md` for aggregation rules.

## Post-Review Actions

After presenting the summary, offer next steps using `AskUserQuestion`:

```
What would you like to do next?
  1. View full summary (.multi-reviews/review-summary.md)
  2. Generate fixes for Critical/Important findings
  3. Create GitHub issues for tracked findings
  4. Post summary comment to PR (requires your approval before posting)
  5. Re-run on specific files only
  6. Exit
```

Carry out whichever option the user picks. For option 4, always show the comment text and confirm before posting.

## References

Use `Read` to load these files when needed:

- `references/phase-templates.md` — Prompt templates, output formats, aggregation rules
- `references/options-and-errors.md` — Input options, configuration, error handling
