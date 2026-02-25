---
name: multi-review
description: >-
  Use when reviewing a PR or set of changed files with comprehensive
  multi-perspective analysis, when wanting parallel code reviews from
  different methodologies, or when needing validated and aggregated
  review findings including security analysis
---

# Multi Review

> **STOP. Your first action is Phase 1 below. Do NOT launch any agents
> until you have printed the Phase 1 discovery report.**

## Rules

1. **Phase 1 first.** Complete Phase 1 and print the discovery report
   before doing anything else. If you skip this, you will launch the
   wrong agents.
2. **Wait for all agents.** Use `TaskOutput` with `block: true` on
   every agent ID before writing output files or starting the next phase.

---

## Phase 1: Discover Available Review Agents

Discover what review agent types are available by inspecting the Task
tool's `subagent_type` list in the system prompt.

**Step 1: Extract review-related agent types.** Look at the Task tool
description for agent types whose name or description mentions "review",
"code review", "PR review", or "code quality". These use the
`plugin:agent-name` format (e.g., `coderabbit:code-reviewer`).

**Step 2: Filter.**
- Exclude anything containing `multi-review` (this skill — avoids recursion).
- If the same plugin appears with multiple agent types, pick the one
  most focused on code review.
- Select up to `--max-reviewers` agents (default: 3). If set to `all`,
  select every discovered agent. If more agents are available than the
  limit, prefer diversity of perspective (general review, security
  review, style/quality review). Report all discovered agents and
  indicate which were selected vs skipped.

**Step 3: Print the discovery report.**

Phase 1 is **not complete** until you print the report below. You MUST
output this exact format — do not paraphrase, summarize, or skip it.
Replace the placeholders with actual values:

```text
Multi Review - PR #<NUMBER>
════════════════════════════════════════

[✓] Phase 1: Discovered <N> review agents (max-reviewers: <MAX>):
    ├── [selected] <agent-type>
    ├── [selected] <agent-type>
    ├── [selected] <agent-type>
    └── [skipped]  <agent-type>       # include for every agent beyond max
```

- One line per discovered agent, marked `[selected]` or `[skipped]`.
- Use `├──` for all lines except the last, which uses `└──`.
- If zero review agents are found, **STOP** and inform the user to
  install review plugins.

**Step 4: Get user confirmation.**

If `--no-input` is set, skip this step — proceed directly to Phase 2
with the auto-selected agents from Step 2.

Otherwise, use `AskUserQuestion` with `multiSelect: true` to let the
user pick which agents to run. List ALL discovered agents as options
(all unchecked by default). Append "(Recommended)" to the label of
agents marked `[selected]` in the report so the user knows which ones
were auto-selected.

Set `max-reviewers` to the number of agents the user selected.

After the user submits, reprint the discovery report with the updated
selection, then proceed to Phase 2.

**Do NOT proceed to Phase 2 until the user confirms the selection
(unless `--no-input` is set).**

## Phase 2: Parallel Review Execution

### Pre-launch checklist

Before launching any agents, verify ALL of the following:

- [ ] User has confirmed the Phase 1 agent selection (or `--no-input` is set)
- [ ] You are using ONLY the confirmed/auto-selected agent types from Phase 1

### Launch agents

Launch **one agent per selected review agent type** from Phase 1 in a
single Task tool message:

```jsonc
{
  "subagent_type": "[AGENT_TYPE]",       // from Phase 1 discovery
  "description": "[AGENT_TYPE] review",
  "prompt": "Review [TARGET]. Do NOT post comments to PR. Return all findings as markdown.",
  "run_in_background": true
}
```

`[AGENT_TYPE]` = the discovered agent type from Phase 1 (e.g., `coderabbit:code-reviewer`).
`[TARGET]` = the PR number, branch name, or file list being reviewed.

For each agent, the prompt should include:

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

### Phase 2 Output Files

**IMPORTANT:** Use `TaskOutput` with `block: true` on ALL agent IDs
before proceeding. Do NOT write output files until all agents have returned.

```jsonc
{"task_id": "[agent-id]", "block": true, "timeout": 300000}
```

After all agents complete, write results to output directory. Name each file
based on the agent type that produced it:

- `review-<short-name>.md` - Output from each reviewer

Use a short name derived from the agent type (e.g., `coderabbit` from
`coderabbit:code-reviewer`, `pr-toolkit` from `pr-review-toolkit:code-reviewer`,
`superpowers` from `superpowers:code-reviewer`).

Include header in each file:

```markdown
# Code Review Results

**Source:** <agent-type>
**Target:** PR #123 / branch-name
**Date:** 2024-01-23 14:30:52
**Scope:** diff-only
**Files reviewed:** 12

---
```

## Phase 3: Parallel Validation

Launch **one validation agent per review output** to evaluate findings:

### Validator prompt template

```markdown
Read and evaluate the findings in review-<name>.md.

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

### Validation Output Files

- `validated-<short-name>.md` - Validated findings from each review

## Phase 4: Aggregate Summary

After validation completes, generate a comprehensive summary.

### Deduplication Rules

Issues are considered duplicates if ANY of these match:

| Criteria                       | Threshold            |
| ------------------------------ | -------------------- |
| Same file + line range         | Within 5 lines       |
| Issue description similarity   | >80% semantic match  |
| Same code snippet referenced   | Exact match          |

**When duplicates found:**

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

Output file: `pr-review-summary.md`

## Post-Review Actions

After summary is generated, offer actions: view summary, generate fix
suggestions, create GitHub issues, post to PR (requires approval),
re-run on specific files, or exit.

---

## Reference

### Input Options

Specify what to review using these options:

| Option            | Description                        | Example            |
| ----------------- | ---------------------------------- | ------------------ |
| `--pr <number>`   | Review a specific PR               | `--pr 123`         |
| `--branch <name>` | Review branch vs main/master       | `--branch feat/x`  |
| `--files <paths>` | Review specific files only         | `--files src/*.ts` |
| `--base <ref>`    | Compare against specific base ref  | `--base develop`   |
| `--diff-only`     | Review only changed lines (default)|                    |
| `--full-context`  | Review entire files for context    |                    |

**Default behavior:** If no options specified, detect from current git state:

1. If on a branch with open PR → review that PR
2. If on a branch with uncommitted changes → review staged/unstaged changes
3. If on a branch ahead of main → review commits since divergence

### Configuration

| Option              | Description                  | Default       |
| ------------------- | ---------------------------- | ------------- |
| `--output-dir`      | Directory for review files   | `./.reviews/` |
| `--confidence`      | Min confidence threshold     | `70`          |
| `--max-reviewers`   | Max review agents (`all` for no limit) | `3`  |
| `--no-input`        | Skip agent selection prompt   | `false`       |
| `--skip-validation` | Skip Phase 3, use raw results| `false`       |
| `--revalidate`      | Re-run Phase 3-4 on existing | `false`       |

### Error Handling

| Scenario                      | Behavior                             |
| ----------------------------- | ------------------------------------ |
| One agent fails in Phase 2    | Continue with available, warn user   |
| All agents fail in Phase 2    | Abort with error details             |
| Validation fails              | Use unvalidated results with warning |
| Output directory not writable | Fallback to current directory        |
| PR not found                  | Prompt for correct PR number         |
| No changes detected           | Exit with "nothing to review" message|

**Always produce summary even with partial results** - indicate which
phases succeeded/failed.
