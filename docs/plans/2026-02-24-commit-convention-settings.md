# Commit Convention Settings Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Document the Conventional Commits convention in CLAUDE.md and enforce it locally with commitlint + husky.

**Architecture:** A project-level CLAUDE.md gives Claude Code agents proactive guidance on commit format. commitlint validates every commit message against the Conventional Commits spec with restricted scopes. husky installs a commit-msg git hook that runs commitlint automatically.

**Tech Stack:** commitlint, @commitlint/config-conventional, husky v9

---

### Task 1: Create project-level CLAUDE.md

**Files:**
- Create: `CLAUDE.md`

**Step 1: Create CLAUDE.md at repo root**

```markdown
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
```

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(repo): add CLAUDE.md with Conventional Commits convention"
```

---

### Task 2: Install commitlint and husky

**Files:**
- Modify: `package.json` (devDependencies and prepare script)
- Generated: `package-lock.json` (updated)

**Step 1: Install commitlint packages**

```bash
npm install --save-dev @commitlint/cli @commitlint/config-conventional
```

Expected: Packages install successfully, `package.json` devDependencies updated.

**Step 2: Install husky**

```bash
npm install --save-dev husky
```

Expected: Package installs successfully.

**Step 3: Add prepare script to package.json**

The root `package.json` needs a `prepare` script so husky hooks auto-install on `npm install`. Add this to `package.json`:

```json
"scripts": {
  "prepare": "husky"
}
```

Place the `"scripts"` block after `"private": true` and before `"description"`.

**Step 4: Commit**

```bash
git add package.json package-lock.json
git commit -m "build(repo): install commitlint and husky"
```

---

### Task 3: Initialize husky and create commit-msg hook

**Files:**
- Create: `.husky/commit-msg`

**Step 1: Initialize husky**

```bash
npx husky init
```

Expected: Creates `.husky/` directory. May also create a `.husky/pre-commit` file with a placeholder.

**Step 2: Remove default pre-commit hook if created**

If `npx husky init` created `.husky/pre-commit`, remove it (we don't need it):

```bash
rm -f .husky/pre-commit
```

**Step 3: Create the commit-msg hook**

Create `.husky/commit-msg` with this content:

```bash
npx --no -- commitlint --edit $1
```

Note: husky v9 uses plain shell scripts in `.husky/`. No shebang needed — husky handles execution.

**Step 4: Make it executable**

```bash
chmod +x .husky/commit-msg
```

**Step 5: Commit**

```bash
git add .husky/
git commit -m "build(repo): add husky commit-msg hook for commitlint"
```

---

### Task 4: Add commitlint configuration

**Files:**
- Create: `commitlint.config.js`

**Step 1: Create commitlint.config.js**

```javascript
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [2, 'always', ['multi-review', 'jira-cli', 'repo']],
    'scope-empty': [0],
  },
};
```

Explanation of rules:
- `scope-enum`: Level 2 (error), always enforce, only allow these three scopes. This prevents typos like `feat(mulitreview):`.
- `scope-empty`: Level 0 (disabled). Allows commits without a scope (e.g., `feat: add new plugin`), which map to the repo-level version.

**Step 2: Commit**

```bash
git add commitlint.config.js
git commit -m "build(repo): add commitlint config with scope restrictions"
```

---

### Task 5: Test the enforcement

**Files:** None (validation only)

**Step 1: Test a valid commit message**

```bash
echo "feat(multi-review): test message" | npx commitlint
```

Expected: No output, exit code 0 (valid).

**Step 2: Test an invalid scope**

```bash
echo "feat(wrong-scope): test message" | npx commitlint
```

Expected: Error output mentioning `scope must be one of`, exit code 1.

**Step 3: Test an unscoped commit (should pass)**

```bash
echo "feat: unscoped commit" | npx commitlint
```

Expected: No output, exit code 0 (valid).

**Step 4: Test an invalid type**

```bash
echo "yolo: bad type" | npx commitlint
```

Expected: Error output mentioning `type must be one of`, exit code 1.

**Step 5: Test the hook end-to-end**

Create a temporary file, attempt a commit with a bad message, then clean up:

```bash
touch /tmp/test-commitlint
cp /tmp/test-commitlint test-commitlint-temp
git add test-commitlint-temp
git commit -m "yolo: this should fail" 2>&1 || true
git reset HEAD test-commitlint-temp
rm test-commitlint-temp
```

Expected: The commit is rejected by commitlint with an error about invalid type. The `git reset` cleans up.

**Step 6: Test the hook with a valid message**

```bash
touch test-commitlint-temp
git add test-commitlint-temp
git commit -m "test(repo): verify commitlint hook works"
```

Expected: Commit succeeds.

**Step 7: Remove the test commit**

```bash
git reset --soft HEAD~1
git reset HEAD test-commitlint-temp
rm test-commitlint-temp
```

This undoes the test commit without losing any real work.
