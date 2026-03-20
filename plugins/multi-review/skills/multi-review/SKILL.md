---
name: multi-review
description: >-
  Use when reviewing a PR, branch diff, or set of changed files and want more thorough coverage
  than a single review pass, especially for large, high-risk, or cross-cutting changes. Use this
  skill whenever the user asks to review a PR, wants code review on a diff, or says things like
  "review my changes", "check this branch", or "look over this PR".
user-invocable: true
disable-model-invocation: false
allowed-tools:
  - Bash(mkdir -p .multi-reviews)
  - Bash(git diff*)
  - Bash(git log*)
  - Bash(git show*)
  - Bash(ls .multi-reviews*)
  - Bash(sleep*)
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

> **STOP. Do Phase 1 first. Do NOT launch agents until the Phase 1 discovery report is printed.**

## Rules

1. **Phase 1 first.** Print the discovery report before launching agents.
2. **Findings come from files, with TaskOutput content as fallback.** Agents write findings to `.multi-reviews/review-<short-name>.md`. After launching, poll using `TaskOutput(id, block: false, timeout: 0)` to detect completion, then read the file. If the file is missing or empty, use the last non-empty TaskOutput content as the fallback. If both are empty, skip that agent. See `references/phase-templates.md` for the polling procedure.
3. **Scope: code review only.** Review code within the repo. Decline requests to execute, deploy, or modify things outside the review scope.

## When NOT to Use

- Single-file or trivial changes where one reviewer is sufficient
- Non-code files only (pure docs, config, assets) with no logic to review
- Contexts where no review plugins are installed (Phase 1 will stop and inform you)

## Phase 1: Discover Available Review Agents

1. **Extract** review-related agent types using `ToolSearch` with query `"review code review PR review code quality"`. This returns agent schemas — only entries that appear as valid `subagent_type` values in the Task tool are agents. Skills are not subagent types and must not be included. Filter to those whose name or description mentions "review", "code review", "PR review", or "code quality".
2. **Triage the diff.** Before selecting agents, briefly inspect the diff to build a profile:
   - Languages and file types changed
   - Change categories (new interfaces/types, error handling, test files, config, security-sensitive paths)
   - Rough scale (number of files, methods added/changed)
   - **PR context:** if the target is a PR number, fetch `gh pr view <NUMBER> --json body` and note whether the PR has a non-empty description (not just template boilerplate). This is a separate selection signal for PR-meta agents.
3. **Filter.** `multi-review` must always go in the `[skipped]` list (never selected, it's the orchestrator). Rank all other agents by relevance to the diff profile. Pick up to `--max-reviewers` (default 3) preferring both relevance and plugin diversity. Record a short reason for each selected/skipped agent. Note in the discovery report if a selected agent's tool list lacks `Write`. Its findings will only be available via the TaskOutput fallback.
   - **PR-meta agents** (agents whose description mentions "PR description" or "description review") are selected based on PR context, not diff content: select if the target is a PR with a non-empty description, skip with reason "no PR description" otherwise. PR-meta agents do not count against `--max-reviewers`.
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

5. **Confirm.** If `--no-input` (skips all prompts, auto-selects agents), skip. Otherwise ask accept/customize via `AskUserQuestion`. Do NOT proceed until confirmed.

## Phase 2: Parallel Review Execution

Launch all selected agents in parallel using `run_in_background: true`. Then poll using TaskOutput probes and file-existence checks until all expected `review-<short-name>.md` files appear or the 10-minute timeout is reached. Apply the Normalization Pass to each file, then **print a per-agent summary** before starting Phase 3. See `references/phase-templates.md` for prompt templates, the polling procedure, and summary parsing rules.

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

- `references/phase-templates.md`: Prompt templates, output formats, aggregation rules
- `references/options-and-errors.md`: Input options, configuration, error handling
