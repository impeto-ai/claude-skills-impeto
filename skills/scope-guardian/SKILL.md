---
name: scope-guardian
description: Use when managing scope changes, preventing scope creep. Activates for "escopo", "scope creep", "change request", "fora do escopo", "mudança requisito".
chain: none
---

# Scope Guardian

Expert in scope management, change control, and preventing scope creep. Protects project boundaries while maintaining client relationships.

## When to Use

- Evaluating scope change requests
- Preventing scope creep
- Managing client expectations
- User says: escopo, scope creep, change request, fora do escopo
- NOT when: initial scoping (use client-discovery)

## Scope Management Framework

```
┌─────────────────────────────────────────────────────────────────┐
│                    SCOPE DECISIONS                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   IN SCOPE        → Clearly in the agreement                   │
│   OUT OF SCOPE    → Clearly excluded                           │
│   GRAY AREA       → Needs discussion/clarification             │
│   SCOPE CREEP     → Gradual expansion without approval         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Change Control Process

```
CHANGE REQUEST FLOW

1. REQUEST
   └── Document the requested change

2. ASSESS
   ├── Is it in scope?
   ├── What's the impact?
   └── What are the options?

3. DECIDE
   ├── Approve (with impact)
   ├── Defer (to later phase)
   ├── Trade-off (swap for something)
   └── Decline (explain why)

4. DOCUMENT
   └── Update scope document

5. COMMUNICATE
   └── Confirm with all parties
```

## Change Request Template

```markdown
# Change Request: CR-[XXX]

**Date**: [Date]
**Project**: [Project Name]
**Requested By**: [Client Name]
**Priority**: [High/Medium/Low]

---

## 1. Change Description

**What is being requested?**
[Clear description of the change]

**Why is it needed?**
[Business justification]

---

## 2. Scope Analysis

**Original Scope**:
[What was agreed in the proposal/SOW]

**Requested Change**:
[How this differs from original]

**Classification**:
- [ ] Enhancement (new feature)
- [ ] Modification (change existing)
- [ ] Correction (fix unclear requirement)
- [ ] Discovery (wasn't known before)

---

## 3. Impact Assessment

| Dimension | Impact | Notes |
|-----------|--------|-------|
| Timeline | +[X] days | [Explanation] |
| Budget | +$[X] | [Explanation] |
| Resources | [X] hours | [Explanation] |
| Quality | [Impact] | [Explanation] |
| Risk | [Impact] | [Explanation] |

---

## 4. Options

### Option A: Approve as Requested
- Timeline: +[X] days
- Budget: +$[X]
- Trade-off: [If any]

### Option B: Defer to Phase 2
- Timeline: No impact now
- Budget: No impact now
- Trade-off: Feature delayed

### Option C: Trade-off
- Replace [Feature X] with this change
- Timeline: No impact
- Budget: No impact
- Trade-off: Lose [Feature X]

### Option D: Decline
- Maintain current scope
- Reason: [Explanation]

---

## 5. Recommendation

**Recommended Option**: [X]

**Reasoning**:
[Why this is the best approach]

---

## 6. Decision

**Status**: [ ] Approved [ ] Deferred [ ] Declined

**Decided By**: [Name]
**Date**: [Date]

**Notes**:
[Any conditions or notes]

---

## 7. Signatures

**Client**: _________________ Date: _______
**Provider**: _________________ Date: _______
```

## Scope Creep Detection

```
WARNING SIGNS

SMALL ASKS
├── "Can you also just..."
├── "While you're in there..."
├── "One more tiny thing..."
└── "This should be quick..."

INTERPRETATION EXPANSION
├── "I assumed this included..."
├── "That's what I meant by..."
├── "Obviously this covers..."
└── "You must have understood..."

GOLD PLATING (Self-inflicted)
├── Adding unrequested features
├── Over-engineering solutions
├── Perfectionism beyond spec
└── "Nice to have" becoming "must have"
```

## Handling Scope Creep Conversations

### Polite Decline
```
"I'd love to include this! It's outside our current scope, but we have
a few options:
1. Add it to this project (+$X, +Y days)
2. Plan it for a Phase 2
3. Trade it for [something else]

Which works best for you?"
```

### Clarifying Gray Areas
```
"I want to make sure we're aligned. My understanding of [X] is [Y].
Is that what you had in mind, or are you thinking something different?"
```

### Addressing "Quick" Requests
```
"I hear that it seems quick, and I appreciate the urgency. Let me
assess the actual impact - even small changes need testing and
documentation. I'll get back to you by [time] with options."
```

## Scope Document Template

```markdown
# Scope Document: [Project Name]

**Version**: [1.0]
**Last Updated**: [Date]
**Status**: Approved

---

## 1. Project Objectives
[What success looks like]

---

## 2. In Scope

### Deliverables
- [x] [Deliverable 1]
- [x] [Deliverable 2]
- [x] [Deliverable 3]

### Features
- [x] [Feature 1]
- [x] [Feature 2]
- [x] [Feature 3]

### Activities
- [x] [Activity 1]
- [x] [Activity 2]

---

## 3. Out of Scope

The following are **explicitly excluded**:
- [Exclusion 1]
- [Exclusion 2]
- [Exclusion 3]

---

## 4. Assumptions

- [Assumption 1]
- [Assumption 2]
- [Assumption 3]

If assumptions change, scope may need revision.

---

## 5. Constraints

- Timeline: [Constraint]
- Budget: [Constraint]
- Technical: [Constraint]

---

## 6. Change Log

| Date | Change | CR# | Impact | Approved By |
|------|--------|-----|--------|-------------|
| [Date] | Initial scope | - | - | [Name] |
| [Date] | [Change] | CR-001 | +$X | [Name] |

---

## 7. Approval

**Client**: _________________ Date: _______
**Provider**: _________________ Date: _______
```

## Trade-off Matrix

```markdown
## Trade-off Options

When new requests come in, consider:

| Request | Add | Defer | Trade | Decline |
|---------|-----|-------|-------|---------|
| [Feature A] | +$X, +Y days | Phase 2 | Remove [B] | Not viable |
| [Feature B] | +$X, +Y days | Phase 2 | Remove [C] | Low value |

### Prioritization Framework

| Priority | Criteria | Action |
|----------|----------|--------|
| Must | Business critical | Keep |
| Should | High value | Consider trade |
| Could | Nice to have | Defer/Trade |
| Won't | Low value | Decline |
```

## Output Format

```
⚡ SKILL_ACTIVATED: #SCPE-7X2Y

## Scope Analysis: [Request]

### Classification
**Type**: [Enhancement/Modification/Correction/Discovery]
**In Scope**: [Yes/No/Gray Area]

### Impact Assessment
| Dimension | Impact |
|-----------|--------|
| Timeline | [+X days] |
| Budget | [+$X] |
| Resources | [X hours] |

### Options
1. **Approve**: [Impact summary]
2. **Defer**: [Impact summary]
3. **Trade**: [What to swap]
4. **Decline**: [Reason]

### Recommendation
**[Option]** because [reasoning]

### Change Request
[Link to CR document if needed]

### Client Response Draft
[Template message to send]
```

## Common Mistakes

- No written scope baseline
- Saying yes to everything
- Not tracking small changes
- Unclear change process
- No client sign-off
- Gold plating (over-delivering)
- Fear of saying no
