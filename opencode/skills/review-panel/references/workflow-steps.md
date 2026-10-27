# Review Panel Workflow Steps

## Phase 1: Target Resolution and Diff Triage
1. Parse flags or user input:
   - `--pr <number>`
   - `--branch <name>`
   - `--files <paths>`
2. If `--pr` is provided:
   - Run `gh pr view <NUMBER> --json baseRefName,headRefName,title,body`
   - If that fails or the PR is not found, surface the error in-chat and stop
     (or fall back to the no-target resolution below with the user's
     confirmation)
   - Run `git diff origin/<baseRefName>...HEAD` (or fetch the target PR ref);
     if `origin/<baseRefName>` is missing locally, run
     `git fetch origin <baseRefName>` before diffing
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
5. If the resolved diff is empty, report "no changes to review" in-chat and skip
   Phases 2–4 — never dispatch lanes against an empty diff.
6. Apply the gating rules in `references/agent-routing.md`:
   - Default lanes: `arbiter`, `hunter`, `proctor`
   - Add `paladin` if security-sensitive surfaces changed
   - Add `oracle` for architecture-critical or perf-critical changes
   - Add `designer` (read-only prompt) for UI-only diffs
   - Tier 3 lanes only if the user explicitly opted in
7. If a routed agent is unavailable, note the lane for degraded inline review
   (see `references/agent-routing.md` §5).

## Phase 2: Parallel Lane Dispatch
1. Ensure `.review-panel/` exists (`mkdir -p .review-panel`).
2. Dispatch each selected lane in parallel using the `subagent` tool with
   `background: true`, one call per agent, e.g. `subagent(agent: "paladin",
   background: true, prompt: ...)`.
3. Build each prompt from the lane contract in `references/agent-routing.md` §4:
   diff + base ref, scope limits, read-only constraint, JSON output contract.
4. Record each lane's task/session identifier for tracking.
5. Collect results as completion notifications arrive; write raw output to
   `.review-panel/raw-<agent>.md` (or `.json`).
6. On a lane failure — dispatch error, an error result instead of findings, or a
   lane that never completes — treat the lane as degraded per
   `references/agent-routing.md` §5 (inline review or explicit decline), record
   the failure reason in the summary's "Degraded lanes" field, and state the
   failure in-chat.
7. If a lane's output does not parse as the JSON contract, do not discard it
   silently: mark the lane as output-unparseable in the report, attempt
   best-effort structured extraction from the raw text, and cite the raw file
   path (see `references/agent-routing.md` §4).
8. Do not poll; continue with any non-overlapping work while lanes run.
9. Before aggregation, verify every dispatched lane has a collected result or a
   recorded degradation/output-unparseable marker — a stuck lane with neither is
   resolved (inline review or explicit decline) so it cannot be silently dropped.

## Phase 3: Validation Pass
1. Filter candidate findings with severity CRITICAL or IMPORTANT. Findings from
   output-unparseable lanes are limited to what best-effort extraction produced
   and cite the raw output file path.
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
3. Write the final report to `.review-panel/review-summary.md` using
   `references/summary-template.md`, including per-lane agent attribution and
   validation verdicts.
4. Output a concise summary in chat: findings counts, top issues, any degraded
   lanes, and the validation stats.
5. Offer `fixer`-driven remediation as an explicit follow-up — only on user
   request, never as part of the review.
