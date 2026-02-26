# CLAUDE.md

## Commit Convention

This project uses Conventional Commits enforced by commitlint.

Format: `type(scope): description`

### Types
- `feat` -- new feature (minor version bump)
- `fix` -- bug fix (patch version bump)
- `docs` -- documentation only
- `chore` -- maintenance, dependencies
- `build` -- build system or tooling
- `ci` -- CI/CD changes
- `refactor` -- code change that neither fixes nor adds
- `style` -- formatting, whitespace
- `test` -- adding or updating tests

### Scopes
- `multi-review` -- multi-review plugin
- `jira-cli` -- jira-cli plugin
- `pr-desc-review` -- PR description review plugin
- `repo` -- repo-level (CI, README, marketplace config)

Unscoped commits are allowed and map to the repo-level version.

### Breaking Changes
Add `!` after scope or include `BREAKING CHANGE:` footer:
`feat(multi-review)!: redesign output format`

### Examples
```
feat(multi-review): add custom reviewer configs
fix(jira-cli): handle missing API token
docs(repo): update installation instructions
build(repo): add commitlint configuration
```

## Dev Workflow

### Validate all plugins
```
npm run validate
```

### Test a plugin locally
```
npm run dev -- <plugin-name>
```
Launches a Claude session with the plugin loaded from your working tree. Edit files, re-run — no install needed.

### Scaffold a new plugin
```
npm run scaffold -- <plugin-name>
```
Creates the directory structure and registers the plugin in marketplace.json, commitlint.config.js, and package.json workspaces.
