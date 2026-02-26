# pr-desc-review Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a Claude Code plugin that reviews PR descriptions against actual implementation, reports discrepancies, and suggests corrected text. Works standalone and as a multi-review compatible agent.

**Architecture:** Dual definitions — SKILL.md for interactive standalone use, agents/desc-reviewer.md for headless multi-review integration. Both share the same review methodology (compare PR description claims against diff reality).

**Tech Stack:** Claude Code plugin system (YAML frontmatter + markdown), `gh` CLI for PR data

---

### Task 1: Scaffold the plugin

**Files:**
- Creates: `pr-desc-review/.claude-plugin/plugin.json`
- Creates: `pr-desc-review/package.json`
- Creates: `pr-desc-review/skills/pr-desc-review/SKILL.md` (placeholder)
- Modifies: `.claude-plugin/marketplace.json`
- Modifies: `commitlint.config.js`
- Modifies: `package.json` (root)

**Step 1: Run the scaffold script**

Run: `npm run scaffold -- pr-desc-review`
Expected: "Plugin 'pr-desc-review' created successfully!"

**Step 2: Verify scaffold output**

Run: `npm run validate`
Expected: All validations passed (3 plugins now)

**Step 3: Commit**

```bash
git add pr-desc-review/ .claude-plugin/marketplace.json commitlint.config.js package.json
git commit -m "feat(pr-desc-review): scaffold plugin structure"
```

---

### Task 2: Fill in plugin metadata

**Files:**
- Modify: `pr-desc-review/.claude-plugin/plugin.json`
- Modify: `pr-desc-review/package.json`
- Modify: `.claude-plugin/marketplace.json`

**Step 1: Update plugin.json description**

Replace the TODO in `pr-desc-review/.claude-plugin/plugin.json`:

```json
{
  "name": "pr-desc-review",
  "version": "1.0.0",
  "description": "Review PR descriptions to ensure they accurately reflect the implementation",
  "author": {
    "name": "gchiam"
  }
}
```

**Step 2: Update package.json description**

Replace the TODO in `pr-desc-review/package.json`:

```json
{
  "name": "pr-desc-review",
  "version": "1.0.0",
  "private": true,
  "description": "Review PR descriptions to ensure they accurately reflect the implementation"
}
```

**Step 3: Update marketplace.json description**

In `.claude-plugin/marketplace.json`, replace the TODO description for pr-desc-review:

```json
{
  "name": "pr-desc-review",
  "source": "./pr-desc-review",
  "description": "Review PR descriptions to ensure they accurately reflect the implementation"
}
```

**Step 4: Validate**

Run: `npm run validate`
Expected: All validations passed

**Step 5: Commit**

```bash
git add pr-desc-review/.claude-plugin/plugin.json pr-desc-review/package.json .claude-plugin/marketplace.json
git commit -m "docs(pr-desc-review): fill in plugin metadata and descriptions"
```

---

### Task 3: Write the SKILL.md

This is the core deliverable — the interactive skill for standalone `/pr-desc-review` invocation.

**Files:**
- Modify: `pr-desc-review/skills/pr-desc-review/SKILL.md`

**Step 1: Write the complete SKILL.md**

Replace the entire scaffold placeholder with the full skill definition. The skill must:

1. **YAML frontmatter:**
   - `name: pr-desc-review`
   - `description:` mentioning "review PR description", "PR accuracy", "description matches implementation", and "code review" (so it triggers on review requests)

2. **Rules section:**
   - Always use `gh` CLI (not manual API calls)
   - Never auto-update the PR description — only suggest
   - If no PR found for current branch, inform user and stop

3. **Phase 1: Gather Context**
   - Auto-detect PR: `gh pr view --json number,title,body,url`
   - If no PR, exit with message
   - Fetch diff: `gh pr diff`
   - Print header with PR number and title

4. **Phase 2: Analyze**
   - Parse the PR description body into individual claims (what it says was done)
   - Analyze the diff: which files changed, what was added/removed/modified
   - Compare each claim against the diff:
     - **Claimed changes not in diff** — description mentions something not in the code
     - **Changes not mentioned** — significant changes with no mention in description
     - **Accuracy of stated behavior** — description says X but code does Y
     - **Scope mismatch** — description implies small change but diff is large (or vice versa)

5. **Phase 3: Report**
   - Print structured report using this exact format:
     ```
     PR Description Review - PR #<NUMBER>
     ════════════════════════════════════════

     [✓] <N> claims verified
     [✗] <N> discrepancies found

     [Missing] <description of unmentioned change>
     [Inaccurate] <description of incorrect claim>
     [Incomplete] <description of vague claim>

     Suggested PR Description:
     ─────────────────────────
     ## Summary
     - <bullet points reflecting actual implementation>
     ```
   - If no discrepancies found, print congratulatory message instead

**Step 2: Validate**

Run: `npm run validate`
Expected: All validations passed

**Step 3: Commit**

```bash
git add pr-desc-review/skills/pr-desc-review/SKILL.md
git commit -m "feat(pr-desc-review): write SKILL.md for standalone PR description review"
```

---

### Task 4: Write the agent definition

This makes the plugin discoverable by multi-review.

**Files:**
- Create: `pr-desc-review/agents/desc-reviewer.md`

**Step 1: Create the agents directory**

```bash
mkdir -p pr-desc-review/agents
```

**Step 2: Write desc-reviewer.md**

Create `pr-desc-review/agents/desc-reviewer.md` with:

1. **YAML frontmatter:**
   - `description:` must include "review" and "code review" keywords so multi-review Phase 1 discovers it. Describe it as a specialized code review agent that checks PR description accuracy.

2. **Markdown body:**
   - Role: review agent that validates PR descriptions against implementation
   - Workflow:
     1. Identify the PR being reviewed (from the prompt's target)
     2. Fetch PR description via `gh pr view --json title,body`
     3. Fetch diff via `gh pr diff` (or use the diff context provided by multi-review)
     4. Run the same 4 comparison checks from the methodology
     5. Return structured markdown with discrepancies and suggested description
   - Output format: same structured report (discrepancies + suggested text)
   - Critical: do NOT post comments to PR, do NOT use `gh pr comment`
   - Critical: return ALL findings as markdown (multi-review expects this)

**Step 3: Validate**

Run: `npm run validate`
Expected: All validations passed

**Step 4: Commit**

```bash
git add pr-desc-review/agents/desc-reviewer.md
git commit -m "feat(pr-desc-review): add desc-reviewer agent for multi-review compatibility"
```

---

### Task 5: End-to-end validation

**Step 1: Run full validation**

Run: `npm run validate`
Expected: All validations passed (marketplace + 3 plugins)

**Step 2: Verify plugin structure is complete**

Run: `ls -la pr-desc-review/ pr-desc-review/.claude-plugin/ pr-desc-review/skills/pr-desc-review/ pr-desc-review/agents/`
Expected:
- `pr-desc-review/.claude-plugin/plugin.json` exists
- `pr-desc-review/package.json` exists
- `pr-desc-review/skills/pr-desc-review/SKILL.md` exists
- `pr-desc-review/agents/desc-reviewer.md` exists

**Step 3: Verify marketplace registration**

Run: `cat .claude-plugin/marketplace.json | grep pr-desc-review`
Expected: Shows the plugin entry

**Step 4: Verify commitlint scope**

Run: `cat commitlint.config.js | grep pr-desc-review`
Expected: Shows 'pr-desc-review' in scope-enum

**Step 5: Test locally (optional, requires Claude CLI)**

Run: `npm run dev -- pr-desc-review`
Expected: Launches Claude session with plugin loaded
