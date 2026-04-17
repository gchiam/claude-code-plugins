# review-pr-comments

A Claude Code skill that systematically fetches, evaluates, and applies GitHub PR inline review comments.

## Installation

```bash
claude plugin install review-pr-comments
```

## Usage

```
/review-pr-comments <pr-number>
/review-pr-comments <pr-number> --fix
/review-pr-comments <pr-number> --comment <comment-id-or-url>
/review-pr-comments <pr-number> --fix --comment <comment-id-or-url>
```

### Flags

**`--fix`** — apply code changes and commit for ACCEPT decisions. Without this flag (the default), the skill assesses and reports decisions only. Run without `--fix` first to preview what would happen, then re-run with `--fix` to apply.

**`--comment`** — process a single comment instead of all comments. Accepts either a numeric comment ID or a full GitHub comment URL (e.g. `https://github.com/owner/repo/pull/42#discussion_r12345678`).

## What it does

The skill runs in three phases:

**Phase 1 — Fetch:** Resolves the repo, fetches all top-level inline review comments, prints a discovery report, and creates a task per comment for tracking.

**Phase 2 — Process:** For each comment, reads the file in context, validates whether the comment still applies, decides what to do, and (with `--fix`) applies and commits the change.

**Phase 3 — Summary:** Prints a summary table of all decisions with totals.

## Decisions

| Decision | Meaning |
|----------|---------|
| `ACCEPT` | Agree with the suggestion — applies the fix (requires `--fix`) |
| `REJECT` | Disagree — explains why, no code change |
| `NO_ACTION` | Informational or emoji-only comment — no code change |
| `ALREADY_DONE` | Fix was already applied — the code already matches the suggestion |
| `SKIP` | Referenced code no longer exists — comment is stale |

## Example output

```
PR Comments Summary - PR #42
════════════════════════════════════════

  ✅ DONE         #111 @alice  src/auth.ts:45
  ✅ ALREADY DONE #112 @bob    src/utils.ts:12
  ❌ REJECTED     #113 @alice  src/api.ts:88
  ⬜ NO ACTION    #114 @carol  README.md:3

Totals: 1 accepted  1 already done  1 rejected  1 no-action  0 skipped

Details:
  #113 REJECT  — The null check is intentional; the caller guarantees non-null at this point.
```

## Commit strategy

When `--fix` is active and a change is applied:

- **Fixup commit** for changes to files already touched in a recent commit: `fixup! <original message>`
- **Regular commit** for independent changes, matching the repo's existing commit style
