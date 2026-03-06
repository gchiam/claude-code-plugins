# git-absorb

Create fixup commits targeting the right parent commits using [`git-absorb`](https://github.com/tummychow/git-absorb).

## Prerequisites

```bash
brew install git-absorb
```

## Usage

```text
/git-absorb
/git-absorb --base main
/git-absorb --no-one-fixup-per-commit
```

## What it does

1. **Checks** `git-absorb` is installed and there are staged changes
2. **Auto-detects** the base branch (or accepts `--base <branch>`)
3. **Dry-runs** to show which commits would be targeted
4. **Confirms** before creating fixup commits
5. **Optionally** runs `git rebase -i --autosquash` to squash them in

## Options

| Option | Description |
|---|---|
| `--base <branch>` | Override base branch auto-detection |
| `--no-one-fixup-per-commit` | Allow multiple fixups per target commit |
