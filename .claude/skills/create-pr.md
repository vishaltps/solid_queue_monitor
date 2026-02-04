---
name: create-pr
description: Use when creating a pull request - follows PR template with summary, problem, solution, and testing checklist
---

# Create Pull Request

## PR Template

```markdown
## Summary
<!-- 1-3 bullet points: what does this PR do? -->

## Problem
<!-- What issue does this address? Link if applicable -->

## Solution
<!-- How does this solve it? Key decisions made -->

## Changes
<!-- List main changes -->
-
-

## Testing
<!-- How was this tested? -->
- [ ] Unit tests added/updated
- [ ] Manual testing completed
- [ ] Edge cases considered

## Screenshots (if UI changes)
<!-- Before/after if applicable -->

## Checklist
- [ ] Code follows project patterns
- [ ] Self-review completed
- [ ] Tests pass
- [ ] No debug statements left
```

## Before Creating PR

1. Ensure all commits follow commit-style
2. Rebase on latest main if needed
3. Run full test suite locally
4. Self-review all changes (`git diff main...HEAD`)

## PR Title

- Keep under 70 chars
- Use same format as commits: `type: description`
- Examples:
  - `feat: add job search functionality`
  - `fix: resolve N+1 query in workers index`

## Command

```bash
gh pr create --title "type: description" --body "$(cat <<'EOF'
## Summary
...
EOF
)"
```
