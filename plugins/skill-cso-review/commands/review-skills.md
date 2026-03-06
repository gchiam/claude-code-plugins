---
description: Run the skill-quality-reviewer agent to check SKILL.md files for CSO compliance
argument-hint: "[path]"
---

Run the skill-quality-reviewer subagent to audit SKILL.md files for CSO compliance
(C1, C2, I1, M1 criteria).

If a path argument was provided, pass that path to the reviewer.
Otherwise, pass the current working directory so all SKILL.md files in the repo are checked.
