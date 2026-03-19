# Phase Templates

## Phase 1: Confirmation Flow

If `--no-input` is set, skip — proceed directly to Phase 2 with auto-selected agents.

Otherwise, use a two-step confirmation:

**Step 1: Accept or customize** — `AskUserQuestion` with `multiSelect: false`:
- "Accept recommended" → proceed to Phase 2 with `[selected]` agents
- "Customize selection" → continue to Step 2

**Step 2: Agent selection (only if "Customize")** — `AskUserQuestion` with `multiSelect: true`:
- List ALL discovered agents (all unchecked by default)
- Append "(Recommended)" to the label of agents marked `[selected]`
- Set `max-reviewers` to number of agents user selected
- Reprint the discovery report with updated selection, then proceed to Phase 2

## Phase 2: Review Agent Prompt

### Pre-launch checklist

Before launching any agents, verify ALL of the following:

- [ ] `ToolSearch` with `select:Task,TaskOutput` was called (Rule 1) — if not, Rule 1 was skipped in error; recover by calling it now before proceeding
- [ ] User has confirmed the Phase 1 agent selection (or `--no-input` is set)
- [ ] You are using ONLY the confirmed/auto-selected agent types from Phase 1
- [ ] `.multi-reviews/` directory exists (create with `mkdir -p .multi-reviews` if not)

### Agent prompt

For each agent, use this prompt (substitute `[AGENT_TYPE]`, `[TARGET]`, `[SHORT_NAME]`, `[SCOPE]`, `[FILE_LIST]`):

```jsonc
{
  "subagent_type": "[AGENT_TYPE]",
  "description": "[AGENT_TYPE] review",
  "prompt": "<full prompt below>",
  "run_in_background": true  // MUST be boolean true (not string "true")
}
```

Full prompt per agent:

```
Review [TARGET].

OUTPUT REQUIREMENT (most important): Write your complete findings to
.multi-reviews/review-[SHORT_NAME].md using the Write tool. Do NOT return findings
as text output — the file is how the orchestrator collects your results.

CRITICAL INSTRUCTIONS:
1. Write findings to .multi-reviews/review-[SHORT_NAME].md (see above)
2. Do NOT post any comments to the PR
3. Do NOT use `gh pr comment` or any GitHub posting commands
4. Capture ALL review output including issues, severity levels, and locations
5. Format output as structured markdown

The output file must begin with this exact header:

# Code Review Results

**Source:** [AGENT_TYPE]
**Target:** [TARGET]
**Date:** [YYYY-MM-DD HH:mm:ss]
**Scope:** [SCOPE]
**Files reviewed:** [N]

---

Configuration:
- Review scope: [diff-only | full-context]
- Files: [FILE_LIST or "all changed files"]
```

Short name is derived from the agent type: `pr-toolkit` from `pr-review-toolkit:code-reviewer`,
`code-review` from `code-review:code-reviewer`, `superpowers` from `superpowers:code-reviewer`.

### Collecting Results

Call `TaskOutput` for every agent in parallel using the exact `id` returned by their `Task` call:

```jsonc
{"task_id": "<exact UUID from Task response>", "block": true, "timeout": 300000}
// block MUST be boolean true (not string "true"), timeout MUST be number (not string "300000")
// If TaskOutput returns "No task output available", Rule 1 (ToolSearch pre-load) was skipped — stop and fix that first
```

After all `TaskOutput` calls return, for each agent use this fallback chain to get findings:

1. **File written** — read `.multi-reviews/review-<short-name>.md`. If it exists and is non-empty, use it. Apply the Normalization Pass and write it back.
2. **File missing or empty** — the agent returned its findings as text output instead of writing a file. Check the `TaskOutput` content: if it is non-empty and does not match a known failure string (`"No task output available"`, `"No task found with ID"`), use it as the findings. Write it to `.multi-reviews/review-<short-name>.md` (with the standard header prepended), then apply the Normalization Pass. If the content matches a failure string, fall through to step 3.
3. **Both empty or failed** — warn the user and skip this agent in subsequent phases.

Then print all per-agent summaries before starting Phase 3.

### Per-Agent Summary Format

Print one of these blocks per agent after all agents have completed:

```text
[✓] Phase 2: Reviews complete (<TOTAL> agents)

    ┌── <short-name> ──────────────────────────
    │ <severity counts>
    │ • <finding summary> (<file>:<line>)
    └────────────────────────────────────────

    ┌── <short-name> ──────────────────────────
    │ ...
    └────────────────────────────────────────
```

Print the `[✓] Phase 2` header once, then one box per agent.

**Severity counts line:** List non-zero severity categories separated by ` · `. Example: `2 critical · 3 important · 1 minor`

**Finding preview lines:** One line per critical or important finding, formatted as:
`• <1-line description> (<file-path>:<line-number>)`

Show at most 5 preview lines. If more than 5 critical/important findings exist, show the top 5 by severity (critical first) and append: `│ ... and <N> more critical/important findings`

If no critical or important findings exist, print: `│ No critical or important issues found`

**Unparseable output:** If an agent returns results that cannot be parsed into severity/findings (e.g., unstructured text, errors), print: `│ ⚠ Could not parse findings — see .multi-reviews/review-<short-name>.md`

## Phase 3: Validator Prompt

Launch one validation agent per review output (substitute `[SHORT_NAME]` and `[CONFIDENCE_THRESHOLD]`):

```markdown
Read and evaluate the findings in .multi-reviews/review-[SHORT_NAME].md.

For each issue found:
1. Verify the issue is real (not a false positive)
2. Check if it's a pre-existing issue vs new in this PR
3. Assess severity using ONLY these labels: Critical / Important / Minor / Nitpick
4. Evaluate confidence level (0-100)
5. Check if issue is actionable

Filter criteria:
- Remove false positives
- Remove pre-existing issues not introduced by this PR
- Remove issues that linters/type checkers would catch
- Keep issues with confidence >= [CONFIDENCE_THRESHOLD]

Write your validated findings to .multi-reviews/validated-[SHORT_NAME].md — do NOT return them as text output.
```

After all validators complete, apply the Normalization Pass (see below) to each
`validated-<short-name>.md` file before proceeding to Phase 4.

## Normalization Pass

Apply this pass to each review or validated file after reading it, before writing it back.
Make only label substitutions — do not reword, reorder, or restructure any content.

**Severity label mapping** (case-insensitive match on whole-word standalone markers only):

| Matches | Canonical |
|---------|-----------|
| `CRITICAL`, `HIGH`, `BLOCKER`, `ERROR`, `🔴`, `P0`, `P1` | `Critical` |
| `IMPORTANT`, `MEDIUM`, `MAJOR`, `WARNING`, `🟡`, `P2` | `Important` |
| `MINOR`, `LOW`, `INFO`, `🟢`, `P3` | `Minor` |
| `NITPICK`, `TRIVIAL`, `STYLE`, `SUGGESTION`, `P4` | `Nitpick` |

Apply substitutions only when the label appears as a **standalone severity marker**: in table
cells, bold headings (e.g. `**High**`), or as a prefix label (e.g. `**Severity:** High`).
Do NOT substitute occurrences inside running prose where the word is used descriptively
(e.g. "this is a high priority area" should not be changed).

## Phase 4: Aggregation Rules

### Deduplication

Issues are duplicates if ANY match:

| Criteria                       | Threshold            |
| ------------------------------ | -------------------- |
| Same file + line range         | Within 5 lines       |
| Issue description similarity   | >80% semantic match  |
| Same code snippet referenced   | Exact match          |

When duplicates found:
- Keep the instance with highest confidence score
- Mark source as "multiple" in Source column
- Combine unique details from all descriptions

### Aggregation Steps

1. **Deduplicate** - Identify issues found by multiple reviews
2. **Categorize** - Group by severity (Critical > Important > Minor > Nitpick)
3. **Prioritize** - Security issues first, then by confidence score
4. **Cross-reference** - Note which review(s) found each issue
5. **Synthesize** - Create actionable summary

Report sections: Executive Summary, Security Issues, Critical Issues,
Important Issues, Minor Issues, Nitpicks, Positive Observations, Review Agreement
Analysis, Recommended Actions.

Output file: `.multi-reviews/review-summary.md`
