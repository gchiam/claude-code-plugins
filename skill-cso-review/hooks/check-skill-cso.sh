#!/usr/bin/env bash
#
# PostToolUse hook: check SKILL.md files for CSO compliance after edits.
# Runs C1 and I1 checks. If issues found, outputs a systemMessage to Claude.
#
# C1: description must start with "Use when"
# I1: "When NOT to Use" section must be present

set -uo pipefail

input=$(cat)
file_path=$(echo "$input" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log(d.tool_input?.file_path || d.tool_input?.path || '')" 2>/dev/null || echo "")

# Only run on SKILL.md files
if [[ "$file_path" != *"SKILL.md" ]]; then
  exit 0
fi

# File must exist
if [ ! -f "$file_path" ]; then
  exit 0
fi

ERRORS=()

# C1: description must start with "Use when"
DESC=$(awk '
  /^---$/ { if (++fence == 2) exit }
  fence == 1 && /^description:/ { found=1; sub(/^description:[[:space:]]*(>-[[:space:]]*)?/, ""); desc=$0; next }
  fence == 1 && found && /^[[:space:]]/ { gsub(/^[[:space:]]+/, ""); desc=desc" "$0; next }
  fence == 1 && found && !/^[[:space:]]/ { found=0 }
  END { print desc }
' "$file_path" | sed 's/^[[:space:]]*//')

if ! echo "$DESC" | grep -qi '^Use when'; then
  ERRORS+=("[C1] Description does not start with \"Use when...\". Got: $(echo "$DESC" | head -c 80)")
fi

# I1: "When NOT to Use" section must be present
if ! grep -q 'When NOT to Use' "$file_path"; then
  ERRORS+=("[I1] Missing \"When NOT to Use\" section")
fi

if [ ${#ERRORS[@]} -eq 0 ]; then
  exit 0
fi

# Output systemMessage so Claude sees the issues
MSG="CSO compliance issues found in $file_path:"
for err in "${ERRORS[@]}"; do
  MSG="$MSG\n  - $err"
done
MSG="$MSG\nFix these before committing. Run /skill-cso-review:review-skills for full analysis."

node -e "console.log(JSON.stringify({systemMessage: process.argv[1]}))" "$MSG"
exit 0
