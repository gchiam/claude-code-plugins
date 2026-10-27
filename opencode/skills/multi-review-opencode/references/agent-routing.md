# Agent Routing and Output Contracts

## 1. Routing Table

Route review concerns to oh-my-opencode-slim agents. Models shown are an
example preset assignment; the skill references agents only, so it stays
valid when the config changes.

| Review concern | Agent | Model (example) | Tier |
|---|---|---|---|
| Diff triage / profiling (large diffs) | `explorer` | `zai.glm-5p3-flash` low | 0 |
| Correctness, contracts, architecture, merge readiness | `arbiter` | `anthropic.claude-opus-5-5` high | 1 (default) |
| Error paths, swallowed failures, misleading fallbacks, retry exhaustion | `hunter` | session model | 1 (default) |
| Test sufficiency, behavioral coverage, regression risk | `proctor` | session model | 1 (default) |
| Security: authn/authz boundaries, secrets, injection, SSRF, unsafe deserialization | `paladin` | `anthropic.claude-opus-5-5` high | 2 (gated) |
| Architecture-critical / performance review | `oracle` | `anthropic.claude-opus-5-5` high | 2 (gated) |
| UI / visual diffs (read-only) | `designer` | `github-copilot/gpt-6.1-sol` medium | 2 (gated: UI-only diffs) |
| Maintainability sweep | `janitor` | session model | 3 (opt-in) |
| Image / screenshot evidence | `observer` | `github-copilot/gpt-6.1-sol` low | 3 (opt-in; disabled by default) |
| Validation of CRITICAL/IMPORTANT findings | `explorer` validators | `zai.glm-5p3-flash` low | per-phase |
| Consensus on contested CRITICAL findings | `council` | config-driven councillors | 3 (explicit opt-in) |
| Post-review remediation | `fixer` | `zai.glm-5p3-flash` high | Out of review scope |

## 2. Lane Selection Rules

**Tier 0 — always.** Target resolution + diff profile. Inline for small diffs;
delegate to `explorer` when the diff exceeds ~400 lines or ~15 files.

**Tier 1 — default lanes (3, one premium).** `arbiter` + `hunter` + `proctor`.
Run these on every review unless the user narrows scope.

**Tier 2 — auto-added when the diff profile triggers:**
- `paladin`: auth, API boundaries, crypto, migrations, external input, or secrets touched.
- `oracle`: architectural or core-logic changes, cross-system contracts, perf-critical paths.
- `designer`: UI-only diffs. Designer normally implements — the prompt MUST forbid edits.

**Tier 3 — opt-in only.** `council` on contested CRITICALs, `janitor`
maintainability sweep, `observer` for image evidence. Never auto-dispatch.

**Limits.** Cap concurrent review lanes at 3–4; premium (Opus) lanes at 2 per run.

## 3. Per-Agent Lane Scope

- `arbiter`: logic bugs, off-by-one, null/undefined safety, race conditions, type
  invariants, contract violations, merge readiness.
- `hunter`: swallowed failures, misleading fallbacks, weak diagnostics, hidden
  retry exhaustion, unhandled error branches.
- `proctor`: missing test cases for new paths, brittle assertions, untested error
  branches, behavioral coverage gaps, regression risk.
- `paladin`: input validation, authentication/authorization boundaries, secrets,
  injection vectors, SSRF, unsafe deserialization.
- `oracle`: modularity regressions, resource leaks, blocking operations on event
  loops, inefficient database/network calls — only for architecture-critical diffs.
- `designer`: visual/layout regressions and UI hierarchy issues in UI-only diffs;
  strictly read-only.

## 4. Lane Prompt Contract

Every dispatched lane receives a prompt containing:
1. The resolved diff (or the exact commands to reproduce it) and the base reference.
2. The agent's scope limits from section 3.
3. The read-only constraint: no file modifications, no fixes, review only.
4. The output contract below.

Each reviewer must format findings as a JSON array of items adhering to:

```json
[
  {
    "file": "path/to/file.ext",
    "line": 123,
    "severity": "CRITICAL" | "IMPORTANT" | "SUGGESTION",
    "confidence": 0-100,
    "title": "Short title",
    "description": "Clear explanation of the issue",
    "evidence": "Code quote or trace explaining why this is an issue",
    "suggested_fix": "Concrete guidance or snippet",
    "agent": "arbiter"
  }
]
```

The `agent` field must match the lane's agent name. Empty finding sets are valid —
return `[]` rather than inventing findings.

## 5. Degradation

If a routed marketplace agent is unavailable (not installed/enabled), do not
silently skip the lane: fall back to an inline review of that concern by the
main session and flag the degraded lane in the final report.
