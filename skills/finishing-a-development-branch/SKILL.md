---
name: finishing-a-development-branch
description: Use when feature is complete, or user mentions "merge", "PR", "finalizar branch", "terminar feature", "ready to merge". Handles merge/PR workflow.
---

# Finishing a Development Branch

Complete workflow for merging a feature branch, creating PRs, and cleanup.

## When to Use

- Feature is complete and tested
- Ready to merge to main
- User says: merge, PR, finalizar, terminar feature
- After verification-before-completion
- NOT when: still developing, tests failing

## The Finish Workflow

```
┌─────────────────────────────────────────────────┐
│  1. PRE-MERGE CHECKS                            │
│     Everything ready?                           │
├─────────────────────────────────────────────────┤
│  2. UPDATE BRANCH                               │
│     Sync with main                              │
├─────────────────────────────────────────────────┤
│  3. CREATE PR                                   │
│     Request review                              │
├─────────────────────────────────────────────────┤
│  4. MERGE                                       │
│     Complete the merge                          │
├─────────────────────────────────────────────────┤
│  5. CLEANUP                                     │
│     Remove branch, worktrees                    │
└─────────────────────────────────────────────────┘
```

## Step 1: Pre-Merge Checklist

```markdown
## Pre-Merge Checklist

### Code Quality
- [ ] All tests pass locally
- [ ] No linting errors
- [ ] No TypeScript errors
- [ ] Self-reviewed changes

### Git Status
- [ ] All changes committed
- [ ] No stray files
- [ ] Commits are clean and atomic

### Documentation
- [ ] README updated if needed
- [ ] API docs updated if needed
- [ ] CHANGELOG updated

### Dependencies
- [ ] No unintended dependency changes
- [ ] Lock file committed
- [ ] All new dependencies justified
```

## Step 2: Update Branch

```bash
# Fetch latest from remote
git fetch origin

# Rebase on main (preferred) or merge
git rebase origin/main

# OR merge if team prefers
git merge origin/main

# Resolve any conflicts
# Test again after rebase/merge
npm test  # or pytest, etc.

# Force push if rebased
git push --force-with-lease origin feature/my-branch
```

### Handling Conflicts

```markdown
## Conflict Resolution

### Files with conflicts
- `src/config.ts` - Both modified DATABASE_URL
- `src/api/users.ts` - New function in both branches

### Resolution Strategy
1. Keep our changes for: [list]
2. Keep theirs for: [list]
3. Manual merge for: [list]

### After Resolution
```bash
git add .
git rebase --continue
npm test
```
```

## Step 3: Create PR

### PR Template

```markdown
## Summary
[2-3 sentences explaining the change]

## Changes
- Added [feature A]
- Fixed [bug B]
- Refactored [component C]

## Type
- [x] Feature
- [ ] Bug fix
- [ ] Refactor
- [ ] Documentation

## Testing
- [x] Unit tests added
- [x] Integration tests added
- [x] Manual testing completed

### How to Test
1. [Step 1]
2. [Step 2]
3. Expected: [result]

## Screenshots (if UI changes)
| Before | After |
|--------|-------|
| [img] | [img] |

## Checklist
- [x] Tests pass
- [x] Self-reviewed
- [x] Documentation updated
- [x] No breaking changes (or documented)

## Related
- Closes #[issue-number]
- Related to #[issue-number]
```

### GitHub CLI

```bash
# Create PR
gh pr create --title "feat: add user authentication" \
  --body "$(cat pr-description.md)" \
  --base main \
  --head feature/auth

# Or interactive
gh pr create

# Add reviewers
gh pr edit --add-reviewer username1,username2
```

## Step 4: Merge

### Merge Options

| Method | When to Use |
|--------|-------------|
| Squash & Merge | Many small commits, want clean history |
| Rebase & Merge | Commits are clean, want linear history |
| Merge Commit | Want to preserve all commits, need merge record |

### Via GitHub CLI

```bash
# Squash and merge (most common)
gh pr merge --squash

# Rebase and merge
gh pr merge --rebase

# Regular merge
gh pr merge --merge

# Delete branch after merge
gh pr merge --squash --delete-branch
```

### Via Git (if no PR)

```bash
# Switch to main
git checkout main
git pull origin main

# Merge feature
git merge --squash feature/my-branch
git commit -m "feat: add user authentication"

# Push
git push origin main
```

## Step 5: Cleanup

### Delete Remote Branch

```bash
# Via gh
gh pr merge --delete-branch

# Via git
git push origin --delete feature/my-branch
```

### Delete Local Branch

```bash
# Switch to main first
git checkout main

# Delete local branch
git branch -d feature/my-branch

# Force delete if needed
git branch -D feature/my-branch
```

### Remove Worktree (if used)

```bash
git worktree remove ../project-feature
git worktree prune
```

### Full Cleanup Script

```bash
#!/bin/bash
BRANCH="feature/my-branch"
WORKTREE="../project-feature"

# Merge via GitHub
gh pr merge --squash --delete-branch

# Remove worktree if exists
if [ -d "$WORKTREE" ]; then
    git worktree remove "$WORKTREE"
fi

# Cleanup local
git checkout main
git pull origin main
git branch -d "$BRANCH" 2>/dev/null
git remote prune origin
git worktree prune
```

## Finish Workflow Template

```markdown
# Branch Finish: [feature/branch-name]

## Pre-Merge Status
- [x] Tests pass
- [x] Self-reviewed
- [x] Rebased on main
- [x] Conflicts resolved: None

## PR Details
- **Title**: feat: [description]
- **Link**: [PR URL]
- **Reviewers**: @[names]

## Merge Plan
- **Method**: Squash & Merge
- **Target**: main
- **Delete branch**: Yes

## Post-Merge Cleanup
- [ ] Remote branch deleted
- [ ] Local branch deleted
- [ ] Worktree removed (if applicable)
- [ ] Related issues closed

## Verification
- [ ] Change deployed to staging
- [ ] Smoke test passed
```

## Output Format

When finishing a branch:

```markdown
## Branch Finish: feature/[name]

### Step 1: Pre-Check ✅
All checks passed

### Step 2: Updated
- Rebased on main
- No conflicts
- Tests pass

### Step 3: PR Created
- URL: [link]
- Reviewers assigned

### Step 4: Merged
- Method: Squash & Merge
- Commit: abc1234

### Step 5: Cleanup
- [x] Remote branch deleted
- [x] Local branch deleted
- [x] Worktree removed

### Done!
Feature successfully merged to main.
```

## Common Mistakes

- Merging without latest main (conflicts in main)
- Not running tests after rebase
- Forgetting to delete branches (clutter)
- Leaving worktrees (disk space)
- Not closing related issues
- Skipping PR review for "small" changes
