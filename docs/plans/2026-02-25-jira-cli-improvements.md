# jira-cli SKILL.md Restructure — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restructure jira-cli SKILL.md to be a focused agent guide — remove duplicate reference material, reorganize sections, add discovery patterns and batch workflows.

**Architecture:** Single-file restructure of `jira-cli/skills/jira-cli/SKILL.md`. Work top-down through the document: trim Reading Output, move Defensive Patterns up, add Discovery Patterns, expand Common Workflows, trim Issue Operations and Epics/Sprints, expand Error Handling.

**Tech Stack:** Markdown only. Validate with `npm run validate`.

---

### Task 1: Trim Reading Output and Move Defensive Patterns into Foundations

**Files:**
- Modify: `jira-cli/skills/jira-cli/SKILL.md:84-133` (trim Reading Output)
- Modify: `jira-cli/skills/jira-cli/SKILL.md:384-424` (move Defensive Patterns)

**Step 1: Replace the Reading Output section**

Replace lines 84-97 (from `## Reading Output` through the line ending with
`(like description, comments, custom fields).`) with this trimmed version that
removes the flag explanations (already in commands.md) and keeps only a brief
summary:

````markdown
## Reading Output

Plain output (`--plain`) is tab-delimited. Use `--no-headers` when parsing
programmatically. Use `--raw` for full JSON when you need fields not available
in plain mode. See `references/commands.md` for all output flags (`--columns`,
`--csv`, `--delimiter`, etc.).
````

Keep the existing `### Parsing Plain Output`, `### Parsing JSON Output`, and
`### Special Characters` subsections (lines 99-133) unchanged.

**Step 2: Move Defensive Patterns up**

Cut the entire `## Defensive Patterns` section (lines 384-424, from
`## Defensive Patterns` through `Do not retry 4xx errors (except 429) — they
indicate a permanent problem.`) and paste it immediately after the
`### Special Characters` subsection, before `## Issue Operations`.

Keep the Defensive Patterns content exactly as-is.

**Step 3: Validate**

Run: `npm run validate`
Expected: All validations passed

**Step 4: Commit**

```bash
git add jira-cli/skills/jira-cli/SKILL.md
git commit -m "refactor(jira-cli): trim Reading Output and move Defensive Patterns up"
```

---

### Task 2: Add Discovery Patterns Section

**Files:**
- Modify: `jira-cli/skills/jira-cli/SKILL.md` (insert after Defensive Patterns, before Common Workflows)

**Step 1: Insert Discovery Patterns section**

Insert the following new section after the Defensive Patterns section (after
"Do not retry 4xx errors...") and before `## Common Workflows`:

````markdown
## Discovery Patterns

Before running commands, you often need to discover IDs and names. Use these
patterns to find what you need.

### Project Keys

```bash
# List available projects with keys
jira project list --plain --no-headers | awk -F'\t' '{print $1, $2}'
```

If the user says "my project" without a key, list projects and ask which one.

### Sprint IDs

Sprint commands need numeric IDs. Extract from the sprint list:

```bash
# Get active sprint ID
SPRINT_ID=$(jira sprint list --state active --table --plain --no-headers | awk -F'\t' '{print $1}' | head -1)
```

### Status Names

Status names are instance-specific and case-sensitive. When `jira issue move`
fails with "No transition found", discover valid transitions:

```bash
# Get current status
jira issue view ISSUE-123 --raw | jq -r '.fields.status.name'

# List valid transitions from current state
jira issue view ISSUE-123 --raw | jq -r '.transitions[]?.name'
```

### Custom Field IDs

Custom fields use IDs like `customfield_10001`. Discover them from any issue:

```bash
# List all custom field IDs on an issue
jira issue view ISSUE-123 --raw | jq -r '.fields | keys[] | select(startswith("customfield"))'

# Get a specific custom field value
jira issue view ISSUE-123 --raw | jq -r '.fields.customfield_10001'
```

### Issue Types

Issue types vary by project. Common safe defaults: `Task`, `Bug`, `Story`.
To discover available types, inspect an existing issue:

```bash
jira issue view ISSUE-123 --raw | jq -r '.fields.issuetype.name'
```
````

**Step 2: Validate**

Run: `npm run validate`
Expected: All validations passed

**Step 3: Commit**

```bash
git add jira-cli/skills/jira-cli/SKILL.md
git commit -m "feat(jira-cli): add discovery patterns section"
```

---

### Task 3: Expand Common Workflows

**Files:**
- Modify: `jira-cli/skills/jira-cli/SKILL.md` (Common Workflows section)

**Step 1: Fix "Create a Bug" workflow**

In the existing "Create a Bug from a Code Finding" workflow, replace the
`python3 -c` JSON parsing with `jq` for consistency:

Replace:
```
--no-input --raw 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['key'])")
```

With:
```
--no-input --raw | jq -r '.key')
```

**Step 2: Add four new workflows**

Append the following workflows after the existing "Bulk Status Check for a
Team" workflow, before the next `##` section:

````markdown

### Batch Create Issues

Create multiple related issues with rate-limit-safe spacing:

```bash
KEYS=()
for SUMMARY in "Set up CI pipeline" "Add unit tests" "Write API docs"; do
  KEY=$(jira issue create -tTask -s"$SUMMARY" -PEPIC-42 \
    --no-input --raw | jq -r '.key')
  KEYS+=("$KEY")
  echo "Created $KEY"
  sleep 1
done

# Add all created issues to a sprint
jira sprint add "$SPRINT_ID" "${KEYS[@]}"
```

### Batch Transition Issues

Move multiple issues to a target status. Continues on failure and reports
which issues failed:

```bash
FAILED=()
KEYS=$(jira issue list -q "project = PROJ AND status = 'Code Review'" \
  --plain --no-headers | awk -F'\t' '{print $2}')

for KEY in $KEYS; do
  if ! jira issue move "$KEY" "Done" --comment "Sprint cleanup" -RFixed 2>/dev/null; then
    FAILED+=("$KEY")
  fi
  sleep 1
done

if [ ${#FAILED[@]} -gt 0 ]; then
  echo "Failed to transition: ${FAILED[*]}"
fi
```

### Triage Backlog

Query unassigned issues and assign/prioritize them:

```bash
# List unassigned issues in priority order
jira issue list -pPROJ -ax --plain --columns key,summary,priority,created \
  --order-by priority

# Assign and prioritize a specific issue
jira issue assign PROJ-456 "$ME"
jira issue edit PROJ-456 -yHigh -l"sprint-candidate" --no-input
```

### Sprint Planning

Find the target sprint, query candidate issues, and add them:

```bash
# Get the next sprint ID
SPRINT_ID=$(jira sprint list --state future --table --plain --no-headers \
  | awk -F'\t' '{print $1}' | head -1)

# Find candidate issues
jira issue list -pPROJ -s"To Do" -l"sprint-candidate" \
  --plain --columns key,summary,priority

# Add selected issues to the sprint
jira sprint add "$SPRINT_ID" PROJ-101 PROJ-102 PROJ-103
```
````

**Step 3: Validate**

Run: `npm run validate`
Expected: All validations passed

**Step 4: Commit**

```bash
git add jira-cli/skills/jira-cli/SKILL.md
git commit -m "feat(jira-cli): expand common workflows with batch and planning patterns"
```

---

### Task 4: Trim Issue Operations

**Files:**
- Modify: `jira-cli/skills/jira-cli/SKILL.md` (Issue Operations section)

**Step 1: Replace the Issue Operations section**

Replace the entire `## Issue Operations` section (from `## Issue Operations`
through the end of `### Linking and Cloning`, ending at the `jira issue unlink`
line) with this trimmed version — one representative example per operation:

````markdown
## Issue Operations

One example per operation. See `references/commands.md` for all flags.

### List and Search

```bash
# My open issues
jira issue list -a"$ME" --plain

# Filter by status, type, and project
jira issue list -pPROJ -s"In Progress" -tBug --plain

# Search by text
jira issue list "login crash" --plain
```

### View

```bash
# Plain text view with comments
jira issue view ISSUE-123 --plain --comments 5

# Full JSON for detailed inspection
jira issue view ISSUE-123 --raw
```

### Create

```bash
# Create a bug (minimum: -t, -s, --no-input)
jira issue create -tBug -s"Login fails on mobile" -yHigh \
  -b"Steps to reproduce..." --no-input

# Capture the created issue key
KEY=$(jira issue create -tTask -s"New task" --no-input --raw | jq -r '.key')
```

### Edit

```bash
# Update fields
jira issue edit ISSUE-123 -s"Updated title" -yHigh --no-input

# Pipe multi-line description
echo "New detailed description" | jira issue edit ISSUE-123 --no-input
```

### Transition (Move)

```bash
# Move to a status (name must match exactly, case-sensitive)
jira issue move ISSUE-123 "In Progress"

# Complete with comment and resolution
jira issue move ISSUE-123 "Done" --comment "Completed" -RFixed
```

### Assign

```bash
jira issue assign ISSUE-123 "$ME"        # Assign to self
jira issue assign ISSUE-123 x            # Unassign
```

### Comment

```bash
jira issue comment add ISSUE-123 "Root cause identified" --no-input
```

### Work Log

```bash
jira issue worklog add ISSUE-123 "2h 30m" --comment "Implementation" --no-input
```

### Link and Clone

```bash
jira issue link ISSUE-123 ISSUE-456 Blocks
jira issue clone ISSUE-123 -s"Cloned: New summary"
```
````

**Step 2: Validate**

Run: `npm run validate`
Expected: All validations passed

**Step 3: Commit**

```bash
git add jira-cli/skills/jira-cli/SKILL.md
git commit -m "refactor(jira-cli): trim issue operations to one example per op"
```

---

### Task 5: Trim Epics, Sprints, and Projects

**Files:**
- Modify: `jira-cli/skills/jira-cli/SKILL.md` (Epics, Sprints, Projects sections)

**Step 1: Replace the three sections**

Replace the `## Epics`, `## Sprints`, and `## Projects and Boards` sections
(everything from `## Epics` through `jira open`) with this trimmed version:

````markdown
## Epics

```bash
jira epic list --table --plain               # List all epics
jira epic list EPIC-42 --plain               # Issues in an epic
jira epic create -n"Q1 Auth" -s"Summary" --no-input  # Create
jira epic add EPIC-42 ISSUE-123 ISSUE-456    # Add issues to epic
```

See `references/commands.md` for `epic remove` and all epic flags.

## Sprints

```bash
jira sprint list --state active --table --plain   # Active sprints
jira sprint list --current --plain -a"$ME"        # My current sprint issues
jira sprint add SPRINT_ID ISSUE-123 ISSUE-456     # Add issues to sprint
```

See `references/commands.md` for `sprint close`, `--prev`, `--next`, and all
sprint flags.

## Projects and Boards

```bash
jira project list --plain     # List projects
jira board list --plain       # List boards
jira open ISSUE-123           # Open in browser
```
````

**Step 2: Validate**

Run: `npm run validate`
Expected: All validations passed

**Step 3: Commit**

```bash
git add jira-cli/skills/jira-cli/SKILL.md
git commit -m "refactor(jira-cli): trim epics, sprints, projects sections"
```

---

### Task 6: Expand Error Handling and Update Footer

**Files:**
- Modify: `jira-cli/skills/jira-cli/SKILL.md` (Error Handling and footer)

**Step 1: Replace the Error Handling section**

Replace the entire `## Error Handling` section (from `## Error Handling`
through `Avoid running many commands in rapid succession.`) with this expanded
version:

````markdown
## Error Handling

**"Issue does not exist"**: Double-check the issue key. Keys are case-sensitive
and project-prefixed (e.g., PROJ-123, not just 123).

**"No transition found"**: The status name doesn't match available transitions.
Use the discovery pattern:
`jira issue view ISSUE-123 --raw | jq -r '.transitions[]?.name'`

**Command hangs**: You likely forgot `--no-input` on a create/edit command, or
`--plain` on a list command. Kill the process and retry with the correct flags.

**"401 Unauthorized"**: The JIRA_API_TOKEN is missing or expired. Check with
`echo $JIRA_API_TOKEN` and verify it's set.

**Rate limiting (429)**: Wait at least 5 seconds before retrying. See the
Defensive Patterns section for spacing and retry guidance.

**Custom field errors**: The field ID doesn't match. Use the discovery pattern:
`jira issue view ISSUE-123 --raw | jq -r '.fields | keys[] | select(startswith("customfield"))'`

**Partial batch failure**: When a batch loop has mixed results, collect failures
and report both lists. Retry only the failures:

```bash
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "Succeeded: ${SUCCEEDED[*]}"
  echo "Failed: ${FAILED[*]}"
  # Retry only failures
  for KEY in "${FAILED[@]}"; do
    jira issue move "$KEY" "Done" -RFixed
    sleep 1
  done
fi
```
````

**Step 2: Replace the footer**

Replace the `## Full Command Reference` section (from `## Full Command
Reference` through end of file) with:

````markdown
## Full Command Reference

For complete flag documentation on every command — including flags not shown
above (`--fix-version`, `--original-estimate`, `--skip-notify`, `--internal`,
`--delimiter`, `--csv`, and more) — read `references/commands.md` in this
skill's directory.
````

**Step 3: Validate**

Run: `npm run validate`
Expected: All validations passed

**Step 4: Commit**

```bash
git add jira-cli/skills/jira-cli/SKILL.md
git commit -m "feat(jira-cli): expand error handling and update footer"
```

---

### Task 7: Final Validation

**Files:**
- Read: `jira-cli/skills/jira-cli/SKILL.md` (full file review)

**Step 1: Validate plugin**

Run: `npm run validate`
Expected: All validations passed

**Step 2: Verify document structure**

Read through the final SKILL.md and verify these sections exist in order:

1. Prerequisites
2. Critical Rules
3. Choosing Your Approach: Flags vs JQL
4. Reading Output (trimmed — parsing examples only)
5. Defensive Patterns (moved up from end)
6. Discovery Patterns (new)
7. Common Workflows (9 workflows total — 5 existing + 4 new)
8. Issue Operations (trimmed — one example per op)
9. Epics (trimmed)
10. Sprints (trimmed)
11. Projects and Boards (trimmed)
12. Error Handling (expanded — 7 error types)
13. Full Command Reference (updated footer)

**Step 3: Verify no duplicate content**

Confirm that flag documentation (column lists, output flag explanations, flag
catalogs per command) has been removed from SKILL.md and exists only in
`references/commands.md`.

**Step 4: Check line count**

Run: `wc -l jira-cli/skills/jira-cli/SKILL.md`
Expected: Roughly 300-350 lines (down from 448, despite new content)
