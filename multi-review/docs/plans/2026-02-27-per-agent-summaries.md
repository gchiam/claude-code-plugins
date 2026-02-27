# Per-Agent Inline Summaries Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Print per-agent summaries to the console after all review agents complete during Phase 2, showing severity counts and top finding previews.

**Architecture:** Two files change — `SKILL.md` gets an updated Phase 2 description and rule, `references/phase-templates.md` gets a new "Per-Agent Summary Format" section with the summary format template. Agents run and are collected in parallel; summaries are printed as a batch before Phase 3. No new files, options, or dependencies.

**Tech Stack:** Claude skill files (markdown instruction files)

---

### Task 1: Update SKILL.md Phase 2 description

**Files:**
- Modify: `multi-review/skills/multi-review/SKILL.md:34` (Rule 2)
- Modify: `multi-review/skills/multi-review/SKILL.md:58-62` (Phase 2 section)

**Step 1: Update Rule 2 to reflect per-agent summary printing**

In `SKILL.md`, replace Rule 2 (line 34):

```
2. **Wait for all agents.** `TaskOutput` with `block: true` on every agent ID before writing files or starting the next phase.
```

with:

```
2. **Collect results sequentially.** After launching all agents in parallel, call `TaskOutput` with `block: true` on each agent ID one at a time. As each returns, print its per-agent summary and write its review file before collecting the next. Do not start Phase 3 until all agents are collected.
```

**Step 2: Update Phase 2 section**

In `SKILL.md`, replace the Phase 2 section (lines 58-62):

```markdown
## Phase 2: Parallel Review Execution

Launch one agent per selected type in a single Task message with `run_in_background: true`. Wait for all via `TaskOutput`. Write results to `.multi-reviews/review-<short-name>.md`.

See [references/phase-templates.md](references/phase-templates.md) for prompt templates and output file format.
```

with:

```markdown
## Phase 2: Parallel Review Execution

Launch one agent per selected type in a single Task message with `run_in_background: true`. Collect results one-by-one via sequential `TaskOutput` calls. As each agent completes, **print a per-agent summary** to the console and write results to `.multi-reviews/review-<short-name>.md`.

Per-agent summary format:

​```text
[✓] Phase 2: Reviews (<N>/<TOTAL> complete)
    ┌── <short-name> ──────────────────────────
    │ <severity counts>
    │ • <top finding summary> (<file>:<line>)
    │ • <top finding summary> (<file>:<line>)
    └────────────────────────────────────────
​```

See [references/phase-templates.md](references/phase-templates.md) for prompt templates, output file format, and summary parsing rules.
```

**Step 3: Verify the edit**

Read back `SKILL.md` and confirm:
- Rule 2 says "Collect results sequentially" with per-agent summary printing
- Phase 2 includes the summary format block
- No other sections were affected

**Step 4: Commit**

```bash
git add multi-review/skills/multi-review/SKILL.md
git commit -m "feat(multi-review): add per-agent summary to Phase 2 in SKILL.md"
```

---

### Task 2: Update phase-templates.md with sequential collection and summary format

**Files:**
- Modify: `multi-review/skills/multi-review/references/phase-templates.md:78-84` (Collecting Results section)

**Step 1: Replace the "Collecting Results" section**

In `references/phase-templates.md`, replace lines 78-84:

```markdown
### Collecting Results

Wait for ALL agents before writing output files:

​```jsonc
{"task_id": "[agent-id]", "block": true, "timeout": 300000}
​```
```

with:

```markdown
### Collecting Results

Collect results **one agent at a time**. For each agent ID (in launch order):

1. Call `TaskOutput` with `block: true` and `timeout: 300000`
2. Parse the agent's findings from the returned result
3. Print the per-agent summary to the console (see format below)
4. Write the review file to `.multi-reviews/review-<short-name>.md`

​```jsonc
// Call sequentially for each agent — agents are already running in parallel
{"task_id": "[agent-id-1]", "block": true, "timeout": 300000}
// → print summary, write file
{"task_id": "[agent-id-2]", "block": true, "timeout": 300000}
// → print summary, write file
​```

### Per-Agent Summary Format

Print this to the console after each agent's result is collected:

​```text
[✓] Phase 2: Reviews (<N>/<TOTAL> complete)
    ┌── <short-name> ──────────────────────────
    │ <severity counts>
    │ • <finding summary> (<file>:<line>)
    └────────────────────────────────────────
​```

**Severity counts line:** List non-zero severity categories separated by ` · `. Example: `2 critical · 3 important · 1 minor`

**Finding preview lines:** One line per critical or important finding, formatted as:
`• <1-line description> (<file-path>:<line-number>)`

Show at most 5 preview lines. If more than 5 critical/important findings exist, show the top 5 by severity (critical first) and append: `│ ... and <N> more critical/important findings`

If no critical or important findings exist, print: `│ No critical or important issues found`

**Progress counter:** `<N>` is the number of agents collected so far, `<TOTAL>` is total selected agents.
```

**Step 2: Verify the edit**

Read back `references/phase-templates.md` and confirm:
- "Collecting Results" section describes sequential collection
- "Per-Agent Summary Format" section is present with the box format
- Severity counts, finding previews, and progress counter are all documented
- Phase 3 and Phase 4 sections are unchanged

**Step 3: Commit**

```bash
git add multi-review/skills/multi-review/references/phase-templates.md
git commit -m "feat(multi-review): add per-agent summary format to phase templates"
```

---

### Task 3: Validate the plugin

**Step 1: Run plugin validation**

```bash
npm run validate
```

Expected: All validations pass.

**Step 2: Verify no unintended changes**

```bash
git diff HEAD~2 --stat
```

Expected: Only `SKILL.md` and `references/phase-templates.md` show changes (plus the plan/design docs).
