# check-pr-comments

A Claude Code skill that verifies whether a reviewer's GitHub PR inline
comments are addressed in code, independent of (and cross-checked against)
GitHub's thread resolution status.

## Installation

```bash
claude plugin install check-pr-comments
```

## Usage

```
/check-pr-comments <pr-number> <reviewer>
/check-pr-comments <pr-number> <reviewer> <file-path>
```

`file-path` is optional — omit it to check every file the reviewer commented on.

## Why code, not threads

Reply threads and resolution status can both be wrong: an author can fix
code without replying to a thread, and a thread can be marked resolved
without the code actually changing. This skill treats code as the source of
truth and reports thread state alongside it, not as a substitute.

## What it does

1. `git fetch`es the PR's actual branch — never trusts a stale local checkout.
2. Fetches all inline comments via the GitHub REST API, including replies
   (matched via `in_reply_to_id`), so a reply from the author counts even if
   it's not the reviewer's own comment.
3. For each comment, reads any replies for context, states a concrete code
   condition (e.g. "constant X is a Set, not an Array"), and greps/reads the
   fetched branch to confirm it, citing the line number.
4. Separately fetches thread resolution status via GraphQL.
5. Reports per-comment code status and thread status, flagging mismatches:
   - code fixed but thread unresolved → should be resolved (not done here)
   - thread resolved but code unchanged → false positive

This is a read-only check. It never edits files, applies fixes, or resolves
threads — use `review-pr-comments` for that.

## Example output

```
PR #302 — @gchiam's comments
════════════════════════════════════════
  #111  app/services/foo.rb:42  code: yes (line 44)   thread: unresolved   replies: 1
  #112  app/services/foo.rb:58  code: yes (line 58)   thread: resolved     replies: 0
  #113  app/services/foo.rb:70  code: no              thread: resolved     replies: 1

  2 of 3 addressed in code; 2 of 3 threads resolved

Details:
  #111 — fix is in code but thread was never resolved; consider resolving it.
    reply @author: "Fixed, moved the check into validate() at line 44"
  #113 — thread marked resolved but the guard clause is not present; false positive.
    reply @author: "Done, added the null check"
```
