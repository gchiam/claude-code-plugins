# Claude Code Plugins

Personal collection of Claude Code plugins.

## Installation

### From GitHub (recommended)

```bash
# Step 1: Add the marketplace
claude plugin marketplace add gchiam/claude-code-plugins

# Step 2: Install individual plugins
claude plugin install multi-review@gchiam-plugins
claude plugin install jira-cli@gchiam-plugins
claude plugin install pr-desc-review@gchiam-plugins
```

### From local clone

```bash
git clone https://github.com/gchiam/claude-code-plugins.git

# Add as local marketplace
claude plugin marketplace add ./claude-code-plugins
```

## Uninstallation

```bash
# Remove individual plugins
claude plugin remove multi-review
claude plugin remove jira-cli
claude plugin remove pr-desc-review

# Optionally remove the marketplace
claude plugin marketplace remove gchiam-plugins
```

## Available Plugins

### multi-review

Discovers available review commands in your environment, runs them in parallel,
validates findings, and produces an aggregated summary.

**Usage:**

```bash
claude "Run multi-review --pr 123"
```

Or use the command:

```text
/multi-review --pr 123
```

**Features:**

- Auto-discovers available review commands (code-review, pr-review-toolkit, coderabbit, etc.)
- Parallel execution with configurable max reviewers (default 3)
- Validation phase to filter false positives
- Deduplication of findings across reviewers
- Configurable confidence threshold
- No auto-posting to PR

See [multi-review/skills/multi-review/README.md](multi-review/skills/multi-review/README.md)
for full documentation.

### pr-desc-review

Review PR descriptions to ensure they accurately reflect the implementation.
Compares what the description claims against the actual code changes and
reports discrepancies.

**Usage:**

```text
/pr-desc-review
```

Or with a specific PR:

```text
/pr-desc-review --pr 123
```

**Features:**

- Auto-detects PR from current branch (or accepts explicit PR number)
- Parses description claims and cross-references against the diff
- Classifies findings: Missing, Inaccurate, Incomplete, Scope mismatch
- Suggests corrected PR description text
- Multi-review compatible (discovered as `pr-desc-review:desc-reviewer`)
- No auto-updating of PR descriptions

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
├── multi-review/                    # Multi-perspective code review plugin
│   ├── .claude-plugin/plugin.json
│   └── skills/multi-review/
│       ├── SKILL.md
│       └── README.md
├── pr-desc-review/                          # PR description review plugin
│   ├── .claude-plugin/plugin.json
│   ├── skills/pr-desc-review/SKILL.md
│   └── agents/desc-reviewer.md
├── jira-cli/                                # Jira CLI plugin
│   ├── .claude-plugin/plugin.json
│   └── skills/jira-cli/
│       ├── SKILL.md
│       └── references/commands.md
└── README.md
```

## Development

```bash
npm install
```

### Validate all plugins

```bash
npm run validate
```

Runs `claude plugin validate` on every plugin and the marketplace manifest, and checks file structure. Also runs automatically as a pre-commit hook.

### Test a plugin locally

```bash
npm run dev -- multi-review
```

Launches a Claude session with the plugin loaded from your working tree via `--plugin-dir`. Edit files, re-run — no install needed.

### Scaffold a new plugin

```bash
npm run scaffold -- my-new-plugin
```

Creates the directory structure and registers the plugin in `marketplace.json`, `commitlint.config.js`, and `package.json` workspaces.

## License

MIT
