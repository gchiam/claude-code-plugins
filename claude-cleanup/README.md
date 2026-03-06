# claude-cleanup

Remove stale project entries from `~/.claude.json` whose directories no longer exist on disk.

## Usage

```text
"Clean up claude.json"
"Remove stale projects"
"Prune old project entries"
```

## What it does

1. **Scans** `~/.claude.json` for project entries whose directories are missing
2. **Shows** the stale paths before doing anything
3. Optionally runs `/insights` first
4. **Removes** the stale entries and writes a backup to `~/.claude.json.bak`

## When NOT to use

- You want to delete *all* project history (this only removes entries whose directories are missing)
- You want to manually edit `~/.claude.json` for other reasons
