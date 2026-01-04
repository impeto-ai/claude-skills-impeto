---
name: business-metrics
description: Use when tracking business metrics, revenue, client health. Activates for "métricas", "receita", "revenue", "churn", "LTV", "health score", "KPIs negócio".
chain: none
---

# Business Metrics

Expert in tracking business health, revenue metrics, and client success indicators for AI/software businesses.

## When to Use

- Tracking business performance
- Client health analysis
- Revenue forecasting
- User says: métricas, receita, revenue, churn, LTV
- NOT when: project-specific tracking (use delivery-tracker)

## Key Metrics Dashboard

```
┌─────────────────────────────────────────────────────────────────┐
│                    BUSINESS METRICS                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   REVENUE         → MRR, ARR, Growth Rate                      │
│   CLIENTS         → Active, Churn, NPS                         │
│   UNIT ECONOMICS  → LTV, CAC, LTV:CAC Ratio                    │
│   PIPELINE        → Leads, Conversion, Deal Size               │
│   DELIVERY        → Utilization, Margin, On-Time               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Revenue Metrics

### Monthly Recurring Revenue (MRR)
```
MRR BREAKDOWN

Starting MRR:           $[X]
+ New MRR:              $[X]  (new clients)
+ Expansion MRR:        $[X]  (upsells)
- Contraction MRR:      $[X]  (downgrades)
- Churned MRR:          $[X]  (lost clients)
= Ending MRR:           $[X]

Net MRR Growth:         $[X] ([X]%)
```

### Revenue Dashboard Template
```markdown
## Revenue Dashboard: [Month/Year]

### Summary
| Metric | Current | Previous | Change |
|--------|---------|----------|--------|
| MRR | $[X] | $[X] | [+/-]% |
| ARR | $[X] | $[X] | [+/-]% |
| Revenue (month) | $[X] | $[X] | [+/-]% |

### MRR Movement
| Category | Amount | % of Starting |
|----------|--------|---------------|
| Starting MRR | $[X] | - |
| New | +$[X] | [X]% |
| Expansion | +$[X] | [X]% |
| Contraction | -$[X] | [X]% |
| Churn | -$[X] | [X]% |
| **Ending MRR** | **$[X]** | - |

### Revenue by Type
| Type | Amount | % |
|------|--------|---|
| Recurring (SaaS) | $[X] | [X]% |
| Projects | $[X] | [X]% |
| Consulting | $[X] | [X]% |
| **Total** | **$[X]** | 100% |

### Top Clients
| Client | MRR | % of Total |
|--------|-----|------------|
| [Client 1] | $[X] | [X]% |
| [Client 2] | $[X] | [X]% |
| [Client 3] | $[X] | [X]% |
```

## Client Health Score

```markdown
## Client Health Score: [Client Name]

**Overall Score**: [X]/100 🟢🟡🔴

### Scoring Components

| Factor | Weight | Score | Weighted |
|--------|--------|-------|----------|
| Product Usage | 25% | [X]/10 | [X] |
| Engagement | 25% | [X]/10 | [X] |
| Relationship | 20% | [X]/10 | [X] |
| Growth Potential | 15% | [X]/10 | [X] |
| Payment History | 15% | [X]/10 | [X] |
| **Total** | 100% | - | **[X]** |

### Health Indicators

**🟢 Positive Signals**
- [Positive indicator 1]
- [Positive indicator 2]

**🔴 Risk Signals**
- [Risk indicator 1]
- [Risk indicator 2]

### Recommended Actions
1. [Action 1]
2. [Action 2]
```

### Health Score Calculation
```
SCORING RUBRIC

PRODUCT USAGE (0-10)
├── 10: Daily active, power user
├── 7: Weekly active, core features
├── 4: Monthly active, basic features
└── 1: Rarely uses, at risk

ENGAGEMENT (0-10)
├── 10: Proactive, provides feedback
├── 7: Responsive, attends meetings
├── 4: Slow to respond
└── 1: Unresponsive, avoids calls

RELATIONSHIP (0-10)
├── 10: Champion, refers others
├── 7: Satisfied, good rapport
├── 4: Neutral, transactional
└── 1: Frustrated, complaints

GROWTH POTENTIAL (0-10)
├── 10: Large org, many opportunities
├── 7: Room to expand
├── 4: Limited expansion
└── 1: At capacity/shrinking

PAYMENT (0-10)
├── 10: Early/on-time, annual upfront
├── 7: On-time, monthly
├── 4: Occasionally late
└── 1: Chronic late, disputes
```

## Unit Economics

```markdown
## Unit Economics: [Month/Year]

### Customer Metrics

| Metric | Value | Benchmark |
|--------|-------|-----------|
| LTV (Lifetime Value) | $[X] | - |
| CAC (Acquisition Cost) | $[X] | - |
| LTV:CAC Ratio | [X]:1 | 3:1+ |
| Payback Period | [X] months | 12 mo |

### Calculations

**LTV**
= Average MRR × Gross Margin × Average Lifespan
= $[X] × [X]% × [X] months
= **$[X]**

**CAC**
= (Sales + Marketing Costs) / New Customers
= $[X] / [X]
= **$[X]**

**LTV:CAC Ratio**
= LTV / CAC
= $[X] / $[X]
= **[X]:1**

### Cohort Analysis

| Cohort | Month 1 | Month 3 | Month 6 | Month 12 |
|--------|---------|---------|---------|----------|
| 2024-Q1 | 100% | [X]% | [X]% | [X]% |
| 2024-Q2 | 100% | [X]% | [X]% | - |
| 2024-Q3 | 100% | [X]% | - | - |
```

## Pipeline Metrics

```markdown
## Pipeline Dashboard: [Month/Year]

### Funnel Metrics

| Stage | Count | Value | Conversion |
|-------|-------|-------|------------|
| Leads | [X] | - | - |
| Qualified | [X] | - | [X]% |
| Proposal | [X] | $[X] | [X]% |
| Negotiation | [X] | $[X] | [X]% |
| Won | [X] | $[X] | [X]% |
| Lost | [X] | $[X] | - |

### Pipeline Health

| Metric | Value | Target |
|--------|-------|--------|
| Total Pipeline | $[X] | $[X] |
| Weighted Pipeline | $[X] | $[X] |
| Avg Deal Size | $[X] | $[X] |
| Avg Sales Cycle | [X] days | [X] days |
| Win Rate | [X]% | [X]% |

### By Source

| Source | Leads | Won | Revenue | ROI |
|--------|-------|-----|---------|-----|
| Referral | [X] | [X] | $[X] | [X]x |
| Inbound | [X] | [X] | $[X] | [X]x |
| Outbound | [X] | [X] | $[X] | [X]x |
```

## Delivery Metrics

```markdown
## Delivery Metrics: [Month/Year]

### Utilization

| Team Member | Available | Billable | Utilization |
|-------------|-----------|----------|-------------|
| [Name] | [X]h | [X]h | [X]% |
| [Name] | [X]h | [X]h | [X]% |
| **Team** | **[X]h** | **[X]h** | **[X]%** |

Target: 70-80%

### Project Margins

| Project | Revenue | Cost | Margin | % |
|---------|---------|------|--------|---|
| [Project 1] | $[X] | $[X] | $[X] | [X]% |
| [Project 2] | $[X] | $[X] | $[X] | [X]% |
| **Total** | **$[X]** | **$[X]** | **$[X]** | **[X]%** |

### On-Time Delivery

| Metric | This Month | YTD |
|--------|------------|-----|
| Projects On-Time | [X]% | [X]% |
| Milestones On-Time | [X]% | [X]% |
| Budget Adherence | [X]% | [X]% |
```

## Monthly Business Review Template

```markdown
# Monthly Business Review: [Month Year]

## Executive Summary
[2-3 sentences on overall health]

## Scorecard

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Revenue | $[X] | $[X] | 🟢🟡🔴 |
| MRR | $[X] | $[X] | 🟢🟡🔴 |
| New Clients | [X] | [X] | 🟢🟡🔴 |
| Churn | [X]% | [X]% | 🟢🟡🔴 |
| NPS | [X] | [X] | 🟢🟡🔴 |
| Utilization | [X]% | [X]% | 🟢🟡🔴 |

## Highlights
- [Key win 1]
- [Key win 2]

## Challenges
- [Challenge 1]
- [Challenge 2]

## Actions for Next Month
1. [Action 1]
2. [Action 2]
```

## Output Format

```
⚡ SKILL_ACTIVATED: #METR-9Z5A

## Business Metrics: [Period]

### Revenue Summary
| Metric | Value | Change |
|--------|-------|--------|
| MRR | $[X] | [+/-]% |
| Revenue | $[X] | [+/-]% |

### Client Health
| Score | Count | % |
|-------|-------|---|
| 🟢 Healthy | [X] | [X]% |
| 🟡 At Risk | [X] | [X]% |
| 🔴 Critical | [X] | [X]% |

### Key Ratios
| Metric | Value | Status |
|--------|-------|--------|
| LTV:CAC | [X]:1 | 🟢🟡🔴 |
| Churn | [X]% | 🟢🟡🔴 |
| NPS | [X] | 🟢🟡🔴 |

### Actions Needed
1. [Priority action 1]
2. [Priority action 2]
```

## Common Mistakes

- Vanity metrics (followers, downloads)
- Not tracking churn properly
- Ignoring leading indicators
- No cohort analysis
- Mixing revenue types
- Not segmenting clients
