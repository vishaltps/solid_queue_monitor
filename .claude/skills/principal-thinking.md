---
name: principal-thinking
description: Use when starting any feature, refactor, or significant code change - applies principal engineer level analysis before implementation
---

# Principal Engineer Thinking

## Overview

Think like a principal engineer: understand deeply before acting, consider trade-offs, anticipate problems.

## Before Writing Code

1. **Understand the "why"**
   - What problem are we solving?
   - Why does it matter to users?
   - What happens if we don't solve it?

2. **Explore existing solutions**
   - How is this handled elsewhere in the codebase?
   - Are there gems/libraries that solve this?
   - What patterns are already established?

3. **Consider trade-offs**
   - What are the options?
   - Pros/cons of each?
   - Document the decision and reasoning

4. **Think about scale**
   - Will this work with 10x data?
   - What are the performance implications?
   - Are there N+1 queries or memory concerns?

5. **Identify risks and edge cases**
   - What could go wrong?
   - What are the boundary conditions?
   - How do we handle failures gracefully?

## During Implementation

| Principle | Question to Ask |
|-----------|-----------------|
| Simplicity | Is there a simpler way? |
| Readability | Will someone understand this in 6 months? |
| Failure handling | What happens when this fails? |
| Backwards compatibility | Does this break existing functionality? |
| Observability | Can we debug this in production? |

## After Implementation

- [ ] Would I approve this in a code review?
- [ ] Is the "why" documented for non-obvious decisions?
- [ ] Is this easy to modify later?
- [ ] Did I add unnecessary complexity?
