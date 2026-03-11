# Logseq Plugin Setup Guide

## graphthulhu Installation

graphthulhu is a Go binary that serves as the MCP server bridging Claude Code to Logseq.

### Option 1: Go Install (Recommended)

```bash
go install github.com/skridlevsky/graphthulhu@latest
```

Requires Go 1.21+. The binary installs to `$GOPATH/bin` (typically `~/go/bin`).
Ensure `~/go/bin` is in your `PATH`:

```bash
# Add to ~/.zshrc or ~/.bashrc
export PATH="$PATH:$(go env GOPATH)/bin"
```

### Option 2: Download Binary

1. Go to https://github.com/skridlevsky/graphthulhu/releases
2. Download the binary for your platform (macOS arm64, macOS amd64, Linux amd64)
3. Move to a directory in your PATH:
   ```bash
   chmod +x graphthulhu
   mv graphthulhu /usr/local/bin/
   ```

### Verify Installation

```bash
graphthulhu --version
```

---

## Enabling Logseq HTTP API

The graphthulhu MCP server communicates with Logseq via its built-in HTTP API. This must be enabled manually in Logseq.

**Steps:**

1. Open Logseq
2. Go to **Settings** (gear icon) → **Features**
3. Enable **"HTTP APIs server"** toggle
4. A new API icon appears in the left toolbar — click it
5. Click **"Start Server"**
6. Click **"Create Token"** — copy the generated token immediately (it won't be shown again)

The API runs at `http://127.0.0.1:12315` by default.

**Verify the API is running:**

```bash
curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $LOGSEQ_API_TOKEN" http://127.0.0.1:12315/api
```

Expected response: `404` (endpoint doesn't exist but auth passed) — this confirms the server is running and the token is valid. A `401` means the token is incorrect. Connection refused means the server isn't started.

---

## MCP Configuration

The logseq plugin's `.mcp.json` configures graphthulhu automatically. You need to set two environment variables before starting Claude Code:

```bash
export LOGSEQ_API_TOKEN="your-token-from-logseq"
# LOGSEQ_API_URL defaults to http://127.0.0.1:12315 if not set
```

Or add them to your shell profile (`~/.zshrc` or `~/.bashrc`).

---

## Plugin Settings File

Create `.claude/logseq.local.md` in your project to customize plugin behavior:

```markdown
---
default_page: "Journal"
api_url: "http://127.0.0.1:12315"
default_tags: ["work", "project-alpha"]
---
```

**Fields:**

| Field | Default | Description |
|-------|---------|-------------|
| `default_page` | Today's journal (`Journal/YYYY-MM-DD`) | Override default capture target |
| `api_url` | `http://127.0.0.1:12315` | Custom Logseq API URL |
| `default_tags` | `[]` | Additional tags added to every entry |

Add `.claude/*.local.md` to `.gitignore` to keep personal settings out of version control.

---

## Verifying graphthulhu MCP Connection

In Claude Code, run `/mcp` to list connected MCP servers. Look for `graphthulhu` in the list with its available tools including `upsert_blocks`, `get_page`, `search`, etc.

If graphthulhu does not appear:
1. Verify `LOGSEQ_API_TOKEN` is set in your environment
2. Verify Logseq is open with HTTP API server running
3. Restart Claude Code session to reload MCP servers
