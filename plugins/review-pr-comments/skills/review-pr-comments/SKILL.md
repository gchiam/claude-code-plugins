---
name: review-pr-comments
description: >-
  Use when the user wants to address, process, or work through GitHub PR review
  comments. Trigger on phrases like "address PR comments", "work through review
  comments", "process PR feedback", "apply reviewer suggestions", or
  "/review-pr-comments <number>".
user-invocable: true
argument-hint: "<pr-number> [--fix] [--comment <comment-id-or-url>]"
allowed-tools:
  - Bash(gh api*)
  - Bash(gh pr*)
  - Bash(git log*)
  - Bash(git add*)
  - Bash(git commit*)
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
/review-pr-comments <pr-number> --fix
/review-pr-comments <pr-number> --comment <comment-id-or-url>
/review-pr-comments <pr-number> --fix --comment <comment-id-or-url>
```

**`--fix`** — when present, apply code changes and commit for ACCEPT decisions.
Without `--fix` (default), the skill assesses and reports decisions only — no
files are edited and no commits are made. This is useful for reviewing what
would be done before committing to it.

**`--comment`** accepts either a numeric comment ID or a full GitHub comment URL
(e.g. `https://github.com/owner/repo/pull/42#discussion_r12345678`).
If a URL is provided, extract the numeric ID from the fragment (the digits after `_r`).

If `--comment` is provided, still execute Phase 1 Steps 1 and 2 (resolve
repo, then fetch the single comment using `gh api repos/<OWNER>/<REPO>/pulls/comments/<COMMENT_ID>`),
skip Steps 3 and 4 (discovery report and task creation), then proceed directly
to Phase 2 for that comment.

## Rules

1. **Never amend commits.** Always create new commits (fixup or regular).
2. **Fixup commits for same-file/same-feature changes.** Use
   `git log --oneline` to find the target. Format: `fixup! <original message>`.
3. **Regular commits for independent changes.** New behavior, new files, docs
   additions get their own descriptive commit. First run `git log --oneline -10`
   to inspect the repo's commit style, then match it exactly.
4. **Run tests after applying changes to test files.** Run the project's tests
   for the affected code. Example (Java/Gradle):
   `./gradlew test --tests <RelevantTestClass>`
   Adapt to the project's actual test runner (npm test, pytest, cargo test, etc.).
5. **SKIP stale comments.** If the referenced code no longer exists or has
   already been addressed, mark `SKIP` with a reason -- do not apply a change.
6. **Verify after each fix.** Re-read the changed lines to confirm correctness
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
If `diff_hunk` is null or absent, rely solely on the `body` and current file state to assess applicability.

**If stale** (referenced file or code no longer exists, or the diff_hunk pattern
is absent):

```
SKIP -- <reason>  (e.g. "file was deleted in a prior commit")
```

Call `TaskUpdate` with `status: completed` and prepend `[SKIP]` to the
description. Move to the next comment.

**If already addressed** (the suggestion was already applied — the current code
already matches what the comment requested):

```
ALREADY_DONE -- <reason>  (e.g. "guard clause already present at line 45")
```

Call `TaskUpdate` with `status: completed` and prepend `[ALREADY_DONE]` to the
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

### 2.4 Apply (ACCEPT + --fix only)

If `--fix` was **not** provided, skip this step entirely -- proceed to 2.7 and
note "assessment only, no change applied" in the task summary.

If `--fix` is present:

- **GitHub suggestion block** (` ```suggestion ` in body): apply the suggestion
  text exactly as written, replacing the hunk lines.
- **Prose suggestion**: implement the intent of the comment. Keep changes
  minimal -- do not refactor surrounding code.

### 2.5 Verify (--fix only)

Skip this step if `--fix` was not provided.

Re-read the changed file at the affected lines. Confirm:

- The fix matches the comment's intent
- No surrounding code was accidentally modified
- Import order and formatting are correct (for Java: checkstyle conventions)

If the changed file has corresponding tests, run them. Run the project's tests
for the affected code. Example (Java/Gradle):

```bash
./gradlew test --tests <RelevantTestClass>
```

Adapt to the project's actual test runner (npm test, pytest, cargo test, etc.).

If tests fail, fix the implementation before proceeding to commit.

### 2.6 Commit (--fix only)

Skip this step if `--fix` was not provided -- proceed to 2.7.

If decision is REJECT, NO_ACTION, ALREADY_DONE, or SKIP, skip this step entirely -- proceed to 2.7.

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

### 2.7 Update task

Call `TaskUpdate`:

- `status`: `completed`
- Prepend decision tag to description: `[ACCEPT]`, `[REJECT]`, `[NO_ACTION]`,
  `[ALREADY_DONE]`, or `[SKIP]`
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
| #<id> | @<user> | <path>:<line> | ALREADY_DONE | <reason> | ✅ ALREADY DONE |
| #<id> | @<user> | <path>:<line> | SKIP | <reason> | ⬜ SKIPPED |

Totals: <N> accepted  <N> already done  <N> rejected  <N> no-action  <N> skipped
```
