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

- [ ] User has confirmed the Phase 1 agent selection (or `--no-input` is set)
- [ ] You are using ONLY the confirmed/auto-selected agent types from Phase 1

### Agent prompt

For each agent, use this prompt:

```jsonc
{
  "subagent_type": "[AGENT_TYPE]",       // from Phase 1 discovery
  "description": "[AGENT_TYPE] review",
  "prompt": "Review [TARGET]. Do NOT post comments to PR. Return all findings as markdown.",
  "run_in_background": true
}
```

Full prompt per agent:

```
Review [TARGET].

CRITICAL INSTRUCTIONS:
1. Do NOT post any comments to the PR
2. Do NOT use `gh pr comment` or any GitHub posting commands
3. Capture ALL review output including issues, severity levels, and locations
4. Format output as structured markdown
5. Return the complete review findings

Configuration:
- Review scope: [diff-only | full-context]
- Files: [file list if specified]
```

### Output File Header

Include in each `.multi-reviews/review-<short-name>.md`:

```markdown
# Code Review Results

**Source:** <agent-type>
**Target:** PR #123 / branch-name
**Date:** <YYYY-MM-DD HH:mm:ss>
**Scope:** diff-only
**Files reviewed:** 12

---
```

Use a short name derived from the agent type (e.g., `coderabbit` from
`coderabbit:code-reviewer`, `pr-toolkit` from `pr-review-toolkit:code-reviewer`,
`superpowers` from `superpowers:code-reviewer`).

### Collecting Results

Wait for ALL agents before writing output files. Call `TaskOutput` for every agent (parallel calls are fine):

```jsonc
{"task_id": "[agent-id]", "block": true, "timeout": 300000}
```

After all agents complete, write each review file, then print all per-agent summaries (see format below) before starting Phase 3.

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

Launch one validation agent per review output:

```markdown
Read and evaluate the findings in .multi-reviews/review-<name>.md.

For each issue found:
1. Verify the issue is real (not a false positive)
2. Check if it's a pre-existing issue vs new in this PR
3. Assess severity: Critical / Important / Minor / Nitpick
4. Evaluate confidence level (0-100)
5. Check if issue is actionable

Filter criteria:
- Remove false positives
- Remove pre-existing issues not introduced by this PR
- Remove issues that linters/type checkers would catch
- Keep issues with confidence >= [CONFIDENCE_THRESHOLD]

Output: Validated findings with confidence scores and reasoning.
```

Output: `.multi-reviews/validated-<short-name>.md`

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
2. **Categorize** - Group by severity (Critical > Important > Suggestions)
3. **Prioritize** - Security issues first, then by confidence score
4. **Cross-reference** - Note which review(s) found each issue
5. **Synthesize** - Create actionable summary

Report sections: Executive Summary, Security Issues, Critical Issues,
Important Issues, Suggestions, Positive Observations, Review Agreement
Analysis, Recommended Actions.

Output file: `.multi-reviews/pr-review-summary.md`
