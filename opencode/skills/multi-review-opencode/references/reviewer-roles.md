# Reviewer Roles and Output Contracts

## 1. Specialist Roles Catalog

### correctness
- Focus: Logic bugs, off-by-one errors, null/undefined safety, race conditions, type invariants, unhandled edge cases.
- Category: `deep` or `unspecified-high`

### security
- Focus: Input validation, authentication/authorization boundaries, secrets, injection vectors, unsafe deserialization, SSRF.
- Category: `deep` or `security-research`

### test-coverage
- Focus: Missing test cases for new paths, brittle assertions, untested error branches, regression risks.
- Category: `deep` or `unspecified-high`

### architecture-perf
- Focus: Resource leaks, inefficient database/network calls, blocking operations on event loops, modularity regressions.
- Category: `deep` or `unspecified-high`

## 2. Reviewer Prompt Contract

Every spawned reviewer subagent must format findings as an array of items adhering to:

```json
[
  {
    "file": "path/to/file.ext",
    "line": 123,
    "severity": "CRITICAL" | "IMPORTANT" | "SUGGESTION",
    "confidence": 0-100,
    "title": "Short title",
    "description": "Clear explanation of the issue",
    "evidence": "Code quote or trace explaining why this is an issue",
    "suggested_fix": "Concrete guidance or snippet"
  }
]
```
