---
name: project-kickoff
description: Use when starting a new project with client. Activates for "kickoff", "início projeto", "start project", "onboarding cliente".
chain: delivery-tracker
---

# Project Kickoff

Expert in project kickoff process. Ensures alignment, sets expectations, and establishes communication rhythms.

## When to Use

- Proposal accepted, starting project
- Onboarding new client
- Setting up project structure
- User says: kickoff, início projeto, start project
- CHAIN: → delivery-tracker (after kickoff complete)
- REQUIRES: proposal-builder completed

## Kickoff Checklist

```
┌─────────────────────────────────────────────────────────────────┐
│                    KICKOFF CHECKLIST                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   PRE-KICKOFF                                                   │
│   [ ] Contract signed                                           │
│   [ ] First payment received                                    │
│   [ ] Internal team briefed                                     │
│   [ ] Project tools setup                                       │
│   [ ] Kickoff agenda prepared                                   │
│                                                                 │
│   KICKOFF MEETING                                               │
│   [ ] Introductions done                                        │
│   [ ] Scope confirmed                                           │
│   [ ] Timeline reviewed                                         │
│   [ ] Communication plan set                                    │
│   [ ] Risks discussed                                           │
│   [ ] Next steps clear                                          │
│                                                                 │
│   POST-KICKOFF                                                  │
│   [ ] Meeting notes sent                                        │
│   [ ] Access/credentials received                               │
│   [ ] First milestone scheduled                                 │
│   [ ] Tracking system updated                                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Kickoff Meeting Agenda

```markdown
# Project Kickoff: [Project Name]

**Date**: [Date]
**Duration**: 60-90 minutes
**Attendees**: [List]

---

## 1. Welcome & Introductions (10 min)
- Team introductions
- Roles and responsibilities

## 2. Project Overview (10 min)
- Recap objectives
- Confirm scope
- Review deliverables

## 3. Timeline & Milestones (15 min)
- Phase breakdown
- Key dates
- Dependencies

## 4. Communication Plan (10 min)
- Meeting cadence
- Communication channels
- Response expectations
- Escalation path

## 5. Ways of Working (15 min)
- Tools we'll use
- How we'll collaborate
- Review/approval process
- Change request process

## 6. Risks & Assumptions (10 min)
- Known risks
- Mitigation plans
- Assumptions to validate

## 7. Access & Resources (10 min)
- What we need from you
- What you need from us
- Timeline for access

## 8. Q&A & Next Steps (10 min)
- Open questions
- Immediate action items
- Next meeting date
```

## Communication Plan Template

```markdown
## Communication Plan: [Project Name]

### Regular Meetings

| Meeting | Frequency | Duration | Attendees | Purpose |
|---------|-----------|----------|-----------|---------|
| Weekly Status | Weekly | 30 min | PM + Client | Progress, blockers |
| Sprint Review | Bi-weekly | 1 hour | Full team | Demo, feedback |
| Steering | Monthly | 1 hour | Leads | Strategic alignment |

### Communication Channels

| Channel | Use For | Response Time |
|---------|---------|---------------|
| Slack/Teams | Quick questions | Same day |
| Email | Formal updates | 24 hours |
| Calls | Complex discussions | Scheduled |
| [Tool] | Task tracking | Async |

### Escalation Path

```
Level 1: Project Manager
    ↓ (24h no resolution)
Level 2: Account Lead
    ↓ (48h no resolution)
Level 3: Director
```

### Status Reports

**Weekly Update (Every Friday)**
- What was completed
- What's in progress
- Blockers/risks
- Next week focus

**Format**: Email to [distribution list]
```

## RACI Matrix Template

```markdown
## RACI: [Project Name]

| Activity | [Client] | [PM] | [Dev] | [Design] |
|----------|----------|------|-------|----------|
| Requirements sign-off | A | R | C | C |
| Design approval | A | R | I | R |
| Development | I | A | R | C |
| Testing | C | A | R | I |
| Deployment | A | R | R | I |
| Training | A | R | C | C |

**R** = Responsible (does the work)
**A** = Accountable (makes decision)
**C** = Consulted (provides input)
**I** = Informed (kept in loop)
```

## Project Setup Checklist

```
DOCUMENTATION
├── Project brief/charter
├── Scope document
├── Timeline/Gantt
├── RACI matrix
└── Risk register

TOOLS
├── Project management (Linear, Notion, etc.)
├── Communication (Slack channel)
├── Repository (GitHub)
├── Design files (Figma)
└── Documentation (Confluence, Notion)

ACCESS NEEDED
├── Staging/production environments
├── APIs and integrations
├── Data access
├── Admin credentials
└── Analytics

TEAM SETUP
├── Roles assigned
├── Capacity confirmed
├── Holidays noted
└── Contact info exchanged
```

## Kickoff Notes Template

```markdown
# Kickoff Notes: [Project Name]

**Date**: [Date]
**Attendees**: [Names]

---

## Key Decisions Made

1. [Decision 1]
2. [Decision 2]
3. [Decision 3]

## Scope Confirmations

- [x] [Confirmed item]
- [x] [Confirmed item]
- [ ] [Pending clarification] - Owner: [Name]

## Timeline Confirmed

| Phase | Start | End | Owner |
|-------|-------|-----|-------|
| [Phase 1] | [Date] | [Date] | [Name] |
| [Phase 2] | [Date] | [Date] | [Name] |

## Communication Agreed

- Weekly calls: [Day] at [Time]
- Channel: [Tool]
- Primary contacts: [Names]

## Action Items

| Action | Owner | Due |
|--------|-------|-----|
| [Action 1] | [Name] | [Date] |
| [Action 2] | [Name] | [Date] |
| [Action 3] | [Name] | [Date] |

## Risks Identified

| Risk | Impact | Mitigation | Owner |
|------|--------|------------|-------|
| [Risk 1] | High | [Plan] | [Name] |
| [Risk 2] | Medium | [Plan] | [Name] |

## Next Meeting

**Date**: [Date]
**Agenda**: [First milestone review]

---

*Notes sent by [Name] on [Date]*
```

## Output Format

```
⚡ SKILL_ACTIVATED: #KICK-3T6U

## Project Kickoff: [Project Name]

### Kickoff Complete
- **Date**: [Date]
- **Attendees**: [X] people
- **Duration**: [X] minutes

### Key Alignments
- [x] Scope confirmed
- [x] Timeline agreed
- [x] Communication plan set
- [x] Risks reviewed

### Communication Rhythm
| Meeting | When | With |
|---------|------|------|
| [Type] | [Freq] | [Who] |

### Immediate Actions
| Action | Owner | Due |
|--------|-------|-----|
| [Action] | [Name] | [Date] |

### Access Pending
- [ ] [Access 1] - Requested from [Name]
- [ ] [Access 2] - Requested from [Name]

→ CHAIN: Ready for delivery-tracker
```

## Common Mistakes

- Skipping kickoff ("we already talked")
- Not confirming scope in writing
- Missing key stakeholders
- No communication plan
- Vague roles (who decides what?)
- Not getting access early
- No risk discussion
