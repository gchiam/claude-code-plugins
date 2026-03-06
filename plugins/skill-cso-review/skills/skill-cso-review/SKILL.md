---
name: skill-cso-review
description: >-
  Use when you want to audit SKILL.md files for CSO compliance, check if skill
  descriptions follow the "Use when..." pattern, or verify skill structure meets
  quality standards before committing or publishing.
user-invocable: false
---

# Skill CSO Review

Audit SKILL.md files in this repo for CSO (Claude Search Optimization) compliance
using the skill-quality-reviewer agent.

## When NOT to Use

- You only want to preview a skill's content (use Read instead)
- You are not working in a repo that contains SKILL.md files

## Automatic Checks

When this plugin is enabled, a `PostToolUse` hook automatically checks C1 and I1
after any `SKILL.md` edit. If issues are found, Claude is notified immediately via
a system message.

## Manual Review

Run `/skill-cso-review:review-skills` to audit all SKILL.md files in the current repo.

Run `/skill-cso-review:review-skills <path>` to audit a specific file or directory.

## Criteria Checked

| ID | Severity | Description |
|---|---|---|
| C1 | Critical | Description must start with "Use when..." |
| C2 | Critical | Description must not summarize the workflow |
| I1 | Important | "When NOT to Use" section must be present |
| M1 | Minor | No unrecognized frontmatter fields |
