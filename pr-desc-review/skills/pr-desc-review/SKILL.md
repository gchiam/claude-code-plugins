---
name: pr-desc-review
description: >-
  Review PR description accuracy by comparing what the description claims against
  the actual code changes. Use this skill to review a PR description, check if a
  PR description matches the implementation, verify PR accuracy, or perform a
  code review focused on whether the description reflects reality. Trigger when
  the user says things like "review PR description", "does my PR description
  match the code", "check PR accuracy", "is my PR description correct", or
  "description review".
---

# PR Description Review

Review the current branch's pull request description against its actual diff to
find discrepancies, missing mentions, and inaccuracies.

> **Your first action is Phase 1 below. Do NOT skip to analysis without
> gathering context first.**

## Rules

1. **Always use `gh` CLI.** Do not make raw API calls or use `curl` against the
   GitHub API. All GitHub interactions go through `gh`.
2. **Never auto-update the PR description.** Only suggest improvements. The user
   decides whether to apply changes.
3. **If no PR exists for the current branch, inform the user and stop.** Do not
   attempt to create a PR or guess at a PR number.

---

## Phase 1: Gather Context

**Step 1: Detect the PR.**

If the user specified a PR number or URL, use it directly:

```bash
gh pr view <NUMBER_OR_URL> --json number,title,body,url
```

Otherwise, auto-detect from the current branch:

```bash
gh pr view --json number,title,body,url
```

If this command fails (exit code non-zero), print:

```text
No open PR found for the current branch.
Please push your branch and open a PR first, then re-run this skill.
```

Then **STOP** — do not proceed to Phase 2.

**Step 2: Fetch the diff.**

```bash
gh pr diff
```

If this command fails (exit code non-zero or empty output), print:

```text
Failed to fetch the PR diff. The PR may have no changes, or there may be a
network issue. Please verify the PR has commits and try again.
```

Then **STOP** — do not proceed to Phase 2.

**Step 3: Print progress.**

```text
Analyzing PR #<NUMBER>: <TITLE>
URL: <URL>
```

Proceed to Phase 2.

---

## Phase 2: Analyze

Systematically compare the PR description against the diff.

### Step 1: Parse Description Claims

If the PR body is empty, null, or contains only template boilerplate with no
actual content, skip to Phase 3 and report all diff changes as **Missing** with
the note: "PR description is empty — all changes are undocumented."

Otherwise, read the PR body and extract every concrete claim about what was
changed. A claim is any statement that asserts something was added, removed,
modified, fixed, refactored, or configured. Ignore boilerplate (e.g., template
headings with no content, checkbox lists that are structural).

Number each claim for reference in the report.

### Step 2: Analyze the Diff

From the diff output, catalog:

- Which files were added, removed, or modified
- What functions, classes, or exports were changed
- What behavior was added or altered
- What dependencies or configurations changed

### Step 3: Cross-Reference

Compare each claim against the diff evidence. Classify every finding into one of
these categories:

| Category        | Meaning                                                    |
| --------------- | ---------------------------------------------------------- |
| **Verified**    | Claim is accurate and supported by the diff                |
| **Missing**     | Significant change in the diff with no mention in the description |
| **Inaccurate**  | Description says X but the code does Y                     |
| **Incomplete**  | Claim is vague or understates the actual scope of a change |
| **Scope mismatch** | Description implies small change but diff is large, or vice versa |

Guidelines for classification:

- **Claimed changes not in diff** — the description mentions something that does
  not appear in the code changes. Mark as **Inaccurate**.
- **Changes not mentioned** — a file was substantially changed or a new feature
  was added with no corresponding description. Mark as **Missing**.
- **Accuracy of stated behavior** — description says "fixes bug X" but the code
  change does something different. Mark as **Inaccurate**.
- **Scope mismatch** — description says "minor refactor" but the diff touches
  20 files across 3 packages. Mark as **Scope mismatch**.
- Minor changes (whitespace, formatting, import reordering) do not need to be
  mentioned in the description. Do not flag these as **Missing**.

---

## Phase 3: Report

Print the structured report using this exact format.

<!-- Keep report format in sync with agents/desc-reviewer.md -->

### When discrepancies are found

```text
PR Description Review - PR #<NUMBER>
════════════════════════════════════════
Reviewing: <TITLE>

[✓] <N> claims verified
[✗] <N> discrepancies found

<For each discrepancy, one line in this format:>
[Missing] <description of unmentioned change>
[Inaccurate] <description of incorrect claim>
[Incomplete] <description of vague claim>
[Scope mismatch] <description of scope issue>

Suggested PR Description:
─────────────────────────
## Summary
- <bullet points reflecting actual implementation>
```

Rules for the suggested description:

- Reflect the **actual diff**, not the original claims
- Use concise bullet points
- Group related changes logically
- Do not include changes that are not in the diff

### When no discrepancies are found

```text
PR Description Review - PR #<NUMBER>
════════════════════════════════════════
Reviewing: <TITLE>

[✓] <N> claims verified
[✗] 0 discrepancies found

The PR description accurately reflects the implementation. No changes needed.
```
