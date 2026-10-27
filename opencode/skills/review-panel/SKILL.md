---
name: review-panel
description: Use when reviewing a PR, branch diff, or set of changed files with multiple parallel specialist perspectives — routes review lanes to oh-my-opencode-slim agents (correctness, error paths, test sufficiency, security, architecture) with cost-tiered gating, independent validation, and an aggregated report. Requires the oh-my-opencode-slim agent roster (or equivalently-named agents).
---

# Review Panel

Run multi-perspective code reviews by routing review lanes to named
oh-my-opencode-slim agents, dispatched in parallel as background subagents,
with an independent validation pass and an aggregated summary report.

See `DESIGN.md` for the rationale and the role→agent migration map.

## Prerequisites

Requires these agents in the OpenCode registry — provided by
[oh-my-opencode-slim](https://github.com/alvinunreal/oh-my-opencode-slim)
(built-ins: `explorer`, `oracle`, `designer`, `council`, `fixer`; marketplace:
`arbiter`, `paladin`, `hunter`, `proctor`, `janitor`) — or equivalently-named
agents defined in your own config. A missing agent degrades its lane to inline
review by the main session with a warning (see `references/agent-routing.md` §5).

## Core Rules

1. Scope: code review only. No lane modifies source files or applies automated fixes during review.
2. Never assume `main` is the base branch. Resolve the base from PR metadata or git tracking.
3. Route to named oh-my-opencode-slim agents per `references/agent-routing.md` — do not spawn anonymous reviewer roles.
4. Lean defaults with gating: start from `arbiter` + `hunter` + `proctor`; add premium lanes (`paladin`, `oracle`) only when the diff profile triggers them (see `references/agent-routing.md`).
5. Validate findings before reporting: CRITICAL/IMPORTANT findings are re-checked by cheap validator lanes.
6. Normalize, deduplicate, and validate findings before reporting.
7. Store artifacts in `.multi-reviews/`.
8. Optional lanes (`council`, `janitor`, `observer`) require explicit user opt-in. Post-review remediation via `fixer` happens only after the report, on explicit request.

## Execution Lifecycle

### Phase 1: Target Resolution and Diff Triage
- Determine target: PR number, branch, or file list.
- If target is a PR, fetch metadata with `gh pr view <number> --json baseRefName,headRefName,title,body`.
- Determine diff using the verified base reference: `git diff origin/<baseRef>...HEAD`.
- Build the diff profile inline for small diffs; delegate to `explorer` for large ones (>~400 lines or >~15 files).
- Apply gating rules from `references/agent-routing.md` to select the lane set.

### Phase 2: Parallel Specialist Reviews
- Dispatch each selected agent lane in parallel via the `subagent` tool with `background: true` (e.g. `agent: "paladin"`).
- Use the per-agent prompt contract from `references/agent-routing.md` (scope, read-only constraint, JSON output).
- Collect results on completion notifications; write raw output to `.multi-reviews/raw-<agent>.md`.

### Phase 3: Finding Validation
- Spawn parallel `explorer` validators (cheap tier) to re-check every CRITICAL/IMPORTANT finding against current file contents.
- Apply verdicts: CONFIRMED, DOWNGRADED, or FALSE_POSITIVE.
- Contested CRITICAL findings may go to `council` only with explicit user opt-in.

### Phase 4: Aggregation and Reporting
- Deduplicate findings reported by multiple agents.
- Generate `.multi-reviews/review-summary.md` using `references/summary-template.md` (includes per-lane agent attribution and validation verdicts).
- Present a concise report table in the session: file, line, severity, agent, description.
- Offer `fixer`-driven remediation as a follow-up step, only on explicit user request.

## References

- `references/agent-routing.md`: Agent routing table, tier/gating rules, and per-agent prompt contract.
- `references/workflow-steps.md`: Step-by-step dispatch, validation, and aggregation procedures.
- `references/summary-template.md`: Report template for the final summary output.
- `DESIGN.md`: Redesign rationale and v1 migration map.
