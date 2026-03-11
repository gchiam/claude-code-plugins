# logseq

A Claude Code plugin for capturing notes, tasks, and insights directly into [Logseq](https://logseq.com) from your Claude conversations, powered by the [graphthulhu](https://github.com/skridlevsky/graphthulhu) MCP server.

## Features

- **Three capture commands**: structured, quick, and last-response capture
- **Auto-detects setup issues** at session start with inline instructions
- **Guided setup agent** for graphthulhu installation and Logseq API configuration
- **Consistent block structure**: properties, tags, and nesting conventions
- **Always tagged `#claude-managed`** for easy filtering in Logseq

## Prerequisites

- [Logseq](https://logseq.com) installed and open
- [graphthulhu](https://github.com/skridlevsky/graphthulhu) binary on your PATH
- Logseq HTTP API enabled with a token (see Setup below)
- `LOGSEQ_API_TOKEN` environment variable set

## Setup

Run the setup agent for guided configuration:

```
Ask Claude: "help me set up logseq"
```

Or follow manual steps:

### 1. Install graphthulhu

```bash
go install github.com/skridlevsky/graphthulhu@latest
export PATH="$PATH:$(go env GOPATH)/bin"
```

### 2. Enable Logseq HTTP API

1. Open Logseq → Settings → Features → enable **"HTTP APIs server"**
2. Click the API icon → Start Server → Create Token
3. Copy the token

### 3. Set Environment Variable

```bash
export LOGSEQ_API_TOKEN="your-token-here"
# Add to ~/.zshrc or ~/.bashrc to persist
```

## Commands

| Command | Description |
|---------|-------------|
| `/logseq:capture [page]` | Structured capture — prompts for type, title, content, tags |
| `/logseq:quick-capture <text>` | Instant capture of raw text to today's journal |
| `/logseq:capture-last [title]` | Capture most recent Claude response to today's journal |

## Project Settings

Create `.claude/logseq.local.md` to customize defaults:

```markdown
---
default_page: ""
api_url: "http://127.0.0.1:12315"
default_tags: []
---
```

Add `.claude/*.local.md` to `.gitignore` to keep personal settings private.

## Block Conventions

All entries follow this structure:

```
- Entry title #claude-managed #tag
  type:: note
  source:: claude-code
  - Content block
    - Nested detail
```

Entry types: `note`, `task`, `code`, `meeting`, `insight`

Tasks use `TODO` prefix: `TODO Task description #claude-managed #task`
