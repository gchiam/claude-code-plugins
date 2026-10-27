# multi-review-opencode v2 — Redesign Proposal

Status: proposed (awaiting approval). Target: rewrite of `SKILL.md` and `references/` in this directory.

## 1. Summary

Rework the skill from anonymous "reviewer role" subagents to native routing over the
[oh-my-opencode-slim](https://github.com/alvinunreal/oh-my-opencode-slim) agent suite, with cost
tiering and lane gating taken from the oh-my-opencode-slim model-selection config.

## 2. Problem with the current design

- **Wrong mechanics.** Reviewers are spawned via Claude-Code-style
  `task(category=..., run_in_background=true)` + `background_output` and collected on
  `<system-reminder>` notices. OpenCode dispatches subagents with the `subagent` tool
  (`agent`, `background: true`) and completion notifications — the skill's instructions
  don't match the runtime it runs in.
- **Ignores the available specialists.** oh-my-opencode-slim already ships review-purpose
  agents, and the model-selection config enables them: `paladin`, `arbiter`, `hunter`, `proctor`,
  `janitor`, `documenter`, `chronicler`. v1 reinvents overlapping anonymous roles instead
  of routing to them.
- **No cost tiering.** Every lane implicitly assumes a "deep" model. A deliberate config
  pins premium Claude Opus 5.5 only on `paladin`/`arbiter`/`oracle`, runs
  `hunter`/`proctor`/`janitor` on the session model (GLM 5.3), and `explorer` on
  GLM 5p3 Flash ($0.15/$0.50 per 1M tokens). A review skill should exploit that spread.
- **Charter mismatches.** v1's "correctness" role duplicates `arbiter`'s
  correctness/contracts/merge-readiness charter; nothing in v1 covers `hunter`'s
  swallowed-failures / error-path charter, which is a distinct and valuable review lens.

## 3. Agent routing table

Replaces the role catalog in `references/reviewer-roles.md` (file becomes
`references/agent-routing.md`).

| Review concern | Agent | Model (example) | Tier |
|---|---|---|---|
| Diff triage / profiling (large diffs) | `explorer` | `zai.glm-5p3-flash` low | 0 |
| Correctness, contracts, architecture, merge readiness | `arbiter` | `anthropic.claude-opus-5-5` high | 1 (default) |
| Error paths, swallowed failures, misleading fallbacks, retry exhaustion | `hunter` | session model (GLM 5.3) | 1 (default) |
| Test sufficiency, behavioral coverage, regression risk | `proctor` | session model (GLM 5.3) | 1 (default) |
| Security (authn/authz, secrets, injection, SSRF, unsafe deserialization) | `paladin` | `anthropic.claude-opus-5-5` high | 2 (gated) |
| Architecture-critical / performance review | `oracle` | `anthropic.claude-opus-5-5` high | 2 (gated) |
| Maintainability sweep | `janitor` | session model | 3 (opt-in) |
| UI / visual diffs (read-only instructions) | `designer` | `github-copilot/gpt-6.1-sol` medium | 2 (gated: UI-only diffs) |
| Image / screenshot evidence in the diff | `observer` | `github-copilot/gpt-6.1-sol` low | 3 (opt-in; disabled by default — see §8) |
| Validation of CRITICAL/IMPORTANT findings | `explorer` validators | `zai.glm-5p3-flash` low | per-phase |
| Consensus on contested CRITICAL findings | `council` | config-driven councillors | 3 (explicit user opt-in) |
| Post-review remediation | `fixer` | `zai.glm-5p3-flash` high | Out of review scope — §7 |

## 4. Lane selection (lean + gating)

- **Tier 0 — always:** target resolution + diff profile. Inline for small diffs; delegate
  to `explorer` when the diff is large (>~400 lines or >~15 files).
- **Tier 1 — default lanes (3, one premium):** `arbiter` + `hunter` + `proctor`.
- **Tier 2 — auto-added when the diff profile triggers:**
  - `paladin`: auth, API boundaries, crypto, migrations, external input, secrets touched.
  - `oracle`: architectural or core-logic changes, cross-system contracts, perf-critical paths.
  - `designer`: UI-only diffs, with explicit read-only instructions (designer normally
    implements; the prompt must forbid edits).
- **Tier 3 — opt-in only (user asks or explicitly confirms):** `council` on contested
  CRITICALs, `janitor` maintainability sweep, `observer` for image evidence.
- Cap concurrent review lanes at 3–4; premium (Opus) lanes at 2 per run.

## 5. Lifecycle (unchanged shape, new mechanics)

1. **Target resolution** — PR number / branch / file list; `gh pr view <n> --json
   baseRefName,headRefName,title,body`; diff via `git diff origin/<base>...HEAD`; never
   assume `main`. Build the diff profile (files, surfaces, tests present) — inline or
   `explorer`. Apply gating rules → lane set.
2. **Parallel specialist reviews** — dispatch each lane with the `subagent` tool,
   `background: true`, using the per-agent prompt contract; collect on completion
   notifications; write raw output to `.multi-reviews/raw-<agent>.md`.
3. **Finding validation** — spawn parallel `explorer` validators (cheap Flash tier) to
   re-check every CRITICAL/IMPORTANT finding against current file contents; verdicts
   CONFIRMED / DOWNGRADED / FALSE_POSITIVE. Contested CRITICALs may go to `council`
   only with explicit user opt-in.
4. **Aggregation & reporting** — dedupe across agents, order by severity, write
   `.multi-reviews/review-summary.md` (per-lane agent/model attribution, validation
   verdicts), present a concise table in chat.

## 6. Output contract

Keep v1's JSON findings schema, add an `agent` field and a validation verdict applied in
phase 3:

```json
{
  "file": "path/to/file.ext",
  "line": 123,
  "severity": "CRITICAL | IMPORTANT | SUGGESTION",
  "confidence": 0-100,
  "title": "Short title",
  "description": "Clear explanation of the issue",
  "evidence": "Code quote or trace explaining why this is an issue",
  "suggested_fix": "Concrete guidance or snippet",
  "agent": "arbiter"
}
```

Every lane prompt carries: the resolved diff (or instructions to reproduce it), the
agent's scope limits, the read-only constraint, and this output contract.

## 7. Boundaries

- **Review is read-only.** No lane modifies source files or applies fixes (kept from v1).
- **`fixer` is out of scope.** After the report is delivered, the skill may *offer*
  fixer-driven remediation, but only on explicit user request, as a separate step.
- **`council` is opt-in.** Highest-cost path; never auto-dispatched.
- **`observer` gap.** Disabled by the plugin default (`disabled_agents: ['observer']`).
  The skill documents it as an opt-in lane requiring `"disabled_agents": []` plus a
  vision-capable model; it never assumes observer availability.

## 8. Caveats & runtime notes

- Model assignments above are an example preset snapshot (2026-10-27); the
  skill text references agents, not model IDs, so it stays valid when the config changes.
- One config rationale notes CLI `opencode run` sessions without `--agent` are rejected
  by the plugin's permission bridge while marketplace agents are enabled; run reviews
  from interactive sessions or with an explicit agent.
- Marketplace agents must be installed/enabled (`paladin`, `arbiter`, `hunter`,
  `proctor`, `janitor`) or the routing table degrades — the skill falls back to inline
  review by the main session with a warning.

## 9. File changes

| File | Change |
|---|---|
| `SKILL.md` | Rewrite: core rules, routing summary, 4-phase lifecycle, references list |
| `references/agent-routing.md` | New: routing table, tier/gating rules, per-agent prompt contract |
| `references/reviewer-roles.md` | Delete (superseded by agent-routing.md) |
| `references/workflow-steps.md` | Rewrite: OpenCode dispatch mechanics, gating, validation, aggregation |
| `references/summary-template.md` | Extend: agent/model attribution, validation verdict column, council section, remediation offer |

## 10. Migration from v1

Role → agent mapping for anyone comparing old reports: `correctness` → `arbiter` (+ error
paths → `hunter`), `security` → `paladin`, `test-coverage` → `proctor`,
`architecture-perf` → `oracle` (gated) / `janitor` (maintainability, opt-in). Artifacts
stay in `.multi-reviews/`; old reports remain readable.
