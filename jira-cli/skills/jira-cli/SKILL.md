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

When using `--plain`, the output is tab-delimited with these default columns:
`TYPE`, `KEY`, `SUMMARY`, `STATUS`, `ASSIGNEE`

Control columns explicitly when you need specific fields:
```bash
jira issue list --plain --columns key,summary,status,priority,assignee
```

Use `--no-headers` when piping or parsing output programmatically.

Use `--raw` to get full JSON when you need fields not available in plain mode
(like description, comments, custom fields).

## Issue Operations

### Listing and Searching

```bash
# My open issues
jira issue list -a"USER_EMAIL" --plain

# Filter by status and type
jira issue list -s"In Progress" -tBug --plain

# Created this week, high priority
jira issue list --created week -yHigh --plain

# Search by text in summary/description
jira issue list "login crash" --plain

# Paginate large results (start:limit, max 100)
jira issue list -a"USER_EMAIL" --paginate 0:50 --plain

# Specific project
jira issue list -pPROJ -s"To Do" --plain
```

### Viewing

```bash
# View issue details
jira issue view ISSUE-123 --plain

# View with recent comments
jira issue view ISSUE-123 --plain --comments 5

# Get full JSON for detailed inspection
jira issue view ISSUE-123 --raw
```

### Creating

Provide at minimum: type (`-t`), summary (`-s`). Add `--no-input` to skip
the interactive editor.

```bash
# Create a bug
jira issue create -tBug -s"Login fails on mobile" -yHigh -b"Steps to reproduce..." --no-input

# Create a story under an epic
jira issue create -tStory -s"Add password reset flow" -PEPIC-42 --no-input

# Create and assign to self
jira issue create -tTask -s"Update dependencies" -a"USER_EMAIL" --no-input

# Create with labels and components
jira issue create -tBug -s"Memory leak in worker" -lbug -l"p0" -Cbackend --no-input

# Create with custom fields (e.g., story points)
jira issue create -tStory -s"User profile page" --custom story-points=5 --no-input

# Get the created issue key as JSON
jira issue create -tTask -s"New task" --no-input --raw
```

### Editing

```bash
# Update summary
jira issue edit ISSUE-123 -s"Updated title" --no-input

# Update description (use pipe for multi-line)
echo "New detailed description" | jira issue edit ISSUE-123 --no-input

# Change priority and add labels
jira issue edit ISSUE-123 -yHigh -lurgent --no-input

# Remove a label (prefix with -)
jira issue edit ISSUE-123 --label -old-label --no-input

# Set custom fields
jira issue edit ISSUE-123 --custom story-points=8 --no-input
```

### Transitioning (Moving)

The status name must match exactly what Jira expects (case-sensitive). Common
statuses: "To Do", "In Progress", "In Review", "Done". Your Jira instance may
use different names.

```bash
# Move to In Progress
jira issue move ISSUE-123 "In Progress"

# Complete with comment and resolution
jira issue move ISSUE-123 "Done" --comment "Completed" -RFixed
```

If the move fails, the status name might not match. Use `jira issue view
ISSUE-123 --raw` and look at the `transitions` field to see valid target
states.

### Assigning

```bash
# Assign to self
jira issue assign ISSUE-123 USER_EMAIL

# Assign to someone else
jira issue assign ISSUE-123 other.person@example.com

# Unassign
jira issue assign ISSUE-123 x
```

### Comments

```bash
# Add a comment
jira issue comment add ISSUE-123 "Investigation complete, root cause is X" --no-input

# Multi-line comment
jira issue comment add ISSUE-123 $'First line\n\nSecond paragraph' --no-input

# Pipe longer content
echo "Detailed analysis..." | jira issue comment add ISSUE-123 --template - --no-input
```

### Work Logging

```bash
# Log time
jira issue worklog add ISSUE-123 "2h 30m" --no-input

# Log with comment
jira issue worklog add ISSUE-123 "4h" --comment "Implemented the feature" --no-input

# Log with specific start time
jira issue worklog add ISSUE-123 "3h" --started "2024-06-15 09:00:00" --no-input
```

### Linking and Cloning

```bash
# Link issues (type: Blocks, Duplicates, Relates, etc.)
jira issue link ISSUE-123 ISSUE-456 Blocks

# Clone an issue with modifications
jira issue clone ISSUE-123 -s"Cloned: New summary" -a"USER_EMAIL"

# Add remote web link
jira issue link remote ISSUE-123 "https://example.com" "Link title"

# Unlink
jira issue unlink ISSUE-123 ISSUE-456
```

## Epics

```bash
# List epics
jira epic list --table --plain

# List issues in an epic
jira epic list EPIC-42 --plain

# Create an epic
jira epic create -n"Q1 Auth Improvements" -s"Epic summary" -b"Description" --no-input

# Add issues to an epic
jira epic add EPIC-42 ISSUE-123 ISSUE-456

# Remove issues from an epic
jira epic remove ISSUE-123
```

## Sprints

```bash
# List sprints (active and closed)
jira sprint list --table --plain

# List only active sprints
jira sprint list --state active --table --plain

# My issues in current sprint
jira sprint list --current --plain -a"USER_EMAIL"

# Previous sprint issues
jira sprint list --prev --plain

# Add issues to a sprint (need sprint ID from sprint list)
jira sprint add SPRINT_ID ISSUE-123 ISSUE-456
```

## Projects and Boards

```bash
# List all projects
jira project list --plain

# List boards
jira board list --plain

# List releases
jira release list --plain

# Open project in browser
jira open
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
  --no-input --raw 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['key'])")
jira issue assign "$KEY" "$ME"
jira issue move "$KEY" "In Progress"
```

### Bulk Status Check for a Team

```bash
jira issue list -q "project = PROJ AND sprint IN openSprints()" \
  --plain --columns key,summary,status,assignee
```

## Error Handling

**"Issue does not exist"**: Double-check the issue key. Keys are case-sensitive
and project-prefixed (e.g., PROJ-123, not just 123).

**"No transition found"**: The status name doesn't match available transitions.
View the issue with `--raw` and check the `transitions` array for valid names.

**Command hangs**: You likely forgot `--no-input` on a create/edit command, or
`--plain` on a list command. Kill the process and retry with the correct flags.

**"401 Unauthorized"**: The JIRA_API_TOKEN is missing or expired. Check with
`echo $JIRA_API_TOKEN` and verify it's set.

**Rate limiting**: Jira Cloud has API rate limits. If you get 429 errors, wait
before retrying. Avoid running many commands in rapid succession.

## Full Command Reference

For complete flag documentation on every command, read
`references/commands.md` in this skill's directory. Use it when you need
uncommon flags or want to verify exact syntax for edge cases.
