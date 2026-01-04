---
name: proposal-builder
description: Use when creating client proposals, quotes, SOWs. Activates for "proposta", "orçamento", "quote", "SOW", "escopo projeto".
chain: project-kickoff
---

# Proposal Builder

Expert in creating compelling proposals for AI/software projects. Transforms discovery into clear, value-focused proposals.

## When to Use

- Creating project proposal
- Writing SOW (Statement of Work)
- Defining project scope and pricing
- User says: proposta, orçamento, quote, SOW
- CHAIN: → project-kickoff (after proposal accepted)
- REQUIRES: client-discovery completed first

## Proposal Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                    PROPOSAL SECTIONS                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   1. EXECUTIVE SUMMARY  → Hook, problem, solution (1 page)     │
│   2. UNDERSTANDING      → Show you get their problem           │
│   3. SOLUTION           → What you'll build/do                 │
│   4. APPROACH           → How you'll do it                     │
│   5. DELIVERABLES       → What they get                        │
│   6. TIMELINE           → When they get it                     │
│   7. INVESTMENT         → What it costs                        │
│   8. WHY US             → Why you're the right choice          │
│   9. NEXT STEPS         → Clear CTA                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Proposal Template

```markdown
# [Project Name] Proposal

**Prepared for**: [Client Company]
**Prepared by**: [Your Company]
**Date**: [Date]
**Valid until**: [Date + 30 days]

---

## Executive Summary

[Client] is facing [problem] which is costing them [impact].

We propose [solution overview] that will [key outcome].

**Investment**: [Price range]
**Timeline**: [Duration]
**Expected ROI**: [Outcome metric]

---

## 1. Understanding Your Challenge

### Current Situation
[Summarize what you learned in discovery]

### The Problem
[Specific pain points]

### Impact
- [Impact 1]: [Quantified]
- [Impact 2]: [Quantified]
- [Impact 3]: [Quantified]

### Desired Outcome
[What success looks like for them]

---

## 2. Proposed Solution

### Overview
[High-level solution description]

### Key Components

#### [Component 1]
[Description and value]

#### [Component 2]
[Description and value]

#### [Component 3]
[Description and value]

### Why This Approach
[Justification for chosen solution]

---

## 3. Scope of Work

### In Scope
- [Deliverable 1]
- [Deliverable 2]
- [Deliverable 3]

### Out of Scope
- [Exclusion 1]
- [Exclusion 2]

### Assumptions
- [Assumption 1]
- [Assumption 2]

---

## 4. Deliverables

| # | Deliverable | Description | Format |
|---|-------------|-------------|--------|
| 1 | [Name] | [What it is] | [How delivered] |
| 2 | [Name] | [What it is] | [How delivered] |
| 3 | [Name] | [What it is] | [How delivered] |

---

## 5. Timeline

### Phase 1: [Name] (Week 1-2)
- [ ] Milestone 1
- [ ] Milestone 2

### Phase 2: [Name] (Week 3-4)
- [ ] Milestone 3
- [ ] Milestone 4

### Phase 3: [Name] (Week 5-6)
- [ ] Milestone 5
- [ ] Milestone 6

```
Week 1   Week 2   Week 3   Week 4   Week 5   Week 6
|--------|--------|--------|--------|--------|--------|
[  Phase 1       ][  Phase 2       ][  Phase 3       ]
                 ▲                  ▲                 ▲
              Review            Review            Delivery
```

---

## 6. Investment

### Option A: [Name]
**[Price]**
- [What's included]
- [What's included]

### Option B: [Name] ← Recommended
**[Price]**
- Everything in Option A
- [Additional value]
- [Additional value]

### Option C: [Name]
**[Price]**
- Everything in Option B
- [Premium value]
- [Premium value]

### Payment Terms
- [X]% upon signing
- [X]% at [milestone]
- [X]% upon completion

---

## 7. Why [Your Company]

### Our Experience
- [Relevant project 1]
- [Relevant project 2]

### Our Approach
[What makes you different]

### Client Testimonial
> "[Quote from happy client]"
> — [Name, Company]

---

## 8. Next Steps

1. Review this proposal
2. Schedule 30-min Q&A call
3. Sign agreement
4. Kickoff meeting within [X] days

**To proceed**: Reply to this email or [call/book]

---

## 9. Terms & Conditions

[Key terms - link to full T&C]

---

**Questions?** Contact [Name] at [email/phone]
```

## Pricing Presentation

### Three-Option Strategy
```
GOOD-BETTER-BEST

Option A (Good):
├── Minimum viable scope
├── Lower price point
└── For price-sensitive clients

Option B (Better): ← Highlight this
├── Recommended scope
├── Best value
└── Most clients choose this

Option C (Best):
├── Premium/full scope
├── Highest price
└── For ambitious clients
```

### Price Anchoring
```
1. Start with the EXPENSIVE option
2. Compare to the COST OF PROBLEM
3. Show VALUE vs INVESTMENT ratio
4. Offer payment terms

EXAMPLE:
"This problem costs you $50K/year.
Option B at $15K is a 3x ROI in year one."
```

## SOW (Statement of Work) Template

```markdown
# Statement of Work

## Project: [Name]
## Client: [Company]
## Effective Date: [Date]

### 1. Background
[Why this project exists]

### 2. Objectives
1. [Objective 1]
2. [Objective 2]

### 3. Scope of Services

#### 3.1 Included
- [Task 1]
- [Task 2]

#### 3.2 Excluded
- [Exclusion 1]

### 4. Deliverables
[Table of deliverables with acceptance criteria]

### 5. Timeline
[Milestones and dates]

### 6. Roles & Responsibilities

**[Your Company] will:**
- [Responsibility 1]

**[Client] will:**
- [Responsibility 1]

### 7. Fees and Payment
[Pricing and payment schedule]

### 8. Change Management
[How changes are handled]

### 9. Acceptance
[How deliverables are accepted]

### 10. Signatures

_________________________     _________________________
[Your Name]                   [Client Name]
[Your Company]                [Client Company]
Date:                         Date:
```

## Output Format

```
⚡ SKILL_ACTIVATED: #PROP-9R5S

## Proposal Created: [Project Name]

### Summary
- **Client**: [Name]
- **Project**: [Brief description]
- **Investment**: $[X] - $[Y]
- **Timeline**: [Duration]

### Scope Highlights
1. [Deliverable 1]
2. [Deliverable 2]
3. [Deliverable 3]

### Pricing Options
| Option | Price | Includes |
|--------|-------|----------|
| A | $[X] | [Basic] |
| B | $[Y] | [Recommended] |
| C | $[Z] | [Premium] |

### Key Terms
- Payment: [Terms]
- Start: [When]
- Duration: [Weeks]

### Files Generated
- [ ] proposal_[client]_[date].md
- [ ] sow_[client]_[date].md

→ CHAIN: After accepted → project-kickoff
```

## Common Mistakes

- No clear value proposition
- Too technical (client doesn't care)
- No pricing options
- Vague scope (scope creep risk)
- No timeline
- Missing next steps
- Too long (nobody reads 50 pages)
- No deadline for proposal validity
