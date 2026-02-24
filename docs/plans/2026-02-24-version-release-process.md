# Version Release Process Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Automate version bumps, git tags, and GitHub Releases for each plugin independently using semantic-release with Conventional Commits.

**Architecture:** `multi-semantic-release` runs in a GitHub Actions workflow on push to `main`. It analyzes Conventional Commits per-package (npm workspaces), bumps versions in `package.json`, syncs to `plugin.json` via an exec hook, creates scoped git tags, and publishes GitHub Releases.

**Tech Stack:** multi-semantic-release, semantic-release plugins, GitHub Actions, Node.js 22, bash

---

### Task 1: Create baseline git tags

Tag the current versions so semantic-release knows where to start analyzing commits.

**Files:** None (git operations only)

**Step 1: Create tags for current plugin versions**

```bash
git tag multi-review-v3.2.0
git tag jira-cli-v1.0.0
git tag claude-code-plugins-v1.0.0
```

**Step 2: Verify tags exist**

Run: `git tag --list`

Expected output includes:
```
claude-code-plugins-v1.0.0
jira-cli-v1.0.0
multi-review-v3.2.0
```

**Step 3: Push tags to remote**

```bash
git push origin --tags
```

---

### Task 2: Add root package.json

Create the root `package.json` that defines npm workspaces and devDependencies for semantic-release.

**Files:**
- Create: `package.json`

**Step 1: Create root package.json**

Create `package.json` at the repo root:

```json
{
  "name": "claude-code-plugins",
  "version": "1.0.0",
  "private": true,
  "description": "Personal collection of Claude Code plugins",
  "workspaces": [
    "multi-review",
    "jira-cli"
  ],
  "devDependencies": {
    "multi-semantic-release": "^3.0.0",
    "@semantic-release/commit-analyzer": "^13.0.0",
    "@semantic-release/release-notes-generator": "^14.0.0",
    "@semantic-release/github": "^11.0.0",
    "@semantic-release/exec": "^7.0.0",
    "@semantic-release/git": "^10.0.0"
  }
}
```

**Step 2: Commit**

```bash
git add package.json
git commit -m "build(repo): add root package.json with semantic-release devDependencies"
```

> Note: Do NOT run `npm install` yet. We will install after all package.json files are in place (Task 4).

---

### Task 3: Add plugin-level package.json files

Each plugin needs a `package.json` for semantic-release to discover it as a workspace package.

**Files:**
- Create: `multi-review/package.json`
- Create: `jira-cli/package.json`

**Step 1: Create multi-review/package.json**

```json
{
  "name": "multi-review",
  "version": "3.2.0",
  "private": true,
  "description": "Multi-perspective code review with validation and aggregation"
}
```

**Step 2: Create jira-cli/package.json**

```json
{
  "name": "jira-cli",
  "version": "1.0.0",
  "private": true,
  "description": "Interact with Jira from the command line using jira-cli"
}
```

**Step 3: Commit**

```bash
git add multi-review/package.json jira-cli/package.json
git commit -m "build(repo): add package.json to each plugin for semantic-release"
```

---

### Task 4: Install dependencies

**Files:** Generated: `package-lock.json`

**Step 1: Install npm dependencies**

Run: `npm install`

Expected: Creates `package-lock.json` and populates `node_modules/`. No errors.

**Step 2: Verify workspaces**

Run: `npm ls --depth=0`

Expected: Shows `multi-review` and `jira-cli` as workspace packages.

**Step 3: Commit lockfile**

```bash
git add package-lock.json
git commit -m "build(repo): add package-lock.json"
```

---

### Task 5: Add plugin.json sync script

Create a script that copies the version from `package.json` into `plugin.json` for a given package directory. This runs during the semantic-release `prepare` lifecycle.

**Files:**
- Create: `scripts/sync-plugin-version.sh`

**Step 1: Create the sync script**

Create `scripts/sync-plugin-version.sh`:

```bash
#!/usr/bin/env bash
#
# Syncs the "version" field from package.json into .claude-plugin/plugin.json
# for the current working directory.
#
# Usage: Called by semantic-release @semantic-release/exec in the prepare step.
#        Runs with cwd set to the package directory by multi-semantic-release.

set -euo pipefail

PACKAGE_JSON="package.json"
PLUGIN_JSON=".claude-plugin/plugin.json"

if [ ! -f "$PLUGIN_JSON" ]; then
  echo "No $PLUGIN_JSON found in $(pwd), skipping sync"
  exit 0
fi

VERSION=$(node -p "require('./$PACKAGE_JSON').version")

# Use node to update the version in plugin.json (preserves formatting)
node -e "
const fs = require('fs');
const path = './$PLUGIN_JSON';
const plugin = JSON.parse(fs.readFileSync(path, 'utf8'));
plugin.version = '$VERSION';
fs.writeFileSync(path, JSON.stringify(plugin, null, 2) + '\n');
"

echo "Synced $PLUGIN_JSON version to $VERSION"
```

**Step 2: Make it executable**

```bash
chmod +x scripts/sync-plugin-version.sh
```

**Step 3: Test the script manually**

Run from the multi-review directory:

```bash
cd multi-review && bash ../scripts/sync-plugin-version.sh && cd ..
```

Expected output: `Synced .claude-plugin/plugin.json version to 3.2.0`

Verify no changes (version should already match):

```bash
git diff multi-review/.claude-plugin/plugin.json
```

Expected: No diff (versions already in sync).

**Step 4: Commit**

```bash
git add scripts/sync-plugin-version.sh
git commit -m "build(repo): add script to sync plugin.json version from package.json"
```

---

### Task 6: Add semantic-release configuration

Create `.releaserc.json` at the repo root. `multi-semantic-release` applies this config to each workspace package.

**Files:**
- Create: `.releaserc.json`

**Step 1: Create .releaserc.json**

```json
{
  "branches": ["main"],
  "tagFormat": "${name}-v${version}",
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    ["@semantic-release/exec", {
      "prepareCmd": "bash ${process.cwd()}/scripts/sync-plugin-version.sh"
    }],
    ["@semantic-release/git", {
      "assets": [
        "package.json",
        ".claude-plugin/plugin.json"
      ],
      "message": "chore(release): ${nextRelease.name} [skip ci]"
    }],
    "@semantic-release/github"
  ]
}
```

**Important notes on this config:**
- `tagFormat`: Uses `${name}-v${version}` which produces tags like `multi-review-v3.3.0`. The `${name}` variable is populated from each package's `package.json` name field by `multi-semantic-release`.
- `@semantic-release/exec` `prepareCmd`: The `${process.cwd()}` resolves to the repo root at runtime, ensuring the script path is absolute regardless of which package is being processed. The script itself reads from the package's own cwd (set by multi-semantic-release).
- `@semantic-release/git` `assets`: Lists files to commit back after version bump. These are relative to each package directory.
- `[skip ci]` in commit message: Prevents the release commit from triggering another release cycle.
- Plugin order matters: `commit-analyzer` -> `release-notes-generator` -> `exec` (sync plugin.json) -> `git` (commit changes) -> `github` (create release).

**Step 2: Commit**

```bash
git add .releaserc.json
git commit -m "build(repo): add semantic-release configuration"
```

---

### Task 7: Add GitHub Actions workflow

**Files:**
- Create: `.github/workflows/release.yml`

**Step 1: Create the workflow file**

```yaml
name: Release

on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      issues: write
      pull-requests: write
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          persist-credentials: true

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22

      - name: Install dependencies
        run: npm ci

      - name: Release
        run: npx multi-semantic-release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Notes on this workflow:**
- `fetch-depth: 0`: Clones full git history so semantic-release can analyze all commits since last tag.
- `persist-credentials: true`: Allows the git plugin to push release commits and tags back to the repo.
- `GITHUB_TOKEN`: The built-in GitHub Actions token. Has sufficient permissions for creating releases and tags when `contents: write` is set.

**Step 2: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "ci(repo): add GitHub Actions release workflow"
```

---

### Task 8: Update .gitignore

The `.gitignore` already has `node_modules/` but should also include `package-lock.json`-related patterns for robustness.

**Files:**
- Modify: `.gitignore`

**Step 1: Verify .gitignore is sufficient**

Check that `.gitignore` already contains:
- `node_modules/`

If it does (it does currently), no changes needed. `package-lock.json` should be committed (it is a lockfile, not a generated artifact to ignore).

**Step 2: Skip this task -- no changes needed**

The existing `.gitignore` is already correct. `node_modules/` is ignored and `package-lock.json` will be tracked.

---

### Task 9: Validate the full setup locally

Run a dry-run to verify the configuration is correct before pushing.

**Files:** None

**Step 1: Verify npm workspaces**

Run: `npm ls --depth=0 --workspaces`

Expected: Lists `multi-review` and `jira-cli` as workspaces.

**Step 2: Verify semantic-release config is valid**

Run from the repo root:

```bash
npx multi-semantic-release --dry-run
```

Expected: Runs without errors. Should report "no new commits" or similar for each package (since current versions already have tags).

**Step 3: Verify tag format**

Run: `git tag --list`

Expected: Shows `multi-review-v3.2.0`, `jira-cli-v1.0.0`, `claude-code-plugins-v1.0.0`.

---

### Task 10: Push everything and verify

**Files:** None

**Step 1: Push all commits and tags**

```bash
git push origin main --follow-tags
```

**Step 2: Verify GitHub Actions workflow runs**

Check the Actions tab at `https://github.com/gchiam/claude-code-plugins/actions`. The release workflow should trigger and complete successfully with "no new releases" (since no new Conventional Commits exist yet).

**Step 3: Test with a real commit**

Create a test commit using Conventional Commits format:

```bash
# Make a small documentation change to multi-review
echo "" >> multi-review/skills/multi-review/README.md
git add multi-review/skills/multi-review/README.md
git commit -m "docs(multi-review): test conventional commit format"
git push
```

Expected: The `docs` type does not trigger a release. Verify in Actions that the workflow runs but creates no release.

Then revert:

```bash
git revert HEAD --no-edit
git push
```
