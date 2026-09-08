---
name: multi-review
description: Use when reviewing a PR, branch diff, or set of changed files with multiple parallel specialist perspectives (correctness, security, test coverage, and performance).
---

# OpenCode Multi-Review

Run multi-perspective code reviews using parallel OpenCode subagents, independent validation passes, and aggregated summary reports.

## Core Rules

1. Scope: code review only. Never modify source files or apply automated fixes during review.
2. Never assume main is the base branch. Resolve base branch from PR metadata or git tracking.
3. Use background tasks for parallel review execution.
4. Normalize and validate findings before reporting.
5. Store artifacts in `.multi-reviews/`.

## Execution Lifecycle

### Phase 1: Target Resolution
- Determine target: PR number, branch, or file list.
- If target is a PR, fetch metadata using `gh pr view <number> --json baseRefName,title,body`.
- Determine diff using verified base reference: `git diff origin/<baseRef>...HEAD`.
- Triage changed files to identify applicable reviewer roles.

### Phase 2: Parallel Specialist Reviews
- Select 2 to 3 relevant specialist roles from `references/reviewer-roles.md`.
- Spawn each reviewer subagent in parallel via `task(..., run_in_background: true)`.
- Use the contract from `references/reviewer-roles.md` to request structured output.
- Wait for system notifications and collect results with `background_output`.

### Phase 3: Finding Validation
- For any findings marked CRITICAL or IMPORTANT, spawn validation subagents in parallel to check for false positives against current file contents.
- Downgrade or discard invalid findings based on validation results.

### Phase 4: Aggregation and Reporting
- Deduplicate findings identified by multiple reviewers.
- Generate `.multi-reviews/review-summary.md`.
- Present a concise report table in the session, listing file, line, severity, and description.

## References

- `references/reviewer-roles.md`: Specialist catalog and output JSON contract.
- `references/workflow-steps.md`: Step-by-step dispatch and aggregation procedures.
- `references/summary-template.md`: Report template for the final summary output.
