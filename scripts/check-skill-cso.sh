#!/usr/bin/env bash
#
# Static CSO compliance check for staged SKILL.md files.
# Checks C1 (description starts with "Use when") and I1 ("When NOT to Use" present).
# C2 and M1 require semantic analysis — use /skill-cso-review:review-skills for those.
#
# Usage: called from pre-commit hook, or: bash scripts/check-skill-cso.sh [file...]

set -uo pipefail

ERRORS=0

# Get files to check: args if provided, otherwise staged SKILL.md files
if [ $# -gt 0 ]; then
  FILES=("$@")
else
  mapfile -t FILES < <(git diff --cached --name-only | grep 'SKILL\.md$')
fi

if [ ${#FILES[@]} -eq 0 ]; then
  exit 0
fi

for FILE in "${FILES[@]}"; do
  [ -f "$FILE" ] || continue

  echo "Checking $FILE..."

  # C1: description must start with "Use when"
  # Extract the description value from YAML frontmatter (handles multiline >- blocks)
  DESC=$(awk '
    /^---$/ { if (++fence == 2) exit }
    fence == 1 && /^description:/ { found=1; sub(/^description:[[:space:]]*(>-[[:space:]]*)?/, ""); desc=$0; next }
    fence == 1 && found && /^[[:space:]]/ { gsub(/^[[:space:]]+/, ""); desc=desc" "$0; next }
    fence == 1 && found && !/^[[:space:]]/ { found=0 }
    END { print desc }
  ' "$FILE" | sed 's/^[[:space:]]*//')

  if ! echo "$DESC" | grep -qi '^Use when'; then
    echo "  FAIL [C1] Description does not start with \"Use when...\""
    echo "       Got: $(echo "$DESC" | head -c 80)"
    ERRORS=$((ERRORS + 1))
  fi

  # I1: "When NOT to Use" section must be present
  if ! grep -q 'When NOT to Use' "$FILE"; then
    echo "  FAIL [I1] Missing \"When NOT to Use\" section"
    ERRORS=$((ERRORS + 1))
  fi

  if [ $ERRORS -eq 0 ]; then
    echo "  OK"
  fi
done

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "CSO check failed with $ERRORS error(s)."
  echo "Run /skill-cso-review:review-skills for full analysis (C2, M1)."
  exit 1
fi
