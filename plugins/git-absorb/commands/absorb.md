---
name: absorb
description: Identify target commits for staged changes and create fixup commits using git-absorb
argument-hint: "[--base <branch>] [--no-one-fixup-per-commit]"
allowed-tools:
  - Bash
---

Identify the target commits for all staged changes and create fixup commits using `git-absorb`.

## Arguments

Parse the user's arguments (if any):
- `--base <branch>`: Use `<branch>` as the base. Overrides auto-detection.
- `--no-one-fixup-per-commit`: Disable `--one-fixup-per-commit` (default is enabled).

## Step 1: Check git-absorb is installed

Run: `which git-absorb`

If not found, output this message and stop:

```
git-absorb is not installed.

Install it with:
  brew install git-absorb

Then re-run this command.
```

## Step 2: Check there are staged changes

Run: `git diff --cached --stat`

If there are no staged changes, output:

```
No staged changes found. Stage your changes first with:
  git add <files>
```

Then stop.

## Step 3: Determine the base branch

If the user provided `--base <branch>`, use that value. Otherwise auto-detect:

1. Try tracked upstream: `git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null`
   - If it returns a value (e.g. `origin/main`), strip the remote prefix to get the branch name (e.g. `main`). Use this.
2. Try remote default branch: `git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}'`
   - If it returns a non-empty value, use it.
3. If neither resolves, ask the user:
   ```
   Could not auto-detect a base branch. Please specify one:
   ```
   Wait for the user's response and use that value.

## Step 4: Run git-absorb (dry run)

Build the command:
- Always include: `--base <resolved-branch> --verbose`
- Include `--one-fixup-per-commit` unless `--no-one-fixup-per-commit` was passed

Run: `git absorb --dry-run --base <branch> --verbose [--one-fixup-per-commit]`

If the output indicates no commits could be identified (empty output, or contains "nothing to absorb" or similar), output:

```
No target commits found for the staged changes against base '<branch>'.

Possible reasons:
- The changes don't overlap with any recent commits
- The base branch may be wrong (try --base <other-branch>)
- The changes may need to be committed manually
```

Then stop.

## Step 5: Show identified commits and confirm

Show the user:
1. Which commits were identified as targets
2. The exact command that will be run

Ask: "Create fixup commits for the above? (yes/no)"

If the user says no, stop without doing anything.

## Step 6: Create fixup commits

Run the full command (without `--dry-run`):
`git absorb --base <branch> --verbose [--one-fixup-per-commit]`

Show the full output to the user.

If the command exits with a non-zero status, show the error and stop.

## Step 7: Prompt for rebase

Show:

```
Fixup commits created. To apply them, run:

  git rebase -i --autosquash <base-branch>

This will reorder and squash the fixup commits into their targets interactively.
Run it now? (yes/no)
```

If the user says yes, run: `git rebase -i --autosquash <base-branch>`

If the user says no, do nothing further.
