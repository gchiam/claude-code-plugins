# Phase Templates

## Phase 1: Confirmation Flow

If `--no-input` is set, skip and proceed directly to Phase 2 with auto-selected agents.

Otherwise, use a two-step confirmation:

**Step 1: Accept or customize.** Use `AskUserQuestion` with `multiSelect: false`:
- "Accept recommended" → proceed to Phase 2 with `[selected]` agents
- "Customize selection" → continue to Step 2

**Step 2: Agent selection (only if "Customize").** Use `AskUserQuestion` with `multiSelect: true`:
- List ALL discovered agents (all unchecked by default)
- Append "(Recommended)" to the label of agents marked `[selected]`
- Set `max-reviewers` to number of agents user selected
- Reprint the discovery report with updated selection, then proceed to Phase 2

## Phase 2: Review Agent Prompt

### Pre-launch checklist

Before launching any agents, verify ALL of the following:

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
  "run_in_background": true,  // MUST be boolean true (not string "true")
  "mode": "bypassPermissions"  // required so agents can write output files without prompting
}
```

Full prompt per agent:

```
Review [TARGET].

OUTPUT REQUIREMENT (most important): Write your complete findings to
.multi-reviews/review-[SHORT_NAME].md using the Write tool. Do NOT return findings
as text output. The file is how the orchestrator collects your results.

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

Launch all agents with `run_in_background: true`, then poll until all output files appear.

**Polling procedure (repeat every 10 seconds, up to 10 minutes):**

Maintain a pending-agents list initialized with all launched agents. Remove an agent from the list when it is marked done. Each cycle: for every still-pending agent, run steps 1-2 (agents may be marked done during this step). Then run step 3 once only if at least one agent is still pending after all step 1-2 iterations complete.

**Step 1: TaskOutput probe** (per pending agent): Call `TaskOutput(id, block: false, timeout: 0)`.
- `"Task is still running…"` → agent still running; skip to step 2.
- `"No task found with ID"` → agent finished, ID expired; no fallback content; skip to step 2.
- `"No task output available"` → agent finished, produced no text output; no fallback content; skip to step 2.
- Any other non-empty content → agent finished; save this content as the TaskOutput fallback; skip to step 2.

**Step 2: File check** (per pending agent): Run `ls .multi-reviews/review-<short-name>.md`.
- File exists and non-empty → agent wrote its findings; collect findings (see below); mark agent done.
- File missing or empty (treat empty as absent), and step 1 returned `"Task is still running…"` → agent still pending; leave in pending list.
- File missing or empty, and step 1 saved fallback content (case 4 above) → agent done, no file; collect findings using TaskOutput fallback (see below); mark agent done.
- File missing or empty, and step 1 returned an expiry or no-output string (cases 2 or 3 above) → agent done, no fallback available; warn the user and skip this agent; mark agent done.

**Step 3: Sleep** (once per cycle, only if agents remain pending): Call `Bash("sleep 10")`.

**When an agent is detected as finished**, collect findings using this priority order:

1. **File:** read `.multi-reviews/review-<short-name>.md`. If it exists and is non-empty, use it. Apply the Normalization Pass and write it back.
2. **TaskOutput content:** if file is missing or empty, and the last `TaskOutput` probe returned non-empty content (not a known status string: `"Task is still running…"`, `"No task found with ID"`, or `"No task output available"`), write it to `.multi-reviews/review-<short-name>.md` (with the standard header prepended), then apply the Normalization Pass.
3. **Skip:** if both are empty or unavailable, warn the user and skip this agent in subsequent phases.

After 10 minutes, treat any agent with no file as skipped.

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

**Unparseable output:** If an agent returns results that cannot be parsed into severity/findings (e.g., unstructured text, errors), print: `│ ⚠ Could not parse findings. See .multi-reviews/review-<short-name>.md`

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

Write your validated findings to .multi-reviews/validated-[SHORT_NAME].md. Do NOT return them as text output.
```

Launch validators using this parameters block (substitute `[SHORT_NAME]`):

```jsonc
{
  "subagent_type": "general-purpose",
  "description": "validate [SHORT_NAME] review",
  "prompt": "<validator prompt above>",
  "run_in_background": true,  // MUST be boolean true (not string "true")
  "mode": "bypassPermissions"  // required so validators can write output files without prompting
}
```

Poll for `validated-<short-name>.md` files using the same procedure as Phase 2 (Steps 1-3, including the TaskOutput fallback if a validated file is missing, every 10 seconds, up to 10 minutes). After all validators complete, apply the Normalization Pass (see below) to each `validated-<short-name>.md` file before proceeding to Phase 4.

## Normalization Pass

Apply this pass to each review or validated file after reading it, before writing it back.
Make only label substitutions. Do not reword, reorder, or restructure any content.

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
