# Multi-Review Workflow Steps

## Phase 1: Target Resolution and Diff Triage
1. Parse flags or user input:
   - `--pr <number>`
   - `--branch <name>`
   - `--files <paths>`
2. If `--pr` is provided:
   - Run `gh pr view <NUMBER> --json baseRefName,headRefName,title,body`
   - Run `git diff origin/<baseRefName>...HEAD` (or fetch target PR ref)
3. If no target specified:
   - Inspect active branch and check if an open PR exists via `gh pr view`
   - Otherwise compare against tracking upstream branch or common merge-base
4. Build diff profile:
   - List of changed files and file extensions
   - High-risk surfaces (auth, API, crypto, migrations, core logic)
   - Presence of test files

## Phase 2: Parallel Reviewers Dispatch
1. Ensure `.multi-reviews/` exists (`mkdir -p .multi-reviews`).
2. Select 2-3 roles from `reviewer-roles.md` matching diff profile:
   - Always include `correctness`.
   - Include `security` if security-sensitive files or external input changed.
   - Include `test-coverage` if new features added or tests changed.
   - Include `architecture-perf` if performance-critical or backend paths changed.
3. Spawn subagents in parallel with `task(category="deep", run_in_background=true, prompt=...)`.
4. Wait for `<system-reminder>` completion notices and collect results using `background_output`.
5. Write raw responses to `.multi-reviews/raw-<role>.json` or `.md`.

## Phase 3: Validation Pass
1. Filter candidate findings with severity CRITICAL or IMPORTANT.
2. For candidate findings, dispatch parallel validation tasks with `category="quick"` or `subagent_type="general"`.
3. Validators verify:
   - Is this finding accurate against the actual code?
   - Is it already handled elsewhere?
   - Does it warrant the assigned severity?
4. Collect validation verdicts (CONFIRMED, DOWNGRADED, FALSE_POSITIVE).

## Phase 4: Aggregated Summary
1. Deduplicate matching findings across reviewers.
2. Order findings: CRITICAL, then IMPORTANT, then SUGGESTION.
3. Write final report to `.multi-reviews/review-summary.md`.
4. Output concise summary in chat with findings count and top issues.
