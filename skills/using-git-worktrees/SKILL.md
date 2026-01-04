---
name: using-git-worktrees
description: Use when working on multiple features, or user mentions "worktree", "parallel branches", "branches paralelas", "multiple features". Manages parallel development.
---

# Using Git Worktrees

Manages parallel development branches using Git worktrees for isolated, concurrent work.

## When to Use

- Working on multiple features simultaneously
- Need to switch context quickly
- Comparing implementations
- User says: worktree, parallel branches, multiple features
- NOT when: simple branch switching suffices

## What is a Worktree?

```
Normal Git:
  repo/
    └── .git/
    └── [one branch at a time]

With Worktrees:
  repo/                     ← main branch
    └── .git/
  repo-feature-a/           ← feature-a branch (linked)
  repo-feature-b/           ← feature-b branch (linked)
```

**Key benefit**: Each worktree = separate directory with different branch, sharing same .git history.

## Essential Commands

### Create Worktree

```bash
# From main repo, create worktree for feature branch
git worktree add ../project-feature-x feature/x

# Create worktree with new branch
git worktree add -b feature/y ../project-feature-y

# Create from specific commit/tag
git worktree add ../project-hotfix v2.1.0
```

### List Worktrees

```bash
git worktree list
# Output:
# /path/to/repo           abc1234 [main]
# /path/to/repo-feature-x def5678 [feature/x]
# /path/to/repo-feature-y ghi9012 [feature/y]
```

### Remove Worktree

```bash
# Remove worktree (branch stays)
git worktree remove ../project-feature-x

# Force remove if uncommitted changes
git worktree remove --force ../project-feature-x

# Clean up stale worktree references
git worktree prune
```

## Workflow: Parallel Feature Development

```markdown
## Setup

### Main Repository
/work/my-project/        ← main branch (stable)

### Active Worktrees
/work/my-project-auth/   ← feature/authentication
/work/my-project-api/    ← feature/api-v2
/work/my-project-ui/     ← feature/new-dashboard

## Daily Workflow

### Morning: Pick up feature/auth
cd /work/my-project-auth
git pull origin feature/authentication
[work on auth]

### Interruption: Urgent API fix needed
cd /work/my-project-api
git pull origin feature/api-v2
[fix urgent issue]
git commit && git push

### Back to auth
cd /work/my-project-auth
[continue where you left off]
```

## Worktree Naming Convention

```
{project}-{feature-short-name}/

Examples:
- impetos-auth/
- impetos-api-v2/
- impetos-dashboard/
- impetos-hotfix-123/
```

## Worktree Management Template

```markdown
# Worktree Status: [Project]

## Active Worktrees

| Path | Branch | Status | Last Updated |
|------|--------|--------|--------------|
| `/work/project/` | main | ✅ Stable | - |
| `/work/project-auth/` | feature/auth | 🔄 In Progress | Today |
| `/work/project-api/` | feature/api | ⏸️ Paused | 2 days ago |
| `/work/project-fix/` | hotfix/123 | ✅ Ready for PR | Today |

## Commands

### Create new worktree
```bash
git worktree add -b feature/[name] ../project-[name]
```

### Clean up completed work
```bash
git worktree remove ../project-fix
git branch -d hotfix/123  # if merged
```

### Prune stale references
```bash
git worktree prune
```
```

## Best Practices

### DO

```markdown
✓ Use consistent naming (project-feature/)
✓ Keep main worktree clean (only main branch)
✓ Remove worktrees after merging
✓ Run `git worktree prune` periodically
✓ Use absolute paths in scripts
```

### DON'T

```markdown
✗ Create worktrees inside repo directory
✗ Delete worktree directory manually (use git worktree remove)
✗ Have too many active worktrees (cognitive overhead)
✗ Forget to push before switching worktrees
```

## Common Scenarios

### Scenario 1: Urgent Hotfix

```bash
# You're in feature branch, urgent fix needed
cd /work/project
git worktree add -b hotfix/urgent ../project-urgent main

cd ../project-urgent
# Make fix
git commit -m "fix: urgent production issue"
git push origin hotfix/urgent
# Create PR, merge

# Cleanup
cd ../project
git worktree remove ../project-urgent
```

### Scenario 2: Compare Implementations

```bash
# Create worktrees for each approach
git worktree add -b experiment/approach-a ../project-approach-a
git worktree add -b experiment/approach-b ../project-approach-b

# Implement each approach in parallel
# Compare results
# Keep winner, remove loser
```

### Scenario 3: Code Review with Context

```bash
# Reviewer: Create worktree for PR branch
git worktree add ../project-review origin/feature/their-branch

# Review code in IDE
cd ../project-review
# Run tests, explore code

# Clean up after review
git worktree remove ../project-review
```

## For AI Agent Development

```markdown
## Agent Development Worktrees

### Recommended Structure
/work/ai-agents/           ← main (stable agents)
/work/ai-agents-new/       ← feature/new-agent
/work/ai-agents-refactor/  ← feature/agent-refactor
/work/ai-agents-test/      ← experiment/new-framework

### Why Worktrees for Agents
- Test new agent without breaking stable version
- A/B test agent improvements
- Isolate prompt experiments
- Keep production agent always runnable
```

## Output Format

When managing worktrees:

```markdown
## Worktree Operation: [Action]

### Current State
```bash
git worktree list
```
[Output]

### Action Taken
[What was done]

### New State
| Worktree | Branch | Purpose |
|----------|--------|---------|
| ... | ... | ... |

### Next Steps
- [ ] [Next action]
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "already checked out" | Branch is in another worktree |
| "not a git repository" | Wrong directory, cd to main repo |
| Stale worktree | `git worktree prune` |
| Can't delete | Use `--force` or commit/stash changes |

## Common Mistakes

- Creating worktree inside repo (path issues)
- Forgetting which worktree you're in
- Not cleaning up after merge
- Deleting directory without `git worktree remove`
- Too many active worktrees (cognitive overload)
- Not syncing changes between worktrees
