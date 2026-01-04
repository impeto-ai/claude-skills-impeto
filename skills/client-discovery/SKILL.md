---
name: client-discovery
description: Use when starting client engagement, understanding requirements. Activates for "discovery", "entender cliente", "requisitos", "first meeting", "kickoff cliente".
chain: proposal-builder
---

# Client Discovery

Expert in client discovery process, requirements gathering, and understanding client needs for AI/software projects.

## When to Use

- First meeting with potential client
- Understanding project requirements
- Clarifying scope and expectations
- User says: discovery, entender cliente, requisitos
- CHAIN: → proposal-builder (after discovery)
- NOT when: project already started (use project-kickoff)

## Discovery Framework

```
┌─────────────────────────────────────────────────────────────────┐
│                    DISCOVERY PROCESS                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   1. CONTEXT    → Company, market, current state               │
│   2. PROBLEM    → Pain points, root causes                     │
│   3. VISION     → Desired future state                         │
│   4. SUCCESS    → How they'll measure it                       │
│   5. CONSTRAINTS→ Budget, timeline, tech limits                │
│   6. STAKEHOLDERS → Who decides, who uses                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Discovery Questions

### Context (5 min)
```
COMPANY
- "Tell me about [Company] - what do you do?"
- "What's your role?"
- "How big is your team?"
- "Who are your customers?"

CURRENT STATE
- "Walk me through your current process for [X]"
- "What tools/systems do you use today?"
- "What's working well?"
```

### Problem (15 min)
```
PAIN POINTS
- "What's the biggest challenge you're facing with [X]?"
- "How is this affecting your business?"
- "How long has this been a problem?"
- "What have you tried before?"

ROOT CAUSE
- "Why do you think this is happening?"
- "What would change if you solved this?"
- "Who else is affected by this problem?"

IMPACT
- "How much time/money does this cost you?"
- "What opportunities are you missing?"
- "What's the cost of not solving this?"
```

### Vision (10 min)
```
FUTURE STATE
- "If we solve this perfectly, what does that look like?"
- "Walk me through an ideal day after this is solved"
- "What would change for your team?"
- "What would change for your customers?"

PRIORITIES
- "What's the most important outcome?"
- "What's nice-to-have vs must-have?"
- "If you could only have one thing, what would it be?"
```

### Success Metrics (10 min)
```
QUANTITATIVE
- "How will you measure success?"
- "What numbers should improve?"
- "What's the target?"
- "What's acceptable? What's amazing?"

QUALITATIVE
- "How will you know when it's working?"
- "What feedback would you expect from users?"
- "What would make you say 'this was worth it'?"
```

### Constraints (10 min)
```
BUDGET
- "Do you have a budget in mind for this?"
- "What would make this investment worthwhile?"
- "How do you typically make purchase decisions?"

TIMELINE
- "When do you need this by?"
- "What's driving that deadline?"
- "Is there flexibility?"

TECHNICAL
- "What systems does this need to integrate with?"
- "Are there tech preferences or requirements?"
- "Any security/compliance requirements?"
```

### Stakeholders (5 min)
```
DECISION MAKERS
- "Who else is involved in this decision?"
- "What are their priorities?"
- "What concerns might they have?"

USERS
- "Who will use this day-to-day?"
- "What's their technical level?"
- "How do they feel about the current process?"
```

## Discovery Document Template

```markdown
# Discovery: [Client Name] - [Project Name]

## Date: [Date]
## Attendees: [Names]

---

## 1. Company Context

**Company**: [Name]
**Industry**: [Industry]
**Size**: [# employees]
**Role**: [Client's role]

**Current Situation**:
[Description of current state]

**Systems Used**:
- [System 1]
- [System 2]

---

## 2. Problem Statement

**Primary Pain Points**:
1. [Pain 1]: [Impact]
2. [Pain 2]: [Impact]
3. [Pain 3]: [Impact]

**Root Cause Analysis**:
[Why this is happening]

**Cost of Problem**:
- Time: [X hours/week]
- Money: [$ estimate]
- Opportunity: [What they're missing]

---

## 3. Desired Outcome

**Vision**:
[Description of ideal future state]

**Must-Haves**:
- [ ] [Requirement 1]
- [ ] [Requirement 2]
- [ ] [Requirement 3]

**Nice-to-Haves**:
- [ ] [Feature 1]
- [ ] [Feature 2]

---

## 4. Success Metrics

| Metric | Current | Target | Timeline |
|--------|---------|--------|----------|
| [Metric 1] | [X] | [Y] | [When] |
| [Metric 2] | [X] | [Y] | [When] |

**Qualitative Success**:
[How they'll know it's working]

---

## 5. Constraints

**Budget**: [Range or TBD]
**Timeline**: [Deadline and flexibility]
**Technical**:
- Must integrate: [Systems]
- Requirements: [Security, compliance, etc.]

---

## 6. Stakeholders

| Name | Role | Priority | Concern |
|------|------|----------|---------|
| [Name] | Decision Maker | [X] | [Y] |
| [Name] | User | [X] | [Y] |
| [Name] | Technical | [X] | [Y] |

---

## 7. Next Steps

1. [ ] [Action 1] - [Owner] - [Date]
2. [ ] [Action 2] - [Owner] - [Date]
3. [ ] Send proposal by [Date]

---

## 8. Red Flags / Concerns

- [Any concerns noted]
- [Risks identified]

---

## 9. Opportunity Assessment

**Fit Score**: [1-5]
**Confidence**: [High/Medium/Low]
**Recommended Approach**: [Proceed/Pause/Decline]
```

## Jobs-to-Be-Done Framework

```
WHEN [situation]
I WANT TO [motivation]
SO I CAN [outcome]

EXAMPLE:
"When I receive a new lead,
I want to automatically qualify them,
So I can focus my time on high-value prospects."
```

## Output Format

```
⚡ SKILL_ACTIVATED: #DISC-7Q3R

## Discovery Summary: [Client]

### The Problem
[1-2 sentence problem statement]

### The Impact
- Time: [X hours/week wasted]
- Money: [$ cost]
- Opportunity: [what they're missing]

### The Vision
[What success looks like]

### Key Requirements
1. [Must-have 1]
2. [Must-have 2]
3. [Must-have 3]

### Success Metrics
| Metric | Target |
|--------|--------|
| [X] | [Y] |

### Constraints
- Budget: [X]
- Timeline: [X]
- Technical: [X]

### Fit Assessment
**Score**: [X/5]
**Recommendation**: [Proceed/Pause/Decline]

→ CHAIN: Ready for proposal-builder
```

## Red Flags to Watch

```
SCOPE
├── "We need everything"
├── "Just a simple [complex thing]"
├── Unclear success metrics
└── Moving target requirements

BUDGET
├── No budget defined
├── Unrealistic expectations
├── Shopping around only
└── Payment terms red flags

TIMELINE
├── "We needed this yesterday"
├── Immovable unrealistic deadline
├── No clear milestones
└── Dependencies on others

STAKEHOLDERS
├── Too many decision makers
├── Missing key stakeholder
├── Conflicting priorities
├── Previous vendor issues
```

## Common Mistakes

- Talking more than listening
- Jumping to solutions
- Not asking about budget
- Missing stakeholders
- Not documenting
- Over-promising
