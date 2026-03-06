# Claude Code Plugins

Personal collection of Claude Code plugins.

## Installation

```bash
# Add the marketplace
claude plugin marketplace add gchiam/claude-code-plugins

# Install a plugin
claude plugin install <name>@gchiam-plugins

# Remove a plugin
claude plugin remove <name>

# Remove the marketplace
claude plugin marketplace remove gchiam-plugins
```

Or clone locally:

```bash
git clone https://github.com/gchiam/claude-code-plugins.git
claude plugin marketplace add ./claude-code-plugins
```

## Available Plugins

| Plugin | Description | Invocation |
|---|---|---|
| [multi-review](multi-review/skills/multi-review/README.md) | Use when reviewing a large or high-risk PR and want multiple specialized perspectives | `/multi-review --pr 123` |
| [pr-desc-review](pr-desc-review/skills/pr-desc-review/SKILL.md) | Checks that a PR description accurately reflects the implementation | `/pr-desc-review` |
| [jira-cli](jira-cli/skills/jira-cli/SKILL.md) | Interact with Jira — issues, sprints, epics, transitions | `"Show my open Jira tickets"` |
| [claude-cleanup](claude-cleanup/skills/claude-cleanup/SKILL.md) | Remove stale project entries from `~/.claude.json` | `"Clean up claude.json"` |
| [git-absorb](git-absorb/skills/git-absorb/SKILL.md) | Create fixup commits targeting the right parent using `git absorb` | `/git-absorb` |
| [skill-cso-review](skill-cso-review/skills/skill-cso-review/SKILL.md) | Audit `SKILL.md` files for CSO compliance (description quality, structure) | `/skill-cso-review:review-skills` |

## Structure

Each plugin lives in its own directory and follows the standard Claude Code plugin layout:

```text
<plugin-name>/
├── .claude-plugin/plugin.json   # Manifest
├── skills/<plugin-name>/        # Skill (auto-activates on context match)
│   └── SKILL.md
├── agents/                      # Subagents (optional)
├── commands/                    # Slash commands (optional)
└── hooks/hooks.json             # Event hooks (optional)
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
