# Version Release Process Design

## Problem

Version management is currently ad-hoc: manual version bumps in `plugin.json`, inconsistent commit messages (sometimes dedicated bump commits, sometimes inlined in feature commits), no git tags, no changelogs, and no GitHub Releases. This makes it hard for users to track changes and for maintainers to follow a consistent release workflow.

## Goals

1. **Consistency** -- standardize how versions get bumped via Conventional Commits
2. **Discoverability** -- GitHub Releases with auto-generated notes, plus git tags
3. **Automation** -- fully automated version bumps, tag creation, and release publishing on push to `main`

## Decision: semantic-release with multi-semantic-release

Use `multi-semantic-release` to run semantic-release independently for each plugin in the monorepo. This provides per-plugin versioning plus a repo-level version, all driven by Conventional Commits.

### Alternatives Considered

- **release-please** -- native monorepo support, creates Release PRs for review. Rejected in favor of semantic-release's fully automatic approach.
- **Custom script + Action** -- full control but high maintenance. Rejected as over-engineering.

## Commit Convention

Conventional Commits with scoped prefixes:

```
feat(multi-review): add support for custom reviewer configs
fix(jira-cli): handle missing API token gracefully
chore(repo): update CI workflow
```

### Scopes

| Scope | Applies to |
|-------|-----------|
| `multi-review` | multi-review plugin |
| `jira-cli` | jira-cli plugin |
| `repo` | Repo-level (CI, README, marketplace) |
| *(unscoped)* | Repo-level version |

### Version Bump Rules

| Commit type | Bump |
|------------|------|
| `fix(scope):` | patch (1.0.0 -> 1.0.1) |
| `feat(scope):` | minor (1.0.0 -> 1.1.0) |
| `feat(scope)!:` or `BREAKING CHANGE:` footer | major (1.0.0 -> 2.0.0) |
| `chore`, `docs`, `refactor`, `style`, `test` | no release |

## Monorepo Structure

Each plugin gets a `package.json` (required by semantic-release) alongside the existing `plugin.json`:

```
claude-code-plugins/
  package.json                          # root: workspaces config + devDependencies
  multi-review/
    package.json                        # { "name": "multi-review", "version": "3.2.0", "private": true }
    .claude-plugin/plugin.json          # existing -- kept in sync
  jira-cli/
    package.json                        # { "name": "jira-cli", "version": "1.0.0", "private": true }
    .claude-plugin/plugin.json          # existing -- kept in sync
```

All packages are `"private": true` to prevent npm publishing. The `plugin.json` version is synced from `package.json` via a `prepare` lifecycle hook.

### Tag Format

- `multi-review-v3.3.0`
- `jira-cli-v1.1.0`
- `claude-code-plugins-v1.1.0`

## GitHub Actions Workflow

`.github/workflows/release.yml` runs on push to `main`:

1. Checks out full history (`fetch-depth: 0`)
2. Sets up Node.js 22
3. Installs dependencies (`npm ci`)
4. Runs `npx multi-semantic-release`

For each package with relevant commits since last tag:
- Determines version bump from commit messages
- Updates `package.json` version
- Runs `prepare` hook to sync `plugin.json`
- Creates git tag
- Creates GitHub Release with auto-generated notes

### Permissions

- `contents: write` -- create tags and releases
- `issues: write` -- comment on referenced issues
- `pull-requests: write` -- comment on referenced PRs

### semantic-release Plugins

| Plugin | Purpose |
|--------|---------|
| `@semantic-release/commit-analyzer` | Determine version bump |
| `@semantic-release/release-notes-generator` | Generate release notes |
| `@semantic-release/exec` | Sync plugin.json version |
| `@semantic-release/git` | Commit version bumps |
| `@semantic-release/github` | Create GitHub Releases |

## Migration Steps

1. Create initial git tags for current versions:
   - `multi-review-v3.2.0`
   - `jira-cli-v1.0.0`
   - `claude-code-plugins-v1.0.0`

2. Add `package.json` to each plugin directory and root

3. Add shared `.releaserc.json` with semantic-release config

4. Add `scripts/sync-plugin-version.sh` to copy version from `package.json` to `plugin.json`

5. Add `.github/workflows/release.yml`

6. Install devDependencies:
   - `multi-semantic-release`
   - `@semantic-release/commit-analyzer`
   - `@semantic-release/release-notes-generator`
   - `@semantic-release/github`
   - `@semantic-release/exec`
   - `@semantic-release/git`

7. Start using Conventional Commits for all future commits

## Invariants

- `plugin.json` remains the source of truth for the Claude Code plugin system
- `package.json` files are purely for semantic-release tooling (`"private": true`)
- No npm packages are published
- Versions are only bumped automatically by CI, never manually
