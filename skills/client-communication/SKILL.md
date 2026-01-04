---
name: client-communication
description: Use when creating client updates, status reports, managing client relationships. Activates for "update cliente", "weekly update", "comunicar cliente", "status report".
chain: none
---

# Client Communication

Expert in client communication, status updates, and relationship management. Maintains transparent, professional client relationships.

## When to Use

- Writing status updates
- Client meeting prep
- Managing expectations
- User says: update cliente, weekly, comunicar, status report
- Triggered by: delivery-tracker (for updates)
- NOT when: internal communication

## Communication Templates

```
┌─────────────────────────────────────────────────────────────────┐
│                    COMMUNICATION TYPES                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   WEEKLY STATUS   → Regular progress update                    │
│   MILESTONE       → Deliverable completion                     │
│   BLOCKER ALERT   → Issue requiring attention                  │
│   GOOD NEWS       → Positive development                       │
│   BAD NEWS        → Problem or delay                           │
│   CHANGE REQUEST  → Scope/timeline change                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Weekly Status Update

```markdown
Subject: [Project Name] - Weekly Update [Date]

---

## 📊 Status: 🟢 On Track

### This Week's Highlights
- ✅ [Achievement 1]
- ✅ [Achievement 2]
- ✅ [Achievement 3]

### Progress

| Milestone | Status | Target | Notes |
|-----------|--------|--------|-------|
| [M1] | ✅ Complete | [Date] | Delivered |
| [M2] | 🟢 In Progress | [Date] | [X]% done |
| [M3] | ⬜ Upcoming | [Date] | Starts next week |

### What's Next
- [ ] [Task 1] - [Owner]
- [ ] [Task 2] - [Owner]
- [ ] [Task 3] - [Owner]

### Blockers/Risks
[None this week / Description of any issues]

### Need from You
- [ ] [Request 1] - By [Date]
- [ ] [Request 2] - By [Date]

---

*Next update: [Date]*
*Questions? Reply to this email or ping on [Slack]*
```

## Milestone Completion

```markdown
Subject: 🎉 [Project Name] - [Milestone] Completed!

---

Hi [Name],

Great news! We've completed **[Milestone Name]**.

## What Was Delivered
- [Deliverable 1]
- [Deliverable 2]
- [Deliverable 3]

## Demo/Preview
[Link to demo or screenshots]

## What This Means
[Business impact in client terms]

## Next Steps
[Milestone Name] is next. We'll start on [Date] and expect completion by [Date].

## Your Input Needed
Before we move forward:
- [ ] Please review [X] by [Date]
- [ ] Confirm [Y] works as expected

---

Let me know if you have any questions!

[Name]
```

## Blocker/Issue Alert

```markdown
Subject: ⚠️ [Project Name] - Issue Requiring Attention

---

Hi [Name],

We've encountered an issue that needs your attention.

## The Issue
[Clear, factual description]

## Impact
- Timeline: [Effect on schedule]
- Scope: [Effect on deliverables]
- Cost: [Any budget impact]

## What We're Doing
1. [Action 1] - [Status]
2. [Action 2] - [Status]

## What We Need from You
[Specific request with deadline]

## Options
**Option A**: [Description]
- Timeline impact: [X]
- Cost impact: [X]

**Option B**: [Description]
- Timeline impact: [X]
- Cost impact: [X]

**Our Recommendation**: Option [X] because [reason]

---

Can we schedule a 15-min call today or tomorrow to discuss?

Available: [Times]

[Name]
```

## Delivering Bad News

```
THE BAD NEWS SANDWICH - DON'T DO IT

❌ Good news + Bad news + Good news
   → Seems manipulative
   → Bad news gets buried

DO THIS INSTEAD:

✅ Direct → Context → Impact → Solution → Commitment

EXAMPLE:
"I need to let you know about a delay.
[Context]: The API integration is more complex than scoped.
[Impact]: This will add 5 days to Phase 2.
[Solution]: We can either extend timeline or reduce scope.
[Commitment]: I have the team on this and will update you Friday."
```

## Communication Best Practices

```
PROACTIVE > REACTIVE
├── Update before they ask
├── Share problems early
├── Celebrate wins together
└── No surprises

CLARITY > COMPLETENESS
├── Lead with the point
├── Keep it scannable
├── Use bullet points
└── Bold key items

PROFESSIONAL > CASUAL
├── Proofread everything
├── Use their name
├── CC appropriately
└── Reply within 24h
```

## Meeting Agenda Templates

### Weekly Status Call (30 min)
```
1. [5 min] Progress recap
2. [10 min] Demos/updates
3. [5 min] Blockers & risks
4. [5 min] Upcoming work
5. [5 min] Q&A / Open items
```

### Sprint Review (1 hour)
```
1. [5 min] Sprint goal recap
2. [30 min] Demo deliverables
3. [10 min] Feedback collection
4. [10 min] Next sprint preview
5. [5 min] Action items
```

### Escalation Meeting (30 min)
```
1. [5 min] Issue summary
2. [10 min] Options presented
3. [10 min] Discussion
4. [5 min] Decision & next steps
```

## Difficult Conversations

### Scope Change
```markdown
Subject: [Project Name] - Scope Change Request

Hi [Name],

We've identified additional work outside our original scope.

## What Changed
[Description of new requirement]

## Why It's Outside Scope
Original scope defined: [What was agreed]
New request requires: [What's additional]

## Options

**Option A: Add to Current Project**
- Additional: +$[X] / +[Y] days
- Impact: Extends timeline to [Date]

**Option B: Phase 2**
- Complete current scope as planned
- Add this to a future phase

**Option C: Trade-off**
- Replace [X] from scope with this
- No timeline/budget change

**Recommendation**: [Option X] because [reason]

Let's discuss on our next call.
```

### Timeline Delay
```markdown
Subject: [Project Name] - Timeline Update

Hi [Name],

I want to give you an early heads up about our timeline.

## Current Status
We're [X] days behind on [Milestone].

## Reason
[Clear explanation - take responsibility]

## Revised Timeline
| Milestone | Original | Revised |
|-----------|----------|---------|
| [M1] | [Date] | [Date] |
| [M2] | [Date] | [Date] |

## What We're Doing
[Actions to prevent further delay]

## Commitment
I'll provide daily updates until we're back on track.

Sorry for the inconvenience. Happy to discuss on a call.
```

## Output Format

```
⚡ SKILL_ACTIVATED: #COMM-6W9X

## Client Communication: [Type]

### Message Created
**To**: [Client]
**Subject**: [Subject line]
**Type**: [Status/Milestone/Alert/etc.]

### Key Points
- [Point 1]
- [Point 2]
- [Point 3]

### Action Required
- From client: [Yes/No]
- Deadline: [Date if applicable]

### Tone Check
- [ ] Clear and scannable
- [ ] Professional
- [ ] Action-oriented
- [ ] No surprises

### Draft
[Full email/message text]
```

## Communication Calendar

```
MONDAY
└── Internal team sync

TUESDAY
└── Client weekly update call

WEDNESDAY
└── Ad-hoc as needed

THURSDAY
└── Demo/review meetings

FRIDAY
└── Weekly status email sent
```

## Common Mistakes

- Waiting too long to share bad news
- Vague updates ("making progress")
- Too much technical detail
- No clear asks/next steps
- Forgetting to follow up
- BCC drama
- Reply-all chaos
