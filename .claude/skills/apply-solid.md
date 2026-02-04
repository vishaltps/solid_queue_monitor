---
name: apply-solid
description: Use when designing classes or refactoring - applies SOLID principles pragmatically, only when there's a clear benefit
---

# SOLID Principles (Pragmatic Application)

## Core Rule

**Apply SOLID only when there's a clear, immediate benefit. Don't over-engineer.**

## When to Apply

| Principle | Apply When | Skip When |
|-----------|------------|-----------|
| **S**ingle Responsibility | Class doing 3+ unrelated things | Simple class, cohesive methods |
| **O**pen/Closed | Behavior extended frequently | One-off, unlikely to change |
| **L**iskov Substitution | Building class hierarchies | No inheritance |
| **I**nterface Segregation | Large interfaces force unused deps | Already small and focused |
| **D**ependency Inversion | Need to swap implementations | Dependency is stable |

## Decision Framework

Before applying, ask:

1. Is there a **real problem NOW**?
2. Will this make code **easier to understand**?
3. Is abstraction worth the **added complexity**?
4. Would a **simpler solution** work?

**If unsure, keep it simple. Refactor when real need arises.**

## Examples

### Single Responsibility - APPLY

```ruby
# BAD: Controller doing everything
class JobsController
  def index
    # querying + filtering + sorting +
    # pagination + formatting + caching
  end
end

# GOOD: Extract query logic
class JobsController
  def index
    @jobs = JobQuery.new(params).execute
  end
end
```

### Single Responsibility - DON'T APPLY

```ruby
# This is FINE - don't over-split
class Job
  def formatted_created_at
    created_at.strftime("%Y-%m-%d")
  end

  def status_label
    status.humanize
  end
end
```

## Red Flags (Over-engineering)

- Creating abstraction for single use case
- Building for "future requirements"
- Interface with one implementation
- Factory that creates one type
- 3 similar lines → premature abstraction

## The Test

> "If I needed to change this, would SOLID make it easier or harder?"

Easier → Apply it
Harder or same → Keep it simple
