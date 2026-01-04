---
name: retrospective
description: Use when doing project retrospectives, lessons learned, post-mortems. Activates for "retro", "lessons learned", "retrospectiva", "post-mortem", "fechamento projeto".
chain: none
---

# Retrospective

Expert in project retrospectives, lessons learned, and continuous improvement. Captures insights to improve future projects.

## When to Use

- End of sprint/phase
- Project completion
- After incidents/issues
- User says: retro, lessons learned, retrospectiva, post-mortem
- NOT when: project is ongoing (use delivery-tracker)

## Retrospective Types

```
┌─────────────────────────────────────────────────────────────────┐
│                    RETROSPECTIVE TYPES                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   SPRINT RETRO    → End of sprint (bi-weekly)                  │
│   PHASE RETRO     → End of project phase                       │
│   PROJECT RETRO   → Project completion                         │
│   INCIDENT PM     → After major issue                          │
│   QUICK RETRO     → Weekly health check                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Classic Format: Start/Stop/Continue

```markdown
## Retrospective: [Project/Sprint]

**Date**: [Date]
**Attendees**: [Names]

---

### 🟢 START (What should we begin doing?)
- [New practice to adopt]
- [New practice to adopt]

### 🔴 STOP (What should we stop doing?)
- [Practice to abandon]
- [Practice to abandon]

### 🔵 CONTINUE (What's working well?)
- [Practice to keep]
- [Practice to keep]

---

### Action Items

| Action | Owner | Due | Status |
|--------|-------|-----|--------|
| [Action 1] | [Name] | [Date] | [ ] |
| [Action 2] | [Name] | [Date] | [ ] |
```

## 4Ls Format: Liked/Learned/Lacked/Longed For

```markdown
## 4L Retrospective: [Project]

### 💚 LIKED (What went well?)
- [What team enjoyed]
- [What worked great]

### 📘 LEARNED (What did we learn?)
- [New insight]
- [Technical learning]
- [Process learning]

### ❌ LACKED (What was missing?)
- [Resource we needed]
- [Process gap]
- [Tool we needed]

### 💭 LONGED FOR (What do we wish we had?)
- [Ideal state]
- [Wishlist item]
```

## Project Completion Retro

```markdown
# Project Retrospective: [Project Name]

**Project Duration**: [Start] - [End]
**Team**: [Names]
**Client**: [Client Name]

---

## 1. Project Summary

**Objective**: [What we set out to do]
**Outcome**: [What we delivered]
**Client Satisfaction**: [X/5]

---

## 2. What Went Well ✅

### Delivery
- [Success 1]
- [Success 2]

### Process
- [What worked]
- [What worked]

### Team
- [Positive aspect]
- [Positive aspect]

### Client Relationship
- [Positive aspect]
- [Positive aspect]

---

## 3. What Could Improve 🔧

### Delivery
- [Challenge 1]
- [Challenge 2]

### Process
- [Gap 1]
- [Gap 2]

### Team
- [Area to improve]
- [Area to improve]

### Client Relationship
- [Area to improve]

---

## 4. Key Learnings 📚

### Technical
- [Learning 1]
- [Learning 2]

### Process
- [Learning 1]
- [Learning 2]

### Business
- [Learning 1]
- [Learning 2]

---

## 5. Metrics Review

| Metric | Target | Actual | Notes |
|--------|--------|--------|-------|
| Timeline | [X] weeks | [Y] weeks | [+/-] |
| Budget | $[X] | $[Y] | [+/-] |
| Scope changes | 0 | [X] | [Notes] |
| Client satisfaction | 4.5/5 | [X]/5 | [Notes] |

---

## 6. Recommendations for Future

### Do This Again
- [Practice to repeat]
- [Practice to repeat]

### Do This Differently
- [What to change]
- [What to change]

### Avoid This
- [What not to do]
- [What not to do]

---

## 7. Action Items

| Action | Owner | Priority | Due |
|--------|-------|----------|-----|
| [Document pattern X] | [Name] | High | [Date] |
| [Create template for Y] | [Name] | Medium | [Date] |
| [Train team on Z] | [Name] | Low | [Date] |

---

## 8. Team Recognition

**Shoutouts**:
- [Name] for [contribution]
- [Name] for [contribution]

---

*Retrospective facilitated by [Name] on [Date]*
```

## Incident Post-Mortem

```markdown
# Post-Mortem: [Incident Name]

**Date**: [Date of incident]
**Duration**: [How long it lasted]
**Severity**: [High/Medium/Low]
**Lead**: [Name]

---

## 1. Summary

**What happened**: [1-2 sentence summary]
**Impact**: [Who/what was affected]
**Resolution**: [How it was fixed]

---

## 2. Timeline

| Time | Event |
|------|-------|
| [HH:MM] | [What happened] |
| [HH:MM] | [What happened] |
| [HH:MM] | Issue detected |
| [HH:MM] | Response started |
| [HH:MM] | [Action taken] |
| [HH:MM] | Issue resolved |
| [HH:MM] | All clear confirmed |

---

## 3. Root Cause Analysis

**Proximate Cause**: [Immediate cause]

**Contributing Factors**:
1. [Factor 1]
2. [Factor 2]
3. [Factor 3]

**Root Cause**: [Underlying cause]

### 5 Whys

1. Why did [symptom] happen? → [Answer 1]
2. Why did [Answer 1]? → [Answer 2]
3. Why did [Answer 2]? → [Answer 3]
4. Why did [Answer 3]? → [Answer 4]
5. Why did [Answer 4]? → **Root Cause**

---

## 4. What Went Well

- [Good response]
- [Good process]
- [Good communication]

---

## 5. What Could Improve

- [Gap 1]
- [Gap 2]
- [Gap 3]

---

## 6. Action Items

| Action | Type | Owner | Priority | Due |
|--------|------|-------|----------|-----|
| [Action 1] | Prevent | [Name] | High | [Date] |
| [Action 2] | Detect | [Name] | High | [Date] |
| [Action 3] | Respond | [Name] | Medium | [Date] |

**Action Types**:
- Prevent: Stop this from happening again
- Detect: Catch it earlier next time
- Respond: Handle it better if it recurs

---

## 7. Lessons Learned

[Key takeaways for the team and org]

---

*Blameless post-mortem. Focus on systems, not individuals.*
```

## Quick Weekly Retro

```markdown
## Quick Retro: Week of [Date]

**Team Mood**: 😀😐😟 [Choose one]

### 👍 Highlight of the week
[Best thing that happened]

### 👎 Challenge of the week
[Biggest obstacle]

### 💡 One thing to try next week
[Small improvement to attempt]

### 🙏 Help needed
[Where the team needs support]
```

## Output Format

```
⚡ SKILL_ACTIVATED: #RETR-8Y4Z

## Retrospective: [Project/Sprint]

### Summary
**What went well**: [Top 3]
**What to improve**: [Top 3]
**Key learnings**: [Top 3]

### Action Items
| Action | Owner | Priority |
|--------|-------|----------|
| [Action] | [Name] | [High/Med/Low] |

### Metrics
| Metric | Target | Actual |
|--------|--------|--------|
| [Metric] | [X] | [Y] |

### Mood Check
Team: [Emoji indicator]
Client: [Emoji indicator]

### Document Created
[Link to full retro document]
```

## Facilitation Tips

```
BEFORE
├── Send agenda in advance
├── Collect async feedback
├── Review previous retro actions
└── Set time limit

DURING
├── Start with positives
├── Equal voice for everyone
├── Focus on systems, not blame
├── Time-box each section
└── End with clear actions

AFTER
├── Send notes within 24h
├── Track action items
├── Follow up on progress
└── Reference in next retro
```

## Common Mistakes

- Skipping retrospectives
- No action items
- Not following up
- Blame culture
- Only focusing on negatives
- Too long/boring
- Not inviting right people
