# Multi-Review Workflow Steps

## Phase 1: Target Resolution and Diff Triage
1. Parse flags or user input:
   - `--pr <number>`
   - `--branch <name>`
   - `--files <paths>`
2. If `--pr` is provided:
   - Run `gh pr view <NUMBER> --json baseRefName,headRefName,title,body`
   - Run `git diff origin/<baseRefName>...HEAD` (or fetch the target PR ref)
3. If no target specified:
   - Inspect the active branch and check for an open PR via `gh pr view`
   - Otherwise compare against the tracking upstream branch or common merge-base
4. Build the diff profile:
   - List of changed files and extensions
   - High-risk surfaces (auth, API, crypto, migrations, core logic, external input)
   - Presence of test files
   - Approximate diff size
   - Inline for small diffs; for large ones (>~400 lines or >~15 files), dispatch
     `explorer` (background) to produce the profile
5. Apply the gating rules in `references/agent-routing.md`:
   - Default lanes: `arbiter`, `hunter`, `proctor`
   - Add `paladin` if security-sensitive surfaces changed
   - Add `oracle` for architecture-critical or perf-critical changes
   - Add `designer` (read-only prompt) for UI-only diffs
   - Tier 3 lanes only if the user explicitly opted in
6. If a routed agent is unavailable, note the lane for degraded inline review
   (see `references/agent-routing.md` §5).

## Phase 2: Parallel Lane Dispatch
1. Ensure `.multi-reviews/` exists (`mkdir -p .multi-reviews`).
2. Dispatch each selected lane in parallel using the `subagent` tool with
   `background: true`, one call per agent, e.g. `subagent(agent: "paladin",
   background: true, prompt: ...)`.
3. Build each prompt from the lane contract in `references/agent-routing.md` §4:
   diff + base ref, scope limits, read-only constraint, JSON output contract.
4. Record each lane's task/session identifier for tracking.
5. Collect results as completion notifications arrive; write raw output to
   `.multi-reviews/raw-<agent>.md` (or `.json`).
6. Do not poll; continue with any non-overlapping work while lanes run.

## Phase 3: Validation Pass
1. Filter candidate findings with severity CRITICAL or IMPORTANT.
2. Batch related candidates and dispatch parallel `explorer` validators
   (background), one per batch, instructing each to verify against current file
   contents:
   - Is the finding accurate against the actual code?
   - Is it already handled elsewhere?
   - Does it warrant the assigned severity?
3. Validators return per-finding verdicts: CONFIRMED, DOWNGRADED, FALSE_POSITIVE.
4. If a CRITICAL is contested (validators disagree or confidence is low), offer
   the user a `council` consensus pass — never dispatch it without explicit opt-in.
5. Discard FALSE_POSITIVE findings; apply DOWNGRADED severities.

## Phase 4: Aggregated Summary
1. Deduplicate matching findings across agents (same file + line + issue).
2. Order findings: CRITICAL, then IMPORTANT, then SUGGESTION.
3. Write the final report to `.multi-reviews/review-summary.md` using
   `references/summary-template.md`, including per-lane agent attribution and
   validation verdicts.
4. Output a concise summary in chat: findings counts, top issues, any degraded
   lanes, and the validation stats.
5. Offer `fixer`-driven remediation as an explicit follow-up — only on user
   request, never as part of the review.
