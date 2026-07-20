---
name: check-pr-comments
description: >-
  Use when the user wants to verify whether a reviewer's PR comments have
  actually been addressed in code, independent of GitHub's thread resolution
  status. Trigger on phrases like "check if <reviewer>'s comments are
  addressed", "verify PR comments are fixed", "did we address the review
  feedback on PR <n>", or "/check-pr-comments <number> <reviewer>".
user-invocable: true
argument-hint: "<pr-number> <reviewer> [file-path]"
allowed-tools:
  - Bash(git fetch*)
  - Bash(git diff*)
  - Bash(git log*)
  - Bash(gh api*)
  - Bash(gh pr*)
  - Read
  - Grep
metadata:
  owner: gchiam
  use_cases:
    - engineering
    - code-review
    - pr-review
  complexity: standard
---

# Check PR Comments

Verify whether a reviewer's inline PR comments are addressed **in code** —
never trust reply threads or resolution status alone. This is a read-only
check: it never edits files, applies fixes, or resolves threads.

## Invocation

```
/check-pr-comments <pr-number> <reviewer>
/check-pr-comments <pr-number> <reviewer> <file-path>
```

If `pr-number` or `reviewer` is missing, ask for it before proceeding.
`file-path` is optional — omit it to check all files the reviewer commented on.

## Why code, not threads

Reply threads and resolution status can both lie:

- An author can fix code without ever replying to the comment thread.
- A thread can be marked resolved without the underlying code actually
  changing.

So code is the source of truth. Thread/reply state is checked separately and
reported alongside it, never used as a substitute.

## When NOT to Use

- When the user wants to apply or fix the comments, not just check them —
  use `review-pr-comments` instead.
- When the user wants a fresh code review — use `multi-review` instead.

---

## Steps

### 1. Fetch the real branch

Never trust a local checkout without fetching first — a stale `HEAD` causes
false negatives.

```bash
gh pr view <PR_NUMBER> --json headRepository,headRepositoryOwner,headRefName \
  --jq '"\(.headRepositoryOwner.login)/\(.headRepository.name) \(.headRefName)"'
git fetch origin <branch>
```

Do all subsequent reads/greps against `origin/<branch>`, not local `HEAD`.

### 2. Fetch all inline comments, including replies

Fetch the full comment list first (not filtered by reviewer) — replies to
the reviewer's comments come from other users (usually the PR author) and
`in_reply_to_id` is the only way to associate them.

```bash
gh api repos/<owner>/<repo>/pulls/<n>/comments --paginate \
  | jq -c '.[] | {id, in_reply_to_id, path, line, user: .user.login, body}'
```

From this list:

- The reviewer's **top-level comments**: `user == <reviewer>` and
  `in_reply_to_id == null`.
- Each comment's **replies**: any comment whose `in_reply_to_id` matches the
  top-level comment's `id`, regardless of who wrote it. A thread can have
  multiple replies — keep them all, in order.

If `file-path` was given, filter top-level comments to that path only (keep
their replies regardless of path).

### 3. Derive a concrete code condition per comment

For each top-level comment, before looking at any code, state the specific,
falsifiable condition that would satisfy it — e.g. "constant X is a Set, not
an Array" or "the null check moved into method Y". A vague restatement of
the comment body is not a condition.

Read any replies on that comment first — a reply often states what was
changed and where, which narrows the condition or points at the exact line.
Do not take a reply's claim at face value; it still has to be confirmed
against code in the next step.

Then grep/read the current file on `origin/<branch>` to confirm that
condition holds. Cite the line number either way.

### 4. Check thread resolution separately

```bash
gh api graphql -f query='
query {
  repository(owner: "<owner>", name: "<repo>") {
    pullRequest(number: <n>) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          comments(first: 1) {
            nodes { id databaseId author { login } body }
          }
        }
      }
    }
  }
}'
```

Match `databaseId` back to the comment `id`s from step 2 to get each
comment's thread `isResolved` state.

### 5. Report per-comment, code as source of truth

```
PR #<n> — @<reviewer>'s comments
════════════════════════════════════════
  #<id>  <path>:<line>  code: yes/no (line <n>)   thread: resolved/unresolved   replies: <N>
  ...

  <N> of <M> addressed in code; <N> of <M> threads resolved

Details:
  #<id> — <one sentence: what the code condition was and whether it holds>
    reply @<user>: "<first 60 chars of reply body>"
    ...
  ...
```

Omit the `reply` lines for comments with no replies. Include every reply on
a comment, in order, when there are any.

Flag mismatches explicitly:

- **code fixed, thread unresolved** → note it should be resolved (do not
  resolve it — that's a separate, explicit action, not part of this check).
- **thread resolved, code not actually changed** → flag as a false positive.

Do not call `resolveReviewThread` or any other mutating API as part of this
check, even if a mismatch is found. Resolving threads is a separate, explicit
user request.
