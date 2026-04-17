---
name: review-pr-comments
description: >-
  Use when the user wants to address, process, or work through GitHub PR review
  comments. Trigger on phrases like "address PR comments", "work through review
  comments", "process PR feedback", "apply reviewer suggestions", or
  "/review-pr-comments <number>".
user-invocable: true
argument-hint: "<pr-number> [--comment <comment-id>]"
allowed-tools:
  - Bash(gh api*)
  - Bash(gh pr*)
  - Bash(git log*)
  - Bash(git add*)
  - Bash(git commit*)
  - Bash(git diff*)
  - Read
  - Edit
  - Write
  - TaskCreate
  - TaskUpdate
  - TaskGet
  - TaskList
metadata:
  owner: gchiam
  use_cases:
    - engineering
    - code-review
    - pr-review
  complexity: standard
---

# Review PR Comments

Systematically fetch, evaluate, apply, and commit GitHub PR inline review comments.

> **Your first action is Phase 1. Do NOT skip ahead.**

## Invocation

```
/review-pr-comments <pr-number>
/review-pr-comments <pr-number> --comment <comment-id>
```

If `--comment <id>` is provided, process only that single comment and skip the
task-creation loop -- jump directly to Phase 2 for that comment.

## Rules

1. **Never amend commits.** Always create new commits (fixup or regular).
2. **Fixup commits for same-file/same-feature changes.** Use
   `git log --oneline` to find the target. Format: `fixup! <original message>`.
3. **Regular commits for independent changes.** New behavior, new files, docs
   additions get their own descriptive commit. First run `git log --oneline -10`
   to inspect the repo's commit style, then match it exactly.
4. **Batch multiple comments touching the same file** into one fixup commit when
   they are all independent of each other (no ordering dependency).
5. **Run tests after applying changes to test files.** Command:
   `./gradlew test --tests <RelevantTestClass>` (Java/Gradle). Adapt to the
   project's test runner if different.
6. **SKIP stale comments.** If the referenced code no longer exists or has
   already been addressed, mark `SKIP` with a reason -- do not apply a change.
7. **Verify after each fix.** Re-read the changed lines to confirm correctness
   before committing.

## When NOT to Use

- When the PR has no open review comments (nothing to process).
- When the user wants to write a new code review (use `multi-review` instead).
- When the user wants to review the PR description (use `pr-desc-review` instead).
- When the user wants to browse or triage comments without applying fixes.

---

## Phase 1: Fetch and Register Comments

### Step 1: Resolve repo

```bash
gh pr view <PR_NUMBER> --json headRepository,headRepositoryOwner \
  --jq '"\(.headRepositoryOwner.login)/\(.headRepository.name)"'
```

Store as `OWNER/REPO`.

### Step 2: Fetch inline review comments

```bash
gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments \
  --paginate \
  --jq '[.[] | select(.in_reply_to_id == null)]'
```

This returns only top-level (non-reply) comments. If the result is an empty
array, print:

```
No top-level review comments found on PR #<PR_NUMBER>.
```

Then STOP.

### Step 3: Print discovery report

```
PR Comments - PR #<PR_NUMBER>
════════════════════════════════════════
Found <N> top-level review comment(s):

  #<id>  <path>:<line>  @<user>  "<first 60 chars of body>"
  #<id>  <path>:<line>  @<user>  "<first 60 chars of body>"
  ...
```

### Step 4: Create one Task per comment

For each comment, call `TaskCreate` with:

- `name`: `Comment #<id> -- <path>:<line>`
- `description`: Full comment body + reviewer login + diff_hunk for context
- `status`: `pending`

Record the task ID alongside the comment ID for later updates.

---

## Phase 2: Process Each Comment

Work through tasks in order. For each task:

### 2.1 Read context

Read the file referenced by `path`. Focus on the lines around `line` (+-20 lines
for context). Note the current state of the code.

### 2.2 Validate applicability

Compare the comment's `diff_hunk` and `body` against current file contents.

**If stale** (code no longer exists, already fixed, or the diff_hunk pattern is
absent):

```
SKIP -- <reason>  (e.g. "code was refactored in a prior commit")
```

Call `TaskUpdate` with `status: completed` and prepend `[SKIP]` to the
description. Move to the next comment.

### 2.3 Decide

Assess the comment and choose one decision with explicit reasoning:

| Decision | Meaning |
|----------|---------|
| `ACCEPT` | Agree with the suggestion -- will apply the fix |
| `REJECT` | Disagree -- explain why, no code change needed |
| `NO_ACTION` | Informational or emoji-only comment -- no code change needed |

Print:

```
Decision: ACCEPT / REJECT / NO_ACTION
Reasoning: <one or two sentences>
```

### 2.4 Apply (ACCEPT only)

- **GitHub suggestion block** (` ```suggestion ` in body): apply the suggestion
  text exactly as written, replacing the hunk lines.
- **Prose suggestion**: implement the intent of the comment. Keep changes
  minimal -- do not refactor surrounding code.

### 2.5 Verify

Re-read the changed file at the affected lines. Confirm:

- The fix matches the comment's intent
- No surrounding code was accidentally modified
- Import order and formatting are correct (for Java: checkstyle conventions)

If the changed file has corresponding tests, run them:

```bash
./gradlew test --tests <RelevantTestClass>
```

If tests fail, fix the implementation before proceeding to commit.

### 2.6 Commit

Run `git log --oneline -20` to inspect recent commits.

**Fixup commit** (change belongs to an existing commit -- same file, same
feature):

```bash
git add <file>
git commit -m "fixup! <original commit message>"
```

**Regular commit** (independent change -- new behavior, new file, separate doc
update):

First inspect the repo's commit style:

```bash
git log --oneline -10
```

Then commit following that style exactly:

```bash
git add <file>
git commit -m "<message matching repo commit style>"
```

**Batched fixup** (multiple independent comments in the same file -- commit
them together):

```bash
git add <file>
git commit -m "fixup! <original commit message>"
```

### 2.7 Update task

Call `TaskUpdate`:

- `status`: `completed`
- Prepend decision tag to description: `[ACCEPT]`, `[REJECT]`, or
  `[NO_ACTION]`
- Append one-line summary of what was done (or why no action was taken)

---

## Phase 3: Summary Table

After all tasks are processed, print:

```
PR Comments Summary - PR #<PR_NUMBER>
════════════════════════════════════════

| Comment ID | Reviewer | File | Decision | Reasoning | Status |
|------------|----------|------|----------|-----------|--------|
| #<id> | @<user> | <path>:<line> | ACCEPT | <reason> | ✅ DONE |
| #<id> | @<user> | <path>:<line> | REJECT | <reason> | ❌ REJECTED |
| #<id> | @<user> | <path>:<line> | NO_ACTION | <reason> | ⬜ SKIPPED |
| #<id> | @<user> | <path>:<line> | SKIP | <reason> | ⬜ SKIPPED |

Totals: <N> accepted  <N> rejected  <N> no-action  <N> skipped
```
