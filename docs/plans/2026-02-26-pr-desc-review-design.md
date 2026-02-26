# pr-desc-review Plugin Design

**Date:** 2026-02-26
**Status:** Approved

## Purpose

A Claude Code plugin that reviews PR descriptions to ensure they accurately
reflect the actual implementation. Reports discrepancies and suggests corrected
PR description text.

## Requirements

- **Output:** Report mismatches + suggest corrected PR description
- **PR detection:** Auto-detect from current branch via `gh pr view`, optional
  override via argument
- **Scope:** Summary/description accuracy (not test plans or templates)
- **Integration:** Standalone skill + multi-review compatible agent

## Architecture

```
pr-desc-review/
├── .claude-plugin/
│   └── plugin.json
├── package.json
├── skills/
│   └── pr-desc-review/
│       └── SKILL.md              # Standalone interactive skill
└── agents/
    └── desc-reviewer.md          # Headless agent for multi-review
```

### Approach: Dual Definitions, Shared Methodology

The skill and agent share the same review methodology but are tailored to their
invocation context:

- **SKILL.md** — interactive, can ask user questions, handles PR auto-detection,
  produces formatted output
- **agents/desc-reviewer.md** — headless reviewer, receives a review prompt from
  multi-review, returns structured markdown findings

## Review Methodology

Compares two inputs:

1. **PR description** — fetched via `gh pr view --json title,body`
2. **Actual implementation** — the diff via `gh pr diff`

### Comparison Checks

| Check                           | What it catches                                       |
| ------------------------------- | ----------------------------------------------------- |
| Claimed changes not in diff     | Description says "added X" but X isn't in code changes |
| Changes not mentioned           | Significant code changes with no mention in description |
| Accuracy of stated behavior     | Description says "fixes Y by doing Z" but code differs |
| Scope mismatch                  | Description implies small change, diff shows large (or vice versa) |

### Discrepancy Severities

- **Missing** — significant code change not mentioned in description
- **Inaccurate** — description claim contradicts actual implementation
- **Incomplete** — description mentions something vaguely but omits important details

### Output Format

```text
PR Description Review - PR #<NUMBER>
════════════════════════════════════════

[✓] <N> claims verified
[✗] <N> discrepancies found

[Missing] <description>
[Inaccurate] <description>
[Incomplete] <description>

Suggested PR Description:
─────────────────────────
## Summary
- <accurate bullet point>
- ...
```

## Skill Design (SKILL.md)

### Trigger Description

Mentions "review PR description", "PR accuracy", "description matches
implementation" so it triggers on review-oriented requests.

### Workflow

**Phase 1: Gather Context**

1. Auto-detect PR from current branch via `gh pr view`
2. Fetch PR title + body
3. Fetch PR diff via `gh pr diff`
4. If no PR found, inform user and exit

**Phase 2: Analyze**

1. Parse PR description into claims
2. Analyze diff to understand actual changes
3. Compare claims vs reality across the 4 check categories

**Phase 3: Report**

1. Print structured discrepancy report
2. Print suggested updated PR description
3. Offer to copy the suggestion (no auto-updating)

## Agent Design (desc-reviewer.md)

### Registration

- Agent type: `pr-desc-review:desc-reviewer`
- Description includes "review" and "code review" keywords for multi-review
  Phase 1 discovery

### Behavior

- Receives review target (PR number, branch, files) from multi-review prompt
- Fetches PR description and diff independently
- Returns structured markdown findings (same format, minus interactive elements)
- No user interaction — purely returns results

## Decisions

| Decision                        | Choice               | Rationale                                     |
| ------------------------------- | -------------------- | --------------------------------------------- |
| Dual skill + agent              | Yes                  | Interactive vs headless have different patterns |
| Auto-detect PR                  | Default, with override | Matches multi-review behavior                 |
| Scope: summary only             | Yes                  | Keep v1 focused; can expand later              |
| Report + suggest (not auto-update) | Yes               | User controls when to update PR description   |
