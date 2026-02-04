---
name: review-code
description: Use when completing a feature or before creating PR - comprehensive code review checklist for self-review or peer review
---

# Code Review Checklist

## 1. Correctness

- [ ] Does the code do what it's supposed to do?
- [ ] Are edge cases handled?
- [ ] Are there off-by-one errors?
- [ ] Is error handling appropriate?

## 2. Security

- [ ] SQL injection vulnerabilities?
- [ ] XSS vulnerabilities?
- [ ] Sensitive data exposure in logs/errors?
- [ ] Authorization checks in place?

## 3. Performance

- [ ] N+1 queries?
- [ ] Unnecessary database calls?
- [ ] Expensive operations in loops?
- [ ] Missing indexes for queries?

## 4. Maintainability

- [ ] Is the code readable without comments?
- [ ] Are names descriptive and consistent?
- [ ] Is there unnecessary complexity?
- [ ] Will this be easy to modify?

## 5. Consistency

- [ ] Follows existing codebase patterns?
- [ ] Matches naming conventions?
- [ ] Similar to how other features are built?

## 6. Testing

- [ ] Tests cover happy path?
- [ ] Tests cover edge cases?
- [ ] Tests cover error scenarios?
- [ ] Tests are readable and maintainable?

## Common Issues to Watch

| Issue | Look For |
|-------|----------|
| N+1 queries | Loops that trigger DB calls |
| Missing validation | User input going directly to DB |
| Error swallowing | Empty rescue blocks |
| Hardcoded values | Magic numbers/strings |
| Dead code | Unused methods/variables |

## After Review

If issues found:
1. Fix the issues
2. Re-run this checklist
3. Only proceed when all checks pass
