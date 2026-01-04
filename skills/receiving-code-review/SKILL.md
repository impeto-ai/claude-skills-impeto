---
name: receiving-code-review
description: Use when processing review feedback, or user mentions "feedback", "review comments", "addressing review", "reviewer disse". Processes and responds to feedback.
---

# Receiving Code Review

Processes review feedback systematically and responds constructively.

## When to Use

- Received review comments on PR
- Need to address feedback
- User says: feedback, review comments, reviewer disse
- Resolving review threads
- NOT when: no feedback exists yet

## Processing Feedback

```
┌─────────────────────────────────────────────────┐
│  1. READ ALL COMMENTS FIRST                     │
│     Don't react to one at a time                │
├─────────────────────────────────────────────────┤
│  2. CATEGORIZE                                  │
│     Must fix / Should fix / Discuss             │
├─────────────────────────────────────────────────┤
│  3. ADDRESS                                     │
│     Fix or discuss each item                    │
├─────────────────────────────────────────────────┤
│  4. RESPOND                                     │
│     Acknowledge and explain                     │
└─────────────────────────────────────────────────┘
```

## Categorize Feedback

### Category 1: MUST FIX
```
- Bugs / errors
- Security issues
- Breaking changes
- Blocked by convention/style guide
```

### Category 2: SHOULD FIX
```
- Code clarity improvements
- Better naming suggestions
- Performance improvements
- Test coverage gaps
```

### Category 3: DISCUSS
```
- Architectural disagreements
- Trade-off decisions
- Opinion-based feedback
- Scope questions
```

## Feedback Processing Template

```markdown
## Review Feedback Analysis

### PR: [Title] | Reviewer: [Name]

### Summary
- Total comments: [N]
- Must fix: [N]
- Should fix: [N]
- Discuss: [N]

---

### MUST FIX

#### Comment 1: [Summary]
**Location:** `file.py:42`
**Reviewer said:** "[quote]"
**Action:**
- [ ] [Specific fix to make]
**Response:** "Fixed in [commit]. [Brief explanation]"

#### Comment 2: [Summary]
[Same structure]

---

### SHOULD FIX

#### Comment 3: [Summary]
**Location:** `file.py:78`
**Reviewer said:** "[quote]"
**Decision:** FIX / DEFER
**Reasoning:** [Why]
**Action:**
- [ ] [Fix to make] OR
- Deferred to issue #[N]

---

### DISCUSS

#### Comment 4: [Summary]
**Location:** `file.py:100`
**Reviewer said:** "[quote]"
**My perspective:** [Explain reasoning]
**Question for reviewer:** [What needs clarification]
**Proposed resolution:** [Suggested path forward]
```

## Response Templates

### Agreeing and Fixing
```
"Good catch! Fixed in [commit SHA].
I [explanation of what was changed]."
```

### Explaining Decision
```
"I considered that approach, but went with this because:
1. [Reason 1]
2. [Reason 2]

Happy to change if you still think [alternative] is better."
```

### Asking for Clarification
```
"Could you clarify what you mean by [X]?

Are you suggesting:
a) [Interpretation 1]
b) [Interpretation 2]

I want to make sure I address your concern correctly."
```

### Deferring to Future Work
```
"Great suggestion! I think this deserves its own PR since it's
a larger change. Created issue #[N] to track this.

For this PR, I'll keep the current approach to limit scope.
Does that work for you?"
```

### Respectfully Disagreeing
```
"I see your point about [X], but I'd like to keep the current
approach because:

1. [Reason 1]
2. [Reason 2]

Would you be open to trying this way and revisiting if it
causes issues? Or do you feel strongly we should change now?"
```

## Handling Different Feedback Types

### Style/Formatting
```markdown
**Comment:** "Use camelCase instead of snake_case"
**Response:** "Fixed. Updated to match project style guide."
```

### Logic Questions
```markdown
**Comment:** "What happens if user is null?"
**Response:** "Added null check and test case for this scenario.
See [commit]."
```

### Performance Concerns
```markdown
**Comment:** "This could be slow with large datasets"
**Response:** "Added index on [column] and benchmarked:
- Before: 450ms for 10k rows
- After: 12ms for 10k rows
Results in PR description."
```

### Architecture Feedback
```markdown
**Comment:** "Consider using Strategy pattern here"
**Response:** "I explored that, but the current approach is simpler
since we only have 2 cases. If we add more cases, I'll refactor.
Added TODO comment noting this for future."
```

## After Addressing Feedback

### Re-request Review
```markdown
## Changes Made

### Addressed Feedback
1. ✅ Comment 1: Fixed null check
2. ✅ Comment 2: Added test coverage
3. ✅ Comment 3: Renamed variable
4. 💬 Comment 4: Responded inline (needs discussion)

### New Changes
- Rebased on latest main
- Fixed merge conflict in `config.py`

### Outstanding
- Comment 4 awaiting your response

Ready for re-review!
```

## Response Etiquette

### DO
```
✓ Thank reviewer for their time
✓ Acknowledge valid points
✓ Explain reasoning clearly
✓ Ask questions when unclear
✓ Update promptly
✓ Mark resolved when done
```

### DON'T
```
✗ Get defensive
✗ Dismiss feedback without consideration
✗ Make excuses
✗ Leave comments unaddressed
✗ Mark resolved without actually fixing
✗ Take feedback personally
```

## Output Format

When processing review:

```markdown
## Review Response: [PR Title]

### Feedback Summary
| Category | Count | Status |
|----------|-------|--------|
| Must Fix | 3 | ✅ All addressed |
| Should Fix | 2 | ✅ 1 fixed, 1 deferred |
| Discuss | 1 | 💬 Awaiting response |

### Changes Made
1. `file.py:42` - Added null check (Comment #1)
2. `file.py:78` - Renamed to `userCount` (Comment #2)
3. `tests/` - Added 2 new test cases (Comment #3)

### Deferred Items
- Issue #123: Refactor to Strategy pattern (Comment #5)

### Pending Discussion
- Comment #4: Awaiting reviewer response on caching approach

### Commits
- `abc1234` - Fix null check
- `def5678` - Add test coverage

Ready for re-review!
```

## Common Mistakes

- Reacting emotionally to feedback
- Addressing comments one by one without reading all first
- Not explaining why you disagree
- Marking resolved without actually fixing
- Forgetting to re-request review after changes
- Not thanking the reviewer
