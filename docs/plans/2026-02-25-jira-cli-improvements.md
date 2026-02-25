# jira-cli SKILL.md Improvements — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add prerequisites/setup, expanded output parsing, and defensive patterns to jira-cli's SKILL.md.

**Architecture:** Three inline additions to a single file (`jira-cli/skills/jira-cli/SKILL.md`). No structural changes. Each addition is an independent section edit committed separately.

**Tech Stack:** Markdown (SKILL.md), npm run validate (plugin validation)

---

### Task 1: Add Prerequisites Section

**Files:**
- Modify: `jira-cli/skills/jira-cli/SKILL.md:22-23` (insert after line 22, before line 24 "## Critical Rules")

**Step 1: Add the Prerequisites section**

Insert the following between the intro paragraph (line 22) and "## Critical Rules" (line 24):

```markdown

## Prerequisites

Before using jira-cli commands, verify your setup:

1. **Install jira-cli**: `brew install ankitpokhrel/jira-cli/jira-cli` (or see
   [install docs](https://github.com/ankitpokhrel/jira-cli#installation))
2. **Initialize**: Run `jira init` and follow prompts (server URL, auth type, project)
3. **Set API token**: Export `JIRA_API_TOKEN` in your shell profile
4. **Verify**: Run `jira serverinfo --plain` — should print your Jira server version

If `jira serverinfo` fails, check:
- Token is set: `echo $JIRA_API_TOKEN`
- Config exists: `cat ~/.config/.jira/.config.yml`
- Network access to your Jira instance

```

Use the Edit tool with `old_string` matching the blank line + "## Critical Rules" and `new_string` containing the new section plus the original "## Critical Rules" heading.

**Step 2: Validate plugin**

Run: `npm run validate`
Expected: All validations passed

**Step 3: Commit**

```bash
git add jira-cli/skills/jira-cli/SKILL.md
git commit -m "feat(jira-cli): add prerequisites/setup section to SKILL.md"
```

---

### Task 2: Expand Output Parsing

**Files:**
- Modify: `jira-cli/skills/jira-cli/SKILL.md` (append after the "Reading Output" section, before "## Issue Operations")

**Step 1: Add parsing subsections**

Insert the following after line 82 (`(like description, comments, custom fields).`) and before the blank line + `## Issue Operations`:

```markdown

### Parsing Plain Output

Plain output is tab-delimited. Extract specific fields with `awk`:

```bash
# Extract just issue keys (column 2)
jira issue list -a"$ME" --plain --no-headers | awk -F'\t' '{print $2}'

# Extract key and status (columns 2 and 4)
jira issue list --plain --no-headers | awk -F'\t' '{print $2, $4}'

# Filter rows by status
jira issue list --plain --no-headers | awk -F'\t' '$4 == "In Progress"'
```

### Parsing JSON Output

Use `--raw` with `jq` for structured data:

```bash
# Get issue description
jira issue view ISSUE-123 --raw | jq -r '.fields.description'

# Extract custom field value
jira issue view ISSUE-123 --raw | jq -r '.fields.customfield_10001'

# Get all issue keys from a list as JSON array
jira issue list -a"$ME" --raw | jq '[.[].key]'
```

### Special Characters

Summaries and descriptions may contain tabs, quotes, or newlines. When using
plain output for programmatic processing, prefer `--raw` (JSON) for fields that
may contain freeform text.

```

Use the Edit tool with `old_string` matching `(like description, comments, custom fields).\n\n## Issue Operations` and `new_string` containing the original line, the new subsections, then `## Issue Operations`.

**Step 2: Validate plugin**

Run: `npm run validate`
Expected: All validations passed

**Step 3: Commit**

```bash
git add jira-cli/skills/jira-cli/SKILL.md
git commit -m "feat(jira-cli): expand output parsing guidance in SKILL.md"
```

---

### Task 3: Add Defensive Patterns Section

**Files:**
- Modify: `jira-cli/skills/jira-cli/SKILL.md` (insert new section before "## Error Handling")

**Step 1: Add the Defensive Patterns section**

Insert the following before the `## Error Handling` heading:

```markdown
## Defensive Patterns

### Pagination

`jira issue list` returns at most 100 results by default. For larger result
sets, paginate explicitly:

```bash
# First 50 results
jira issue list -pPROJ --paginate 0:50 --plain

# Next 50
jira issue list -pPROJ --paginate 50:50 --plain
```

Stop paginating when the returned row count is less than the requested limit.

### Rate Limiting

Jira Cloud enforces API rate limits. When you receive a 429 response:

1. **Do not retry immediately.** Wait at least 5 seconds before the next call.
2. **Space sequential commands.** When running multiple commands in sequence
   (e.g., creating several issues), add `sleep 1` between calls.
3. **Prefer batch-capable flags** over loops — e.g., `jira epic add EPIC-1
   ISSUE-1 ISSUE-2 ISSUE-3` instead of three separate `epic add` calls.

### Retry on Transient Errors

Network timeouts and 5xx errors are transient. Retry up to 2 times with
increasing delay:

```bash
# Simple retry pattern
for i in 1 2 3; do
  jira issue view ISSUE-123 --plain && break
  sleep "$((i * 2))"
done
```

Do not retry 4xx errors (except 429) — they indicate a permanent problem.

```

Use the Edit tool with `old_string` matching `## Error Handling` and `new_string` containing the new section followed by `## Error Handling`.

**Step 2: Validate plugin**

Run: `npm run validate`
Expected: All validations passed

**Step 3: Commit**

```bash
git add jira-cli/skills/jira-cli/SKILL.md
git commit -m "feat(jira-cli): add defensive patterns section to SKILL.md"
```

---

### Task 4: Final Verification

**Step 1: Review the complete file**

Read `jira-cli/skills/jira-cli/SKILL.md` in full and verify:
- Prerequisites section appears between intro and Critical Rules
- Parsing subsections appear within Reading Output, before Issue Operations
- Defensive Patterns section appears before Error Handling
- No duplicate headings, no broken markdown

**Step 2: Run full validation**

Run: `npm run validate`
Expected: All validations passed

**Step 3: Verify git log**

Run: `git log --oneline -4`
Expected: Three new commits (one per task) plus the design doc commit.
