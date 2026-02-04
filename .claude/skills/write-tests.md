---
name: write-tests
description: Use when writing test cases - ensures robust, comprehensive tests following best practices and proper structure
---

# Writing Robust Tests

## Principles

1. **Test behavior, not implementation** - Verify what code does, not how
2. **One concept per test** - Each test verifies one thing
3. **Readable names** - Describe scenario and expectation
4. **Arrange-Act-Assert** - Clear structure

## Test Structure (RSpec)

```ruby
describe "ClassName" do
  describe "#method_name" do
    context "when [condition]" do
      it "does [expected behavior]" do
        # Arrange - setup
        # Act - call method
        # Assert - verify
      end
    end
  end
end
```

## What to Test

| Category | Examples |
|----------|----------|
| Happy path | Normal expected usage |
| Edge cases | Empty, nil, boundaries |
| Error cases | Invalid input, failures |
| Security | Auth, input validation |

## Naming Convention

```ruby
# Format: "verb_outcome_when_condition"
it "returns empty array when no jobs exist"
it "raises error when job_id is nil"
it "filters by status when status param provided"
```

## Test Quality Checklist

- [ ] Tests are independent (no shared mutable state)
- [ ] Tests are deterministic (same result every run)
- [ ] Tests are fast (mock external services)
- [ ] Tests are readable (clear setup, obvious assertions)
- [ ] Critical paths covered
- [ ] Edge cases covered
- [ ] Error handling verified

## Anti-patterns

| Don't | Do Instead |
|-------|------------|
| Test private methods | Test public interface |
| Depend on test order | Independent tests |
| Use sleep for timing | Use proper waiting |
| Hardcode IDs | Use factories |
| Test framework code | Test your code |

## Coverage Goals

- All public methods
- All conditional branches
- All error paths
- Boundary conditions
