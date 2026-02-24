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
