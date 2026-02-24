# Local Dev Workflow Design

## Problem

Developing and testing Claude Code plugins locally is high-friction. The current workflow requires either manually starting Claude sessions and hoping the plugin behaves, or pushing commits and reinstalling from the marketplace. There is no structural validation, no fast feedback loop, and no scaffolding for new plugins.

## Goals

1. **Fast edit-test cycle** -- test local plugin changes immediately without installing or pushing
2. **Confidence before push** -- validate plugin structure and config before committing
3. **Easy new plugin setup** -- scaffold a new plugin with one command

## Decision: npm Scripts Wrapping Claude CLI

Three npm scripts backed by bash scripts in `scripts/`, leveraging existing Claude CLI features (`claude plugin validate`, `--plugin-dir`).

### Alternatives Considered

- **Node.js CLI tool** -- richer validation (watch mode, content checks), but over-engineered for a 2-plugin repo. Rejected.
- **Makefile** -- simpler than npm scripts, but less idiomatic for a Node.js project with existing package.json tooling. Rejected.

## Script 1: `npm run validate`

Runs `claude plugin validate` on all plugins and the marketplace manifest, then checks file structure.

Implementation: `scripts/validate.sh`

1. Run `claude plugin validate .` on the marketplace root
2. Run `claude plugin validate <dir>` on each plugin directory listed in `marketplace.json`
3. Check each plugin has the expected files: `.claude-plugin/plugin.json`, `skills/<name>/SKILL.md`, `package.json`
4. Exit non-zero on any failure

Pre-commit integration: `.husky/pre-commit` hook runs `npm run validate` before every commit.

## Script 2: `npm run dev -- <plugin>`

Launches a Claude session with a local plugin loaded directly from the working tree.

Implementation: `scripts/dev.sh`

1. Accept a plugin name argument
2. Validate the plugin directory exists
3. Run validation on that plugin (fail-fast if broken)
4. Launch `claude --plugin-dir ./<plugin-name>` for an interactive session

## Script 3: `npm run scaffold -- <name>`

Creates a new plugin with the correct directory structure and registers it in all config files.

Implementation: `scripts/scaffold.sh`

1. Accept a plugin name argument
2. Validate the name (lowercase, alphanumeric + hyphens, not already taken)
3. Create directory structure:
   - `<name>/.claude-plugin/plugin.json` (template with name, version 1.0.0, author)
   - `<name>/package.json` (private, version 1.0.0)
   - `<name>/skills/<name>/SKILL.md` (template with TODO placeholders)
4. Add plugin entry to `.claude-plugin/marketplace.json`
5. Add scope to `commitlint.config.js`
6. Print next-steps instructions

## Changes Summary

### New Files

- `scripts/validate.sh`
- `scripts/dev.sh`
- `scripts/scaffold.sh`
- `.husky/pre-commit`

### Modified Files

- `package.json` -- add `validate`, `dev`, `scaffold` scripts
- `CLAUDE.md` -- document dev workflow commands
