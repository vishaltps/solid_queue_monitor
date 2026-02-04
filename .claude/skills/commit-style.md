---
name: commit-style
description: Use when creating git commits - ensures consistent commit message format and atomic commits
---

# Commit Style Guide

## Format

```
<type>: <subject>

[optional body]
```

## Types

| Type | Use For |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring (no behavior change) |
| `docs` | Documentation only |
| `test` | Adding or fixing tests |
| `chore` | Maintenance (deps, configs) |
| `perf` | Performance improvement |
| `style` | Formatting, whitespace |

## Rules

1. **Subject**: Max 50 chars, imperative mood ("add" not "added")
2. **Body**: Explain "what" and "why", not "how"
3. **Atomic**: One logical change per commit

## Examples

```
feat: add full-text search for jobs

Implements search across job class names and arguments.
Uses SQL LIKE with proper escaping.
```

```
fix: prevent N+1 query in jobs index

Eager load queue records to reduce queries from O(n) to O(1).
```

```
refactor: extract job filtering to query object
```

## Anti-patterns

- `fix: stuff` (vague)
- `updated files` (meaningless)
- `WIP` on branches to be merged
- Multiple unrelated changes in one commit
