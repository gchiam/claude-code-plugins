# Options & Error Handling

## Input Options

| Option            | Description                        | Example            |
| ----------------- | ---------------------------------- | ------------------ |
| `--pr <number>`   | Review a specific PR               | `--pr 123`         |
| `--branch <name>` | Review branch vs main/master       | `--branch feat/x`  |
| `--files <paths>` | Review specific files only         | `--files src/*.ts` |
| `--base <ref>`    | Compare against specific base ref  | `--base develop`   |
| `--diff-only`     | Review only changed lines (default)|                    |
| `--full-context`  | Review entire files for context    |                    |

**Default behavior:** If no options specified, detect from current git state:

1. If on a branch with open PR → review that PR
2. If on a branch with uncommitted changes → review staged/unstaged changes
3. If on a branch ahead of main → review commits since divergence

## Configuration

| Option              | Description                  | Default       |
| ------------------- | ---------------------------- | ------------- |
| `--output-dir`      | Directory for review files   | `./.multi-reviews/` |
| `--confidence`      | Min confidence threshold     | `70`          |
| `--max-reviewers`   | Max review agents (`all` for no limit) | `3`  |
| `--no-input`        | Skip agent selection prompt   | `false`       |
| `--skip-validation` | Skip Phase 3, use raw results| `false`       |
| `--revalidate`      | Re-run Phase 3-4 on existing | `false`       |

## Error Handling

| Scenario                      | Behavior                             |
| ----------------------------- | ------------------------------------ |
| One agent fails in Phase 2    | Continue with available, warn user   |
| All agents fail in Phase 2    | Abort with error details             |
| Validation fails              | Use unvalidated results with warning |
| Output directory not writable | Fallback to current directory        |
| PR not found                  | Prompt for correct PR number         |
| No changes detected           | Exit with "nothing to review" message|
| No review agents discovered   | STOP and inform user to install review plugins |

**Always produce summary even with partial results** - indicate which
phases succeeded/failed.
