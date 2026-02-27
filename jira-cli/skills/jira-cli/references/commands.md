# Jira CLI: Full Command Reference

Complete flag and argument reference for every jira-cli command. Consult this
when the main SKILL.md doesn't cover a specific flag or edge case.

## Table of Contents

- [Issue Commands](#issue-commands)
  - [issue list](#issue-list)
  - [issue create](#issue-create)
  - [issue view](#issue-view)
  - [issue edit](#issue-edit)
  - [issue move](#issue-move)
  - [issue assign](#issue-assign)
  - [issue comment add](#issue-comment-add)
  - [issue worklog add](#issue-worklog-add)
  - [issue link](#issue-link)
  - [issue link remote](#issue-link-remote)
  - [issue unlink](#issue-unlink)
  - [issue clone](#issue-clone)
  - [issue delete](#issue-delete)
  - [issue watch](#issue-watch)
- [Epic Commands](#epic-commands)
  - [epic list](#epic-list)
  - [epic create](#epic-create)
  - [epic add](#epic-add)
  - [epic remove](#epic-remove)
- [Sprint Commands](#sprint-commands)
  - [sprint list](#sprint-list)
  - [sprint add](#sprint-add)
  - [sprint close](#sprint-close)
- [Other Commands](#other-commands)
  - [project list](#project-list)
  - [board list](#board-list)
  - [release list](#release-list)
  - [open](#open)
  - [me](#me)
  - [serverinfo](#serverinfo)
- [Global Flags](#global-flags)

---

## Issue Commands

### issue list

List and search issues. Aliases: `lists`, `ls`, `search`

```
jira issue list [optional text query] [flags]
```

**Filtering flags:**

| Flag | Type | Description |
|------|------|-------------|
| `-t, --type` | string | Filter by issue type (Bug, Story, Task, Epic) |
| `-s, --status` | stringArray | Filter by status (repeatable) |
| `-y, --priority` | string | Filter by priority (Highest, High, Medium, Low, Lowest) |
| `-a, --assignee` | string | Filter by assignee (email or display name). Use `x` for unassigned |
| `-r, --reporter` | string | Filter by reporter |
| `-C, --component` | string | Filter by component |
| `-l, --label` | stringArray | Filter by label (repeatable) |
| `-P, --parent` | string | Filter by parent issue key |
| `-R, --resolution` | string | Filter by resolution type |
| `-w, --watching` | bool | Issues you are watching |
| `--history` | bool | Issues you accessed recently |
| `-q, --jql` | string | Raw JQL query in project context |

**Date filters:**

| Flag | Description |
|------|-------------|
| `--created` | today, week, month, year, yyyy-mm-dd, or period (-10d, -2w) |
| `--updated` | Same format as --created |
| `--created-after` | Date string |
| `--created-before` | Date string |
| `--updated-after` | Date string |
| `--updated-before` | Date string |

**Output flags:**

| Flag | Description |
|------|-------------|
| `--plain` | Plain text table output |
| `--no-headers` | Hide table headers (requires --plain) |
| `--no-truncate` | Show all fields (requires --plain) |
| `--columns` | Comma-separated: TYPE, KEY, SUMMARY, STATUS, ASSIGNEE, REPORTER, PRIORITY, RESOLUTION, CREATED, UPDATED, LABELS |
| `--delimiter` | Custom column delimiter (default: tab) |
| `--raw` | JSON output |
| `--csv` | CSV output |
| `--comments` | Show N comments (default: 1) |

**Pagination and sorting:**

| Flag | Description |
|------|-------------|
| `--paginate` | Format: `<from>:<limit>`, max 100. Default: `0:100` |
| `--order-by` | Sort field (default: created) |
| `--reverse` | Reverse sort order |

**Negation:** Prefix status with `~` to exclude: `-s~Open` means "not Open".

### issue create

Create a new issue.

```
jira issue create [flags]
```

| Flag | Type | Description |
|------|------|-------------|
| `-t, --type` | string | Issue type (Bug, Story, Task, Sub-task) |
| `-s, --summary` | string | Title |
| `-b, --body` | string | Description |
| `-y, --priority` | string | Priority |
| `-a, --assignee` | string | Assignee |
| `-r, --reporter` | string | Reporter |
| `-l, --label` | stringArray | Labels (repeatable) |
| `-C, --component` | stringArray | Components (repeatable) |
| `-P, --parent` | string | Parent issue/epic key |
| `-e, --original-estimate` | string | Original estimate |
| `--fix-version` | stringArray | Fix versions |
| `--affects-version` | stringArray | Affects versions |
| `--custom` | key=value | Custom fields (e.g., `story-points=3`) |
| `-T, --template` | string | File path for body (use `-` for stdin) |
| `--web` | bool | Open in browser after creation |
| `--no-input` | bool | Skip interactive prompts |
| `--raw` | bool | JSON output (includes created issue key) |

### issue view

View issue details. Aliases: `show`

```
jira issue view ISSUE-KEY [flags]
```

| Flag | Description |
|------|-------------|
| `--plain` | Plain text output |
| `--raw` | Full JSON API response |
| `--comments` | Number of comments to show (default: 1) |

### issue edit

Edit an existing issue. Aliases: `update`, `modify`

```
jira issue edit ISSUE-KEY [flags]
```

| Flag | Type | Description |
|------|------|-------------|
| `-s, --summary` | string | New summary |
| `-b, --body` | string | New description |
| `-y, --priority` | string | New priority |
| `-a, --assignee` | string | New assignee |
| `-l, --label` | stringArray | Append labels. Prefix with `-` to remove (e.g., `--label -old`) |
| `-C, --component` | stringArray | Replace components. Prefix with `-` to remove |
| `-P, --parent` | string | Link to parent key |
| `--fix-version` | stringArray | Add fix versions. Prefix with `-` to remove |
| `--affects-version` | stringArray | Add affects versions |
| `--custom` | key=value | Edit custom fields |
| `--skip-notify` | bool | Don't notify watchers |
| `--no-input` | bool | Skip interactive prompts |

Supports piping description from stdin.

### issue move

Transition to a new status. Aliases: `transition`, `mv`

```
jira issue move ISSUE-KEY STATE [flags]
```

| Flag | Description |
|------|-------------|
| `--comment` | Add comment during transition |
| `-a, --assignee` | Change assignee during transition |
| `-R, --resolution` | Set resolution (e.g., Fixed, Won't Fix, Duplicate) |

STATE must match an available transition name exactly.

### issue assign

```
jira issue assign ISSUE-KEY ASSIGNEE
```

ASSIGNEE is an email or display name. Use `x` to unassign.

### issue comment add

```
jira issue comment add ISSUE-KEY [COMMENT_BODY] [flags]
```

| Flag | Description |
|------|-------------|
| `--internal` | Make comment internal (Service Desk) |
| `--no-input` | Skip interactive prompt |
| `-T, --template` | File path for body (use `-` for stdin) |

Positional COMMENT_BODY takes precedence over --template.

### issue worklog add

```
jira issue worklog add ISSUE-KEY TIME_SPENT [flags]
```

TIME_SPENT format: `2d 1h 30m` (days, hours, minutes separated by space).

| Flag | Description |
|------|-------------|
| `--started` | Start datetime (e.g., `2024-01-01 09:30:00`) |
| `--timezone` | IANA timezone (default: UTC) |
| `--comment` | Worklog comment |
| `--new-estimate` | New remaining estimate |
| `--no-input` | Skip interactive prompt |

### issue link

```
jira issue link INWARD_KEY OUTWARD_KEY LINK_TYPE
```

Common link types: `Blocks`, `Composition`, `Duplicates`, `Relates`, `Cloners`.

Discover available link types on your instance:

```bash
jira issue view ANY-ISSUE --raw | jq -r '[.fields.issuelinks[].type] | unique_by(.name) | .[].name'
```

#### issue link remote

```
jira issue link remote ISSUE-KEY URL TITLE
```

### issue unlink

```
jira issue unlink ISSUE-KEY OTHER_KEY
```

### issue clone

```
jira issue clone ISSUE-KEY [flags]
```

| Flag | Description |
|------|-------------|
| `-s, --summary` | Override summary |
| `-y, --priority` | Override priority |
| `-a, --assignee` | Override assignee |
| `-l, --label` | Override labels |
| `-C, --component` | Override components |
| `-P, --parent` | Set parent |
| `-H, --replace` | String replacement in summary/body: `"find:replace"` |

### issue delete

```
jira issue delete ISSUE-KEY
```

### issue watch

```
jira issue watch ISSUE-KEY WATCHER
```

WATCHER is an email or display name (exact match required).

---

## Epic Commands

### epic list

List epics, or list issues within an epic. Aliases: `lists`, `ls`

```
jira epic list [EPIC-KEY] [flags]
```

Without EPIC-KEY: lists all epics. With EPIC-KEY: lists issues in that epic.

Supports the same filtering, date, output, and pagination flags as `issue list`.

Additional flag:

| Flag | Description |
|------|-------------|
| `--table` | Table view for epic list (without EPIC-KEY) |

### epic create

```
jira epic create [flags]
```

| Flag | Description |
|------|-------------|
| `-n, --name` | Epic name |
| `-s, --summary` | Epic summary |
| `-b, --body` | Description |
| `-y, --priority` | Priority |
| `-a, --assignee` | Assignee |
| `-l, --label` | Labels (repeatable) |
| `-C, --component` | Components (repeatable) |
| `--custom` | Custom fields |
| `--no-input` | Skip prompts |

### epic add

```
jira epic add EPIC-KEY ISSUE-KEY [ISSUE-KEY...]
```

### epic remove

```
jira epic remove ISSUE-KEY [ISSUE-KEY...]
```

---

## Sprint Commands

### sprint list

List sprints, or list issues in a sprint. Aliases: `lists`, `ls`

```
jira sprint list [SPRINT_ID] [flags]
```

Without SPRINT_ID: lists sprints. With SPRINT_ID: lists issues in that sprint.

**Sprint selection shortcuts:**

| Flag | Description |
|------|-------------|
| `--current` | Active sprint issues |
| `--prev` | Previous sprint issues |
| `--next` | Next planned sprint issues |

**Sprint filtering:**

| Flag | Description |
|------|-------------|
| `--state` | Filter by state: `future`, `active`, `closed` (comma-separated) |
| `--show-all-issues` | Include issues from other projects |

**Output flags:** Same as issue list (`--plain`, `--columns`, `--raw`, etc.)

Sprint list columns: ID, NAME, START, END, COMPLETE, STATE
Sprint issue columns: TYPE, KEY, SUMMARY, STATUS, ASSIGNEE, REPORTER, PRIORITY, RESOLUTION, CREATED, UPDATED, LABELS

### sprint add

```
jira sprint add SPRINT_ID ISSUE-KEY [ISSUE-KEY...]
```

### sprint close

```
jira sprint close SPRINT_ID
```

---

## Other Commands

### project list

```
jira project list [flags]
```

Supports `--plain` output.

### board list

```
jira board list [flags]
```

Supports `--plain` output.

### release list

```
jira release list [flags]
```

Supports `--plain` output.

### open

```
jira open [ISSUE-KEY]
```

Opens issue or project in the default browser.

### me

```
jira me
```

Prints the configured Jira user's email/username.

### serverinfo

```
jira serverinfo
```

Displays Jira instance version, build, deployment type, and locale.

---

## Global Flags

These work with all commands:

| Flag | Description |
|------|-------------|
| `-c, --config` | Config file path (default: `~/.config/.jira/.config.yml`) |
| `--debug` | Enable debug output |
| `-p, --project` | Override default project |
| `-h, --help` | Help for any command |
