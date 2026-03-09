# Common Workflows

End-to-end multi-command sequences for typical Jira tasks.

## Start of Day: What Am I Working On?

```bash
ME=$(jira me)
jira issue list -q "sprint IN openSprints() AND assignee = currentUser()" \
  --plain --columns key,summary,status,priority
```

## Pick Up and Start an Issue

```bash
jira issue assign ISSUE-123 "$ME"
jira issue move ISSUE-123 "In Progress"
```

## Complete an Issue

```bash
jira issue worklog add ISSUE-123 "4h" --comment "Implementation complete" --no-input
jira issue move ISSUE-123 "Done" --comment "Merged in PR #456" -RFixed
```

## Create a Bug from a Code Finding

```bash
KEY=$(jira issue create -tBug -s"Memory leak in connection pool" \
  -yHigh -lbug -Cbackend \
  -b"Found during code review. Connection objects are not released when..." \
  --no-input --raw 2>/dev/null | jq -r '.key')
jira issue assign "$KEY" "$ME"
jira issue move "$KEY" "In Progress"
```

## Bulk Status Check for a Team

```bash
jira issue list -q "project = PROJ AND sprint IN openSprints()" \
  --plain --columns key,summary,status,assignee
```

## Batch Create Issues

Create multiple related issues with rate-limit-safe spacing:

```bash
KEYS=()
for SUMMARY in "Set up CI pipeline" "Add unit tests" "Write API docs"; do
  KEY=$(jira issue create -tTask -s"$SUMMARY" -pPROJ \
    --no-input --raw | jq -r '.key')
  KEYS+=("$KEY")
  echo "Created $KEY"
  sleep 1
done

# Optionally add to an epic: jira epic add EPIC-42 "${KEYS[@]}"
# Add all created issues to a sprint (see Discovery Patterns for $SPRINT_ID)
jira sprint add "$SPRINT_ID" "${KEYS[@]}"
```

## Batch Transition Issues

Move multiple issues to a target status. Continues on failure and reports
which issues failed:

```bash
FAILED=()
KEYS=()
while IFS= read -r KEY; do
  KEYS+=("$KEY")
done < <(jira issue list -q "project = PROJ AND status = 'Code Review'" \
  --plain --no-headers | awk -F'\t' '{print $2}')

for KEY in "${KEYS[@]}"; do
  if ! jira issue move "$KEY" "Done" --comment "Sprint cleanup" -RFixed 2>/dev/null; then
    FAILED+=("$KEY")
  fi
  sleep 1
done

if [ ${#FAILED[@]} -gt 0 ]; then
  echo "Failed to transition: ${FAILED[*]}"
fi
```

## Triage Backlog

Query unassigned issues and assign/prioritize them. Uses `$ME` from the
"Start of Day" workflow (`ME=$(jira me)`):

```bash
# List unassigned issues in priority order
jira issue list -pPROJ -ax --plain --columns key,summary,priority,created \
  --order-by priority

# Assign and prioritize a specific issue
jira issue assign PROJ-456 "$ME"
jira issue edit PROJ-456 -yHigh -l"sprint-candidate" --no-input
```

## Sprint Planning

Find the target sprint, query candidate issues, and add them:

```bash
# Get the next sprint ID
SPRINT_ID=$(jira sprint list --state future --table --plain --no-headers \
  | awk -F'\t' '{print $1}' | head -1)

# Find candidate issues
jira issue list -pPROJ -s"To Do" -l"sprint-candidate" \
  --plain --columns key,summary,priority

# Add selected issues to the sprint
jira sprint add "$SPRINT_ID" PROJ-101 PROJ-102 PROJ-103
```
