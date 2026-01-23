# Claude Code Plugins

Personal collection of Claude Code plugins.

## Installation

### From GitHub (recommended)

```bash
# Step 1: Add the marketplace
/plugin marketplace add gchiam/claude-code-plugins

# Step 2: Install the plugin
/plugin install claude-code-plugins@gchiam/claude-code-plugins
```

### From local clone

```bash
git clone https://github.com/gchiam/claude-code-plugins.git

# Add as local marketplace
/plugin marketplace add ./claude-code-plugins
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

See [skills/parallel-pr-review/README.md](skills/parallel-pr-review/README.md)
for full documentation.

## Prerequisites

Some skills require other plugins to be installed:

```bash
/plugin install code-review@claude-plugins-official
/plugin install pr-review-toolkit@claude-plugins-official
```

## Structure

```text
claude-code-plugins/
├── .claude-plugin/
│   ├── plugin.json            # Plugin manifest
│   └── marketplace.json       # Marketplace definition
├── commands/
│   └── parallel-pr-review.md  # /parallel-pr-review command
├── skills/
│   └── parallel-pr-review/
│       ├── SKILL.md           # Skill instructions (for Claude)
│       └── README.md          # Documentation (for humans)
└── README.md                  # This file
```

## Development

To test changes locally:

```bash
# Run Claude with the plugin (from repo root)
claude --plugin-dir .
```

## License

MIT
