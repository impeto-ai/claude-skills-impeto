---
name: delivery-tracker
description: Use when tracking project deliveries, milestones, status updates. Activates for "entrega", "milestone", "status projeto", "acompanhar", "tracking".
chain: client-communication
---

# Delivery Tracker

Expert in tracking project deliveries, managing milestones, and maintaining project visibility.

## When to Use

- Tracking project progress
- Managing milestones
- Creating status updates
- User says: entrega, milestone, status, acompanhar
- CHAIN: → client-communication (for updates)
- REQUIRES: project-kickoff completed

## Delivery Tracking System

```
┌─────────────────────────────────────────────────────────────────┐
│                    DELIVERY STATUS                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   🟢 ON TRACK    → Proceeding as planned                       │
│   🟡 AT RISK     → Potential issues, needs attention           │
│   🔴 BLOCKED     → Cannot proceed, needs resolution            │
│   ✅ COMPLETED   → Delivered and accepted                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Milestone Tracking Template

```markdown
# Project: [Name] - Delivery Tracker

## Overall Status: 🟢 ON TRACK

**Last Updated**: [Date]
**Completion**: [X]% ([X] of [Y] milestones)

---

## Milestones

### Phase 1: [Name]
| # | Milestone | Status | Due | Actual | Owner |
|---|-----------|--------|-----|--------|-------|
| 1.1 | [Milestone] | ✅ | [Date] | [Date] | [Name] |
| 1.2 | [Milestone] | 🟢 | [Date] | - | [Name] |
| 1.3 | [Milestone] | 🟡 | [Date] | - | [Name] |

### Phase 2: [Name]
| # | Milestone | Status | Due | Actual | Owner |
|---|-----------|--------|-----|--------|-------|
| 2.1 | [Milestone] | ⬜ | [Date] | - | [Name] |
| 2.2 | [Milestone] | ⬜ | [Date] | - | [Name] |

---

## Timeline View

```
Week 1   Week 2   Week 3   Week 4   Week 5   Week 6
|========|========|========|========|========|========|
[███████████] Phase 1 - Complete
            [████████░░░░] Phase 2 - In Progress
                         [░░░░░░░░░░] Phase 3 - Upcoming
```

---

## This Week

### Completed
- [x] [Task 1]
- [x] [Task 2]

### In Progress
- [ ] [Task 3] - [X]% complete
- [ ] [Task 4] - [X]% complete

### Upcoming
- [ ] [Task 5] - Starts [Date]

---

## Blockers & Risks

| Issue | Impact | Status | Owner | Resolution |
|-------|--------|--------|-------|------------|
| [Issue] | 🔴 High | Open | [Name] | [Plan] |
| [Issue] | 🟡 Med | Monitoring | [Name] | [Plan] |

---

## Metrics

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| On-time delivery | 90% | [X]% | ↑ |
| Scope changes | 0 | [X] | → |
| Client satisfaction | 4.5/5 | [X] | ↑ |
```

## Sprint/Week Tracking

```markdown
## Sprint [X]: [Date] - [Date]

### Sprint Goal
[What we're trying to achieve]

### Capacity
- Available hours: [X]
- Committed: [X]
- Buffer: [X]%

### Deliverables

| Task | Status | Est | Actual | Notes |
|------|--------|-----|--------|-------|
| [Task 1] | ✅ | 4h | 3h | Done early |
| [Task 2] | 🟢 | 8h | 6h | On track |
| [Task 3] | 🟡 | 4h | 6h | Took longer |
| [Task 4] | 🔴 | 2h | - | Blocked |

### Burndown
```
Hours |
  30  | ▓
  25  | ▓▓
  20  | ▓▓▓  ← Target
  15  | ▓▓▓▓
  10  | ▓▓▓▓▓
   5  | ▓▓▓▓▓▓
   0  |____________
      M  T  W  T  F
```

### Retrospective Notes
- ✅ What went well: [X]
- 🔧 What to improve: [X]
- 💡 Ideas: [X]
```

## Change Log

```markdown
## Change Log: [Project Name]

| Date | Change | Impact | Approved By | Status |
|------|--------|--------|-------------|--------|
| [Date] | [Description] | +2 days | [Name] | Approved |
| [Date] | [Description] | +$X | [Name] | Pending |
| [Date] | [Description] | None | [Name] | Approved |

### Change Request Template

**Change ID**: CR-[XXX]
**Date**: [Date]
**Requested By**: [Name]

**Description**:
[What is changing]

**Reason**:
[Why it's needed]

**Impact**:
- Timeline: [+/- X days]
- Budget: [+/- $X]
- Scope: [Description]

**Recommendation**:
[Approve/Reject/Modify]

**Decision**:
[ ] Approved [ ] Rejected
**By**: [Name] **Date**: [Date]
```

## Daily Standup Template

```markdown
## Standup: [Date]

### [Team Member 1]
**Yesterday**: [What was done]
**Today**: [What will be done]
**Blockers**: [Any blockers]

### [Team Member 2]
**Yesterday**: [What was done]
**Today**: [What will be done]
**Blockers**: [Any blockers]

### Action Items
- [ ] [Action] - [Owner]
```

## Health Dashboard

```markdown
## Project Health: [Date]

### Overall: 🟢 HEALTHY

| Dimension | Status | Trend | Notes |
|-----------|--------|-------|-------|
| Timeline | 🟢 | → | On schedule |
| Budget | 🟢 | → | Within buffer |
| Scope | 🟡 | ↓ | 2 CRs pending |
| Quality | 🟢 | ↑ | Tests passing |
| Team | 🟢 | → | Capacity ok |
| Client | 🟢 | ↑ | Happy with demo |

### Trend Legend
- ↑ Improving
- → Stable
- ↓ Declining
```

## Output Format

```
⚡ SKILL_ACTIVATED: #DELV-5U8V

## Delivery Status: [Project Name]

### Overall: [🟢/🟡/🔴]
**Progress**: [X]% complete
**On Schedule**: [Yes/No/At Risk]

### This Week
**Completed**: [X] items
**In Progress**: [X] items
**Blocked**: [X] items

### Milestones
| Milestone | Status | Due |
|-----------|--------|-----|
| [M1] | [Status] | [Date] |
| [M2] | [Status] | [Date] |

### Blockers
| Issue | Impact | Owner |
|-------|--------|-------|
| [Issue] | [Impact] | [Name] |

### Next Steps
1. [Action 1]
2. [Action 2]

→ CHAIN: Generate client-communication update
```

## Delivery Cadence

```
DAILY
├── Team standup (internal)
├── Blocker resolution
└── Progress updates

WEEKLY
├── Client status call
├── Milestone review
├── Risk assessment
└── Written status report

BI-WEEKLY
├── Sprint review/demo
├── Retrospective
└── Planning next sprint

MONTHLY
├── Steering meeting
├── Budget review
├── Health assessment
└── Client satisfaction check
```

## Common Mistakes

- Not tracking changes formally
- Missing early warning signs
- Infrequent updates
- No blocker escalation
- Scope creep (undocumented)
- No client visibility
