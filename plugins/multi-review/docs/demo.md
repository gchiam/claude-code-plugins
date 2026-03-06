# Multi-Review Plugin — Demo Walkthrough

This document walks through a real review session using the multi-review plugin on a production PR. It shows how multiple specialized AI reviewers work in parallel, cross-validate each other's findings, and produce a single aggregated summary — catching issues that no single reviewer would find alone.

## The PR Under Review

**PR #257** — Add build status flow for Dependabot PRs

- **8 new files**: 6 GitHub Actions composite actions + 1 reusable workflow + 1 job added to `ci.yml`
- **473 lines added** — all bash scripts orchestrating Dependabot PR classification, build status labeling, and failure notifications
- **Stacked PR** on top of a classification flow branch

## Running the Review

Invoke the skill with a PR number and optional context:

```
/multi-review:multi-review --pr 257 (refer to @docs/plans/2026-02-25-woodstock-3177-build-status-flow.md)
```

Referencing the plan document gives the `superpowers:code-reviewer` agent the ability to compare the implementation against the original plan spec — something only possible with multi-review's diverse reviewer approach.

## Phase 1 — Agent Discovery

The plugin automatically scans installed plugins for review-capable agents:

```
Multi Review - PR #257
════════════════════════════════════════

[✓] Phase 1: Discovered 9 review agents (max-reviewers: 3):
    ├── [selected] coderabbit:code-reviewer
    ├── [selected] feature-dev:code-reviewer
    ├── [selected] pr-review-toolkit:silent-failure-hunter
    ├── [skipped]  pr-review-toolkit:code-reviewer
    ├── [skipped]  pr-review-toolkit:comment-analyzer
    ├── [skipped]  pr-review-toolkit:pr-test-analyzer
    ├── [skipped]  pr-review-toolkit:type-design-analyzer
    ├── [skipped]  superpowers:code-reviewer
    └── [skipped]  pr-desc-review:desc-reviewer

Selection rationale:
- coderabbit:code-reviewer — broad, thorough analysis of all changes
- feature-dev:code-reviewer — security vulnerabilities and logic errors
  (critical for shell scripts in CI/CD)
- pr-review-toolkit:silent-failure-hunter — silent failures and error handling
  (especially relevant for bash + gh CLI workflows)
```

Each agent is selected based on the PR's content. Shell-heavy CI/CD code naturally pulls in the silent-failure-hunter; the security-focused feature-dev reviewer is prioritized for scripts that handle external inputs.

After review, the user customized the selection to add 2 more agents:

```
[✓] Phase 1: Discovered 9 review agents (max-reviewers: 5, customized):
    ├── [selected] coderabbit:code-reviewer
    ├── [selected] feature-dev:code-reviewer
    ├── [selected] pr-review-toolkit:silent-failure-hunter
    ├── [selected] superpowers:code-reviewer          ← added
    ├── [selected] pr-desc-review:desc-reviewer       ← added
    ...
```

## Phase 2 — Parallel Review Execution

All 5 agents launch simultaneously and review the PR diff independently:

```
Phase 2: Launching 5 review agents in parallel.

[running] coderabbit:code-reviewer
[running] feature-dev:code-reviewer
[running] pr-review-toolkit:silent-failure-hunter
[running] superpowers:code-reviewer
[running] pr-desc-review:desc-reviewer
```

Each agent writes a standalone review file (`review-<name>.md`) with its findings. Here's what each reviewer found:

### What Each Reviewer Brought to the Table

| Reviewer | Focus | Unique Contribution |
|----------|-------|---------------------|
| **coderabbit** | Broad code quality | Found the `ensure-label` only-one-state bug, missing `timeout-minutes`, and job actor gate inefficiency |
| **feature-dev** | Security + logic errors | Identified the `<<EOF` vs `<<'EOF'` heredoc inconsistency as a security concern (shell expansion of CODEOWNERS-sourced input) |
| **silent-failure-hunter** | Error handling gaps | Found 6 silent failure patterns: bare `gh pr comment`, bare `--add-label`, `2>/dev/null` suppressing errors, soft-failure `::warning::` exits |
| **superpowers** | Plan vs implementation | Confirmed all 8 tasks implemented; flagged `should-skip` vs `skip` output key mismatch; identified beneficial deviations from plan |
| **pr-desc-review** | Description accuracy | Caught 6 factual inaccuracies in the PR description: wrong label names, wrong action count, wrong job dependency |

### Key Convergences and Disputes

**Two reviewers independently found the same critical bug:**

Both `coderabbit` (95% confidence) and `feature-dev` (98% confidence) flagged `inputs.build-passed == false` as dead code — GitHub Actions coerces boolean workflow inputs to strings at the `workflow_call` boundary, so `"false" == false` never matches.

However, `superpowers` **disputed** this (85% confidence), arguing that `type: boolean` inputs retain their boolean type in `if:` expression contexts.

This disagreement is itself valuable — it tells the author: *test this specific behavior before merge*.

**One reviewer's "critical" finding was debunked by another:**

`superpowers` flagged `.outputs.skip` vs `.outputs.should-skip` as a critical mismatch between the plan and the code. During validation, the validator actually read the `check-skip-label` action on the base branch and confirmed the action outputs `skip` — the plan document was stale, not the code.

## Phase 3 — Parallel Validation

Each review file is validated by a dedicated validator agent that checks whether findings are accurate:

```
Phase 3: Parallel Validation

[running] validate coderabbit review
[running] validate feature-dev review
[running] validate silent-failure review
[running] validate superpowers review
[running] validate pr-desc review
```

Each validator produces a `validated-<name>.md` file with verdicts:

| Verdict | Meaning |
|---------|---------|
| **KEEP** | Finding is accurate and actionable |
| **KEEP (disputed)** | Accurate but contested by another reviewer |
| **FILTERED** | Below confidence threshold after deeper analysis |
| **REMOVED** | False positive — evidence shows the code is correct |

Here are the actual validation results from each reviewer:

### validated-coderabbit.md

| # | Finding | Severity | Confidence | Verdict |
|---|---------|----------|------------|---------|
| 1 | `inputs.build-passed == false` always false — notify step dead code | Critical | 95 | KEEP (disputed) |
| 2 | Plan doc stale `should-skip` key reference | Nitpick | 90 | KEEP (doc only) |
| 3 | 60s timeout undocumented | Minor | 70 | KEEP |
| 4 | Silent fail-open on `gh` error in idempotency checks | Minor | 75 | KEEP |
| 5 | `builds-failed` label may not exist on first failure run | Important | 85 | KEEP |
| 6 | `actions/checkout@v6` vs `zendesk/checkout@v6` | Minor | 80 | KEEP |
| 7 | Job runs for all actors (no outer gate in ci.yml) | — | — | **REMOVED** — intentional design |
| 8 | No `timeout-minutes` on job | — | — | **REMOVED** — generic hygiene |

Two false positives removed. Finding 7 was intentional design; finding 8 was generic hygiene not specific to this PR.

### validated-feature-dev.md

| # | Finding | Severity | Confidence | Verdict |
|---|---------|----------|------------|---------|
| 1 | `inputs.build-passed == false` always false — notify step dead code | Critical | 98 | KEEP (disputed) |
| 2 | `actions/checkout@v6` vs `zendesk/checkout@v6` | Important | 72 | KEEP |
| 3 | Default 60s poll timeout too short | Nitpick | 55 | **FILTERED** — below confidence threshold |
| 4 | Unquoted `<<EOF` heredoc in notify-build-failure | Minor | 78 | KEEP |

One finding filtered: the 60s timeout concern dropped to 55% confidence since the timeout path is graceful and non-fatal.

### validated-silent-failure.md

| # | Finding | Severity | Confidence | Verdict |
|---|---------|----------|------------|---------|
| 1 | `2>/dev/null` + pipe swallows `gh` failure in idempotency check (notify-build-failure) | Critical | 97 | KEEP |
| 2 | Same pattern in notify-classification-timeout | Critical | 97 | KEEP |
| 3 | Bare `gh pr comment` — step fails but log has no diagnostic message | High | 88 | KEEP |
| 4 | `::warning::` + exit 0 on comment failure — PR left unmanaged silently | High | 92 | KEEP |
| 5 | Bare `--add-label` calls — no stderr capture | High | 90 | KEEP |
| 6 | `TEAM` not validated before use in comment body | — | — | **REMOVED** — `get-codeowners-team` already exits 1 on empty team |
| 7 | Timeout warning omits last-seen labels | Minor | 83 | KEEP |
| 8 | Verify step `== 'failure'` vs `!= 'success'` (misses skipped/cancelled) | Minor | 75 | KEEP |

One false positive removed: the `TEAM` validation concern was debunked because the upstream action already guards against empty output.

Note on issues 1 & 2: The superpowers validator pointed out that both the pipeline and variable-capture patterns behave identically when `gh` fails. These were downgraded from Critical to Important in the aggregated report — the real issue is undocumented fail-open behavior, not a pattern regression.

### validated-superpowers.md

| # | Finding | Severity | Confidence | Verdict |
|---|---------|----------|------------|---------|
| 1 | `check-skip-label` output key mismatch (plan says `should-skip`, code uses `skip`) | — | — | **REMOVED** — action on base branch outputs `skip`; code is correct, plan is stale |
| 2 | Idempotency check pipeline vs variable-capture regression | — | — | **REMOVED** — both patterns behave identically on `gh` failure |
| 3 | `inputs.build-passed == false` comparison | Suggestion | 85 | DISPUTED — superpowers says `== false` is correct for `type: boolean` input |

Two false positives removed. The "critical" output key mismatch — the most alarming finding from this reviewer — was completely debunked by reading the actual action on the base branch.

Beneficial deviations confirmed (no action needed):
- `fail-on-timeout` input in `wait-for-classification` — correctly prevents workflow failure
- Improved `remove_opposite_label()` error handling — better than plan spec
- `PR_NUMBER` regex validation across all actions — beneficial addition

### validated-pr-desc.md

All 6 discrepancies confirmed with 100% confidence. No false positives.

| # | Finding | Severity | Confidence | Verdict |
|---|---------|----------|------------|---------|
| 1 | Description says "5 composite actions" but 6 exist | Minor | 100 | KEEP |
| 2 | `check-dependabot-author` falsely described as having skip-label check | Minor | 100 | KEEP |
| 3 | Wrong label names: `dep-type:*` vs actual `dependency-*` | Important | 100 | KEEP |
| 4 | Wrong label names: `build:pending/pass/fail` vs actual `builds-passing`/`builds-failed` | Important | 100 | KEEP |
| 5 | `notify-classification-timeout` falsely described as assigning CODEOWNERS team | Minor | 100 | KEEP |
| 6 | Job described as running "after the build job" but depends on `test` | Minor | 100 | KEEP |

### Validation Summary

| Reviewer | Raw Findings | Kept | Removed | Filtered | Disputed |
|----------|:------------:|:----:|:-------:|:--------:|:--------:|
| coderabbit | 8 | 6 | 2 | 0 | 1 |
| feature-dev | 4 | 3 | 0 | 1 | 1 |
| silent-failure-hunter | 8 | 7 | 1 | 0 | 0 |
| superpowers | 3 | 0 | 2 | 0 | 1 |
| pr-desc-review | 6 | 6 | 0 | 0 | 0 |
| **Total** | **29** | **22** | **5** | **1** | **—** |

6 findings removed or filtered across 5 reviewers — a **21% false positive rate** caught before reaching the final summary.

## Phase 4 — Aggregated Summary

The final `review-summary.md` deduplicates, cross-references, and prioritizes all validated findings:

### Issue Breakdown

| Severity | Count | Examples |
|----------|-------|---------|
| Critical (Disputed) | 1 | `inputs.build-passed == false` — notify step may be dead code |
| Important | 6 | Silent `gh pr comment` failures, bare `--add-label`, missing `ensure-label`, wrong checkout action |
| Minor | 3 | Timeout warning omits labels, verify step `== 'failure'` vs `!= 'success'`, unquoted heredoc |
| PR Description | 6 | Wrong label names, wrong action count, wrong job dependency |

### Cross-Reviewer Agreement Matrix

The summary includes an agreement matrix showing which reviewers found each issue:

```
| Issue                          | coderabbit | feature-dev | silent-failure | superpowers | pr-desc |
|--------------------------------|:----------:|:-----------:|:--------------:|:-----------:|:-------:|
| inputs.build-passed == false   |     ✓      |      ✓      |       —        |  ✗ (disputes) |    —    |
| Idempotency fail-open          |     ✓      |      —      |       ✓        |  ✗ (disputes) |    —    |
| notify-timeout soft-failure    |     —      |      —      |       ✓        |      —      |    —    |
| ensure-label both states       |     ✓      |      —      |       —        |      —      |    —    |
| actions/checkout@v6            |     ✓      |      ✓      |       —        |      —      |    —    |
```

Issues found by multiple reviewers carry higher confidence. Issues found by only one specialist (like silent-failure-hunter's error handling findings) still surface because that reviewer's lens is uniquely suited to catch them.

### Prioritized Action List

The summary concludes with a priority-ordered action list:

1. **Verify C1** — trigger a failing Dependabot CI run, confirm `notify-build-failure` fires
2. **Fix I1** — `notify-classification-timeout` must treat `gh pr comment` failure as hard error
3. **Fix I3** — add stderr capture to `--add-label` calls
4. **Fix I4** — call both `ensure-label` steps unconditionally
5. **Fix I5** — confirm or change `actions/checkout@v6` to `zendesk/checkout@v6`
6. **Update PR description** — fix all 6 inaccuracies before merge

## Results at a Glance

| Metric | Value |
|--------|-------|
| **Reviewers** | 5 agents in parallel |
| **Wall time** | ~14 minutes |
| **Files produced** | 5 raw reviews + 5 validated + 1 summary |
| **Raw findings** | 29 across all reviewers |
| **After validation** | 22 kept, 5 removed, 1 filtered (21% false positive rate) |
| **Final summary** | 1 critical (disputed), 6 important, 3 minor, 6 description |
| **Cross-reviewer disputes** | 2 (both escalated with "test before merge" recommendation) |

## Why Multi-Review?

### 1. Specialized Lenses Catch Different Classes of Bugs

A single general-purpose reviewer found 8 issues. The silent-failure-hunter found 8 different issues focused on error handling. The PR description reviewer found 6 inaccuracies. Together: 16 unique, validated findings from perspectives that don't overlap.

### 2. Cross-Validation Filters False Positives

29 raw findings went in; 6 came out as false positives or below-threshold noise. The `should-skip` vs `skip` finding looked critical — a key output name mismatch across 5 workflow steps. Validation confirmed it was a stale plan doc, not a code bug. The `TEAM` validation concern was debunked because the upstream action already guards against empty output. Without validation, these would have sent the author on a wild goose chase.

### 3. Reviewer Disagreements Are Signal, Not Noise

Two reviewers (95-98% confidence) said `inputs.build-passed == false` is broken. One reviewer (85% confidence) said it's correct. The aggregated summary presented this as a *disputed critical* with a concrete test plan: "trigger a failing run and observe." The disagreement itself tells the author exactly what to verify.

### 4. Consistent Output Format

Every review produces a standardized markdown file. The aggregated summary uses consistent severity tiers (Critical / Important / Minor), confidence scores, and file references. This makes the output scannable and actionable — no hunting through comment threads.

### 5. No Noise on the PR

All output stays local as markdown files. The author decides what to act on, what to post, and what to dismiss. No auto-commenting clutters the PR with low-confidence suggestions.
