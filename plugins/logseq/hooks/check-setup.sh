#!/bin/bash
# check-setup.sh
# Checks graphthulhu installation and Logseq API token at session start.
# Outputs a system message with setup instructions if anything is missing.

set -euo pipefail

issues=()

# Check 1: graphthulhu binary on PATH
if ! command -v graphthulhu &>/dev/null; then
  issues+=("graphthulhu binary not found on PATH")
fi

# Check 2: LOGSEQ_API_TOKEN is set
if [ -z "${LOGSEQ_API_TOKEN:-}" ]; then
  issues+=("LOGSEQ_API_TOKEN environment variable is not set")
fi

# If no issues, exit silently
if [ ${#issues[@]} -eq 0 ]; then
  exit 0
fi

# Build setup message
msg="[logseq plugin] Setup required:\n"
for issue in "${issues[@]}"; do
  msg+="  - $issue\n"
done

msg+="\nTo fix:\n"

if ! command -v graphthulhu &>/dev/null; then
  msg+="  1. Install graphthulhu: go install github.com/skridlevsky/graphthulhu@latest\n"
  msg+="     Or download binary from: https://github.com/skridlevsky/graphthulhu/releases\n"
  msg+="     Ensure it is in your PATH (e.g. export PATH=\"\$PATH:\$(go env GOPATH)/bin\")\n"
fi

if [ -z "${LOGSEQ_API_TOKEN:-}" ]; then
  msg+="  2. Enable Logseq HTTP API:\n"
  msg+="     - Open Logseq → Settings → Features → Enable 'HTTP APIs server'\n"
  msg+="     - Click the API icon in toolbar → Start Server → Create Token\n"
  msg+="     - Set: export LOGSEQ_API_TOKEN=\"your-token\"\n"
fi

msg+="\nRun the 'logseq-setup' agent for guided setup assistance."

# Output as system message for Claude to display (use jq for safe JSON encoding)
echo -e "$msg" | jq -Rs '{"systemMessage": .}'
exit 0
