# Commit Convention Settings Design

## Problem

The project adopted Conventional Commits and semantic-release but has no documentation or enforcement. Claude Code agents working in this repo have no guidance on commit message format, and there is no validation to catch invalid messages before they reach CI.

## Goals

1. **Documentation** -- a project-level CLAUDE.md so Claude agents write correct Conventional Commits
2. **Enforcement** -- commitlint + husky to validate every commit message locally (Claude and human)

## Decision: CLAUDE.md + commitlint + husky

### Alternatives Considered

- **Custom shell script hook** -- fragile regex, not git-tracked, reinvents commitlint. Rejected.
- **GitHub Action only** -- slow feedback loop, no local enforcement. Rejected.

## CLAUDE.md

A project-level `CLAUDE.md` at the repo root documenting:
- Commit message format: `type(scope): description`
- Valid types: feat, fix, docs, chore, build, ci, refactor, style, test
- Valid scopes: multi-review, jira-cli, repo (unscoped allowed for repo-level)
- Breaking change syntax: `!` suffix or `BREAKING CHANGE:` footer
- Examples of valid commit messages

## commitlint Configuration

`commitlint.config.js` at repo root:
- Extends `@commitlint/config-conventional`
- Custom `scope-enum` rule: `['multi-review', 'jira-cli', 'repo']`
- Scope is not required (unscoped commits map to repo-level)

## husky Configuration

- `.husky/commit-msg` hook runs `npx --no -- commitlint --edit $1`
- Root `package.json` `prepare` script runs `husky` for automatic hook installation on `npm install`

## New devDependencies

- `@commitlint/cli`
- `@commitlint/config-conventional`
- `husky`
