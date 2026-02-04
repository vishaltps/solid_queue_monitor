# Project Instructions

## Git Workflow

### Protected Branches
The following branches are protected and must **never** receive direct commits or pushes:
- `main`
- `master`
- `dev`
- `staging`

### Branch Creation Rules
- **Always create a new branch** before starting work on any feature, task, or bug fix
- **Always branch from `main` or `master`** (whichever exists in the repo)
- Before creating a branch, ensure you're on the base branch and it's up to date
- Use descriptive branch names (e.g., `feature/add-search`, `fix/login-bug`)

### Worktree Directory
- Use `.worktrees/` for git worktrees (already in .gitignore)

## Planning Mode

- **Always use plan mode** for complex tasks before writing any code
- Complex tasks: new features, significant refactors, multi-file changes, architectural decisions

## Project Skills

Custom workflows available in `.claude/skills/`:

| Skill | When to Use |
|-------|-------------|
| `principal-thinking` | Starting any feature or significant change |
| `commit-style` | Creating git commits |
| `create-pr` | Creating pull requests |
| `review-code` | Before completing a feature or creating PR |
| `write-tests` | Writing test cases |
| `apply-solid` | Designing classes or refactoring |

**Invoke with:** `/skill-name` or reference during work

## Tech Stack

- **Ruby/Rails:** Follow Rails conventions, use ActiveRecord properly
- **JavaScript:** Modern ES6+ patterns
- **CSS:** Follow existing naming conventions
