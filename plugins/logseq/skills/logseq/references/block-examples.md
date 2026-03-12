# upsert_blocks Examples

Worked examples for all entry types using the graphthulhu `upsert_blocks` tool.

## Note Entry

```json
{
  "page": "Journal/2026-03-10",
  "blocks": [
    {
      "content": "Refactoring the auth module reduces coupling #claude-managed #note #refactoring\ntype:: note\nsource:: claude-code",
      "children": [
        { "content": "The current auth module mixes session handling with token validation" },
        { "content": "Proposed split: `auth/session.ts` and `auth/tokens.ts`",
          "children": [
            { "content": "Session handler owns cookie lifecycle" },
            { "content": "Token handler owns JWT encode/decode" }
          ]
        }
      ]
    }
  ]
}
```

## Task Entry

```json
{
  "page": "Journal/2026-03-10",
  "blocks": [
    {
      "content": "TODO Write unit tests for PaymentService #claude-managed #task\ntype:: task\npriority:: A\nproject:: [[payment-refactor]]",
      "children": [
        { "content": "Cover happy path, declined card, and network timeout scenarios" },
        { "content": "Use existing mock in `tests/mocks/stripe.ts`" }
      ]
    }
  ]
}
```

## Code Snippet

```json
{
  "page": "Journal/2026-03-10",
  "blocks": [
    {
      "content": "TypeScript utility: debounce function #claude-managed #code #typescript\ntype:: code\nlanguage:: typescript\nsource:: claude-code",
      "children": [
        {
          "content": "```typescript\nfunction debounce<T extends (...args: unknown[]) => void>(\n  fn: T,\n  delay: number\n): (...args: Parameters<T>) => void {\n  let timer: ReturnType<typeof setTimeout>;\n  return (...args) => {\n    clearTimeout(timer);\n    timer = setTimeout(() => fn(...args), delay);\n  };\n}\n```"
        }
      ]
    }
  ]
}
```

## Meeting Note

```json
{
  "page": "Journal/2026-03-10",
  "blocks": [
    {
      "content": "Meeting: Q1 planning sync #claude-managed #meeting\ntype:: meeting\ndate:: [[2026-03-10]]\nattendees:: [[Alice]], [[Bob]], [[Carol]]",
      "children": [
        { "content": "Agreed to prioritize auth refactor before new feature work" },
        { "content": "Action items",
          "children": [
            { "content": "TODO Alice to review auth module by EOW" },
            { "content": "TODO Bob to draft technical spec for new payment flow" }
          ]
        },
        { "content": "Next meeting: [[2026-03-17]]" }
      ]
    }
  ]
}
```

## Insight / Learning

```json
{
  "page": "Journal/2026-03-10",
  "blocks": [
    {
      "content": "Insight: MCP tool availability is checked per-session #claude-managed #insight #mcp\ntype:: insight\nsource:: claude-code",
      "children": [
        { "content": "MCP servers listed in .mcp.json only connect when Claude Code session starts" },
        { "content": "Changing .mcp.json requires a session restart to take effect" }
      ]
    }
  ]
}
```

## Named Page (not journal)

Capture to a specific named page instead of today's journal:

```json
{
  "page": "Projects/logseq-plugin",
  "blocks": [
    {
      "content": "Plugin architecture decisions #claude-managed #note #architecture\ntype:: note\nsource:: claude-code",
      "children": [
        { "content": "Using upsert_blocks for all writes ensures idempotency" },
        { "content": "SessionStart hook checks MCP availability silently" }
      ]
    }
  ]
}
```

## Multiple Blocks in One Call

Batch multiple independent entries in a single `upsert_blocks` call:

```json
{
  "page": "Journal/2026-03-10",
  "blocks": [
    {
      "content": "TODO Review PR #142 #claude-managed #task\ntype:: task\npriority:: B"
    },
    {
      "content": "TODO Update CHANGELOG for v1.2.0 #claude-managed #task\ntype:: task\npriority:: C"
    }
  ]
}
```

## Work Log Entry (section exists)

Append a work item under an existing `## In Progress` section:

```json
{
  "page": "2026/03/11",
  "blocks": [
    {
      "content": "[[JIRA/PROJ-123]] investigating auth bug #claude-managed #work-log [09:32]"
    }
  ]
}
```

Note: when the section already exists, the item is appended as a child of that heading block. The `page` and `blocks` shown here represent the child block payload; the actual call uses the section block as parent.

## Work Log Entry (section does not exist)

Create `## In Progress` heading and first work item in a single call:

```json
{
  "page": "2026/03/11",
  "blocks": [
    {
      "content": "## In Progress",
      "children": [
        { "content": "[[JIRA/PROJ-123]] investigating auth bug #claude-managed #work-log [09:32]" }
      ]
    }
  ]
}
```

## Work Page: JIRA ticket

```json
{
  "page": "JIRA/PROJ-123",
  "blocks": [
    {
      "content": "JIRA/PROJ-123 #claude-managed #jira\nstatus:: in-progress\nsprint::\nrepo::\nprs::"
    }
  ]
}
```

## Work Page: Pull Request

```json
{
  "page": "PR/myrepo/42",
  "blocks": [
    {
      "content": "PR/myrepo/42 #claude-managed #pr\nstatus:: open\njira::\nrepo:: [[Repo/myrepo]]\nopened:: [[2026-03-12]]\nmerged::"
    }
  ]
}
```

## Work Page: Repo/Service

```json
{
  "page": "Repo/my-service",
  "blocks": [
    {
      "content": "Repo/my-service #claude-managed #repo\nteam::\nstack::"
    }
  ]
}
```
