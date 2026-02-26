# Multi Review

A Claude Code skill that discovers available review agents and runs them in
parallel, validates the findings, and produces an aggregated summary.

## Why Use This?

- **Multiple perspectives** catch more issues than a single review
- **Auto-discovery** - works with whatever review plugins you have installed
- **Validation phase** filters out false positives
- **Aggregated summary** shows agreement between reviewers
- **No auto-posting** - you control what gets posted to the PR

## Quick Start

```bash
# Review current PR
claude "Run multi-review"

# Review specific PR
claude "Run multi-review --pr 123"

# Review with higher confidence threshold
claude "Run multi-review --pr 123 --confidence 80"
```

## Suggested Review Plugins

This skill works with any review plugins you have installed. Here are some
recommended plugins to get the most out of parallel reviews:

```bash
# General code review (from Anthropic's official plugins)
claude plugin install code-review@claude-plugins-official

# Multi-agent PR review with error handling and security analysis
claude plugin install pr-review-toolkit@claude-plugins-official

# CodeRabbit AI-powered code review
claude plugin install coderabbit@claude-plugins-official

# Security-focused review (from Anthropic's official plugins)
claude plugin install superpowers@claude-plugins-official
```

You don't need all of them — the skill will use whatever is available. Even a
single review plugin is enough, though two or more give better coverage through
cross-validation.

## How It Works

The skill automatically discovers review-related agent types available in your
environment (e.g., `coderabbit:code-reviewer`, `pr-review-toolkit:code-reviewer`,
`superpowers:code-reviewer`) and runs them in parallel (up to `--max-reviewers`,
default 3).

```text
┌─────────────────────────────────────────────────────────────────────┐
│  Phase 0: Discover available review agents                          │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Phase 1: Run discovered reviews in PARALLEL                        │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐                │
│  │ Reviewer 1   │ │ Reviewer 2   │ │ Reviewer 3   │                │
│  └──────────────┘ └──────────────┘ └──────────────┘                │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Phase 2: Validate findings in PARALLEL                             │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐                │
│  │ Validator 1  │ │ Validator 2  │ │ Validator 3  │                │
│  └──────────────┘ └──────────────┘ └──────────────┘                │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Phase 3: Aggregate & deduplicate into final summary                │
└─────────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Post-review: Action menu (view, fix, create issues, etc.)          │
└─────────────────────────────────────────────────────────────────────┘
```

## Output Files

All results are saved to `.multi-reviews/<timestamp>/`:

| File                          | Description                             |
| ----------------------------- | --------------------------------------- |
| `review-<reviewer>.md`        | Raw findings from each review agent     |
| `validated-<reviewer>.md`     | Filtered findings per reviewer          |
| `pr-review-summary.md`       | **Final aggregated report**             |

## Options

### Input Options

| Option            | Description                       |
| ----------------- | --------------------------------- |
| `--pr <number>`   | Review a specific PR              |
| `--branch <name>` | Review branch changes vs main     |
| `--files <paths>` | Review specific files only        |
| `--full-context`  | Review entire files, not just diff|

### Configuration

| Option              | Default       | Description                      |
| ------------------- | ------------- | -------------------------------- |
| `--output-dir`      | `./.multi-reviews/` | Where to save results            |
| `--confidence`      | `70`          | Min confidence to include (0-100)|
| `--max-reviewers`   | `3`           | Max review agents to run         |
| `--skip-validation` | `false`       | Skip Phase 2 for faster results  |

## Examples

```bash
# Basic - auto-detects PR from current branch
claude "Run multi-review"

# Specific PR with custom output location
claude "Run multi-review --pr 456 --output-dir ./reviews"

# Higher confidence threshold (fewer but more certain issues)
claude "Run multi-review --confidence 85"

# Quick review - skip validation phase
claude "Run multi-review --skip-validation"

# Run all discovered reviewers (no practical cap)
claude "Run multi-review --max-reviewers 10"

# Review specific files
claude "Run multi-review --files src/auth.ts src/login.ts"
```

## Understanding the Summary

The final `pr-review-summary.md` includes:

### Issue Categories

- **Critical Issues** - Must fix before merging (includes security vulns)
- **Important Issues** - Should fix
- **Suggestions** - Nice to have improvements

### Source Column

Shows which reviewer(s) found each issue. Issues found by multiple reviewers
have higher confidence.

### Agreement Analysis

Shows how much the reviewers agreed:

- High agreement = high confidence in findings
- Issues found by multiple reviewers are more likely real

## Post-Review Actions

After the review completes, you'll see an action menu:

1. **View** - Open the summary
2. **Fix** - Generate fix suggestions for critical issues
3. **Issues** - Create GitHub issues for tracking
4. **Comment** - Post summary to PR (requires your approval)
5. **Rerun** - Re-run on specific files
6. **Done** - Exit

## FAQ

**Q: Will this post comments to my PR automatically?**
A: No. All output goes to markdown files. You decide what to post.

**Q: What review agents does it use?**
A: It auto-discovers available review agent types in your environment. Install
any review plugins you like and this skill will use them.

**Q: What if one reviewer fails?**
A: The skill continues with available results and warns you.

**Q: How do I adjust sensitivity?**
A: Use `--confidence`. Higher values (80-90) = fewer but more certain
issues. Lower values (50-60) = more issues but more false positives.

## Files

When installed as a plugin, files are located within the plugin directory:

```text
<plugin-dir>/skills/multi-review/
├── SKILL.md   # Instructions for Claude (technical)
└── README.md  # This file (human documentation)
```

