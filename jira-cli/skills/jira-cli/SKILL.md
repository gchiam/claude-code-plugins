---
name: jira-cli
description: >-
  Interact with Jira from the command line to create, list, view, edit, and
  transition issues, manage sprints and epics, and perform common Jira
  workflows. Use this skill whenever the user mentions Jira tickets, issues,
  tasks, stories, bugs, sprints, epics, boards, or any project management
  activity that involves Jira. Also trigger when users say things like "my
  tickets", "what am I working on", "create a bug", "move this to done",
  "assign this to me", "log time", "sprint progress", or "what's in the
  backlog". Even if the user doesn't explicitly say "Jira", if the context
  involves issue tracking or agile project management, use this skill.
compatibility: >-
  Requires jira-cli (https://github.com/ankitpokhrel/jira-cli) installed and
  configured with `jira init`. Requires JIRA_API_TOKEN environment variable.
---

# Jira CLI

Use `jira-cli` to interact with Jira from the terminal. This skill teaches you
how to pick the right commands, avoid interactive prompts that will hang, and
parse output reliably.

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

## Critical Rules

These rules prevent common failures when running jira-cli in a non-interactive
agent context:

1. **Always use `--plain` for list/view commands.** The default TUI output is
   interactive and unparseable. Add `--plain` to every `jira issue list`,
   `jira sprint list`, `jira epic list`, and `jira issue view` call.

2. **Always use `--no-input` for create/edit commands.** Without it, jira-cli
   opens an interactive editor which hangs indefinitely. Add `--no-input` to
   every `jira issue create`, `jira issue edit`, `jira epic create`,
   `jira issue comment add`, and `jira issue worklog add` call.

3. **Capture the current user early.** Run `jira me` at the start of any
   session that involves user-specific queries. Store the result and use it
   with `-a` flags instead of calling `jira me` inline with `$()` which can
   fail silently.

4. **Use `-p PROJECT` explicitly** when the user mentions a specific project,
   rather than relying on the default config.

## Choosing Your Approach: Flags vs JQL

jira-cli supports two filtering styles. Pick the right one:

**Use flags** when filtering on a single dimension or simple combinations:
```bash
jira issue list -a"user@example.com" -s"In Progress" --plain
```

**Use JQL (`-q`)** when you need complex logic, cross-project queries, OR
conditions, functions, or fields not covered by flags:
```bash
jira issue list -q "assignee = currentUser() AND status WAS 'In Progress' BEFORE '2024-01-01'" --plain
```

Common JQL patterns:
- Cross-project: `-q "project IN (PROJ1, PROJ2) AND assignee = currentUser()"`
- OR conditions: `-q "priority = High OR priority = Highest"`
- Text search: `-q "summary ~ 'login bug'"`
- Recently updated: `-q "updated >= -7d AND assignee = currentUser()"`
- Unassigned: `-q "assignee IS EMPTY AND project = PROJ"`
- Sub-tasks: `-q "parent = EPIC-123"`

## Reading Output

Plain output (`--plain`) is tab-delimited with default columns:
`TYPE`, `KEY`, `SUMMARY`, `STATUS`, `ASSIGNEE`. Use `--no-headers` when parsing
programmatically. Use `--raw` for full JSON when you need fields not available
in plain mode. See `references/commands.md` for all output flags (`--columns`,
`--csv`, `--delimiter`, etc.).

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
if [ -z "$SPRINT_ID" ]; then
  echo "No active sprint found" >&2
  exit 1
fi
```

### Status Names

Status names are instance-specific and case-sensitive. When `jira issue move`
fails with "No transition found", check the current status first:

```bash
# Get current status
jira issue view ISSUE-123 --raw | jq -r '.fields.status.name'
```

Note: The standard `--raw` response may not include a `transitions` array
(it requires `?expand=transitions` in the Jira REST API). If you cannot
discover transitions programmatically, try common status names like "To Do",
"In Progress", "In Review", "Done", or check your Jira board for the workflow.

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
To discover types used in a project, sample from existing issues:

```bash
# List distinct issue types used in a project
jira issue list -pPROJ --plain --columns type --no-headers | sort -u

# Check a specific issue's type
jira issue view ISSUE-123 --raw | jq -r '.fields.issuetype.name'
```

## Common Workflows

### Start of Day: What Am I Working On?

```bash
ME=$(jira me)
jira sprint list --current --plain -a"$ME" --columns key,summary,status,priority
```

### Pick Up and Start an Issue

```bash
jira issue assign ISSUE-123 "$ME"
jira issue move ISSUE-123 "In Progress"
```

### Complete an Issue

```bash
jira issue worklog add ISSUE-123 "4h" --comment "Implementation complete" --no-input
jira issue move ISSUE-123 "Done" --comment "Merged in PR #456" -RFixed
```

### Create a Bug from a Code Finding

```bash
KEY=$(jira issue create -tBug -s"Memory leak in connection pool" \
  -yHigh -lbug -Cbackend \
  -b"Found during code review. Connection objects are not released when..." \
  --no-input --raw 2>/dev/null | jq -r '.key')
jira issue assign "$KEY" "$ME"
jira issue move "$KEY" "In Progress"
```

### Bulk Status Check for a Team

```bash
jira issue list -q "project = PROJ AND sprint IN openSprints()" \
  --plain --columns key,summary,status,assignee
```

### Batch Create Issues

Create multiple related issues with rate-limit-safe spacing:

```bash
KEYS=()
for SUMMARY in "Set up CI pipeline" "Add unit tests" "Write API docs"; do
  KEY=$(jira issue create -tTask -s"$SUMMARY" -pPROJ \
    --no-input --raw | jq -r '.key')
  KEYS+=("$KEY")
  echo "Created $KEY"
  sleep 1
done

# Optionally add to an epic: jira epic add EPIC-42 "${KEYS[@]}"
# Add all created issues to a sprint (see Discovery Patterns for $SPRINT_ID)
jira sprint add "$SPRINT_ID" "${KEYS[@]}"
```

### Batch Transition Issues

Move multiple issues to a target status. Continues on failure and reports
which issues failed:

```bash
FAILED=()
KEYS=()
while IFS= read -r KEY; do
  KEYS+=("$KEY")
done < <(jira issue list -q "project = PROJ AND status = 'Code Review'" \
  --plain --no-headers | awk -F'\t' '{print $2}')

for KEY in "${KEYS[@]}"; do
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

Query unassigned issues and assign/prioritize them. Uses `$ME` from the
"Start of Day" workflow (`ME=$(jira me)`):

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

## Error Handling

**"Issue does not exist"**: Double-check the issue key. Keys are case-sensitive
and project-prefixed (e.g., PROJ-123, not just 123).

**"No transition found"**: The status name doesn't match available transitions.
Check the current status with:
`jira issue view ISSUE-123 --raw | jq -r '.fields.status.name'`
Then try common status names ("To Do", "In Progress", "In Review", "Done") or
check your Jira board for the workflow.

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
SUCCEEDED=()
FAILED=()
for KEY in "${ALL_KEYS[@]}"; do
  if jira issue move "$KEY" "Done" -RFixed 2>/dev/null; then
    SUCCEEDED+=("$KEY")
  else
    FAILED+=("$KEY")
  fi
  sleep 1
done

echo "Succeeded: ${SUCCEEDED[*]}"
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "Failed: ${FAILED[*]}"
  # Retry only failures
  for KEY in "${FAILED[@]}"; do
    jira issue move "$KEY" "Done" -RFixed
    sleep 1
  done
fi
```

## Full Command Reference

For complete flag documentation on every command — including flags not shown
above (`--fix-version`, `--original-estimate`, `--skip-notify`, `--internal`,
`--delimiter`, `--csv`, and more) — read `references/commands.md` in this
skill's directory.
