# Claude Code Plugins

Personal collection of Claude Code plugins.

## Installation

### From GitHub (recommended)

```bash
# Step 1: Add the marketplace
/plugin marketplace add gchiam/claude-code-plugins

# Step 2: Install individual plugins
/plugin install parallel-pr-review@gchiam-plugins
/plugin install jira-cli@gchiam-plugins
```

### From local clone

```bash
git clone https://github.com/gchiam/claude-code-plugins.git

# Add as local marketplace
/plugin marketplace add ./claude-code-plugins
```

## Uninstallation

```bash
# Remove individual plugins
/plugin uninstall parallel-pr-review
/plugin uninstall jira-cli

# Optionally remove the marketplace
/plugin marketplace remove gchiam-plugins
```

## Available Plugins

### parallel-pr-review

Runs two independent code review methodologies in parallel, validates findings,
and produces an aggregated summary.

**Usage:**

```bash
claude "Run parallel-pr-review --pr 123"
```

Or use the command:

```text
/parallel-pr-review --pr 123
```

**Features:**

- Parallel execution of code-review and pr-review-toolkit skills
- Validation phase to filter false positives
- Deduplication of findings across reviewers
- Configurable confidence threshold
- No auto-posting to PR

See [parallel-pr-review/skills/parallel-pr-review/README.md](parallel-pr-review/skills/parallel-pr-review/README.md)
for full documentation.

**Prerequisites:**

```bash
/plugin install code-review@claude-plugins-official
/plugin install pr-review-toolkit@claude-plugins-official
```

### jira-cli

Interact with Jira from the command line using
[jira-cli](https://github.com/ankitpokhrel/jira-cli). Covers issue management,
sprints, epics, boards, and common workflows.

**Usage:**

```text
"Show my open Jira tickets"
"Create a bug for the login crash"
"Move PROJ-123 to Done"
```

**Features:**

- Non-interactive mode by default (safe for agent use)
- Decision guidance for flags vs JQL filtering
- Output parsing for plain text and JSON
- Multi-step workflow patterns
- Error handling and recovery guidance

**Prerequisites:**

- [jira-cli](https://github.com/ankitpokhrel/jira-cli) installed and configured (`jira init`)
- `JIRA_API_TOKEN` environment variable set

## Structure

```text
claude-code-plugins/
├── .claude-plugin/
│   └── marketplace.json                  # Marketplace catalog
├── parallel-pr-review/                   # PR review plugin
│   ├── .claude-plugin/plugin.json
│   ├── commands/parallel-pr-review.md
│   └── skills/parallel-pr-review/
│       ├── SKILL.md
│       └── README.md
├── jira-cli/                             # Jira CLI plugin
│   ├── .claude-plugin/plugin.json
│   └── skills/jira-cli/
│       ├── SKILL.md
│       └── references/commands.md
└── README.md
```

## Development

To test changes locally:

```bash
# Run Claude with a specific plugin directory
claude --plugin-dir ./parallel-pr-review
claude --plugin-dir ./jira-cli
```

## License

MIT
