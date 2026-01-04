---
name: pricing-strategy
description: Use when defining pricing for AI/software products. Activates for "precificar", "pricing", "quanto cobrar", "modelo de preço", "price point".
chain: proposal-builder
---

# Pricing Strategy

Expert in pricing AI products, SaaS, and software services. Helps define value-based pricing with market intelligence.

## When to Use

- Defining pricing for new product/service
- Reviewing existing pricing strategy
- Pricing AI/LLM-based features
- User says: precificar, pricing, quanto cobrar
- CHAIN: → proposal-builder (after defining pricing)
- NOT when: market research (use brainstorming-business)

## Pricing Models

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRICING MODELS                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   USAGE-BASED      → Pay per API call, token, transaction      │
│   SEAT-BASED       → Pay per user/license                      │
│   TIERED           → Feature bundles at price points           │
│   FLAT-RATE        → Single price, unlimited use               │
│   HYBRID           → Base + usage overage                      │
│   VALUE-BASED      → Price tied to customer outcomes           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## AI Product Pricing

### Token/API Pricing
```
COST STRUCTURE
├── LLM API costs (input/output tokens)
├── Infrastructure (compute, storage)
├── Development amortization
├── Support overhead
└── Margin target

PRICING FORMULA
Price per call = (
  (avg_input_tokens × input_cost) +
  (avg_output_tokens × output_cost) +
  infra_cost
) × margin_multiplier

MARGIN GUIDELINES
├── Commodity API: 1.5-2x cost
├── Value-add API: 3-5x cost
├── Enterprise: 5-10x cost
└── Custom/unique: 10x+ cost
```

### SaaS Tiers
```
TIER STRUCTURE
┌─────────────┬─────────────┬─────────────┐
│    FREE     │     PRO     │ ENTERPRISE  │
├─────────────┼─────────────┼─────────────┤
│ Acquisition │   Revenue   │ High-touch  │
│ 0% conv     │   Target    │  Expansion  │
│ Limited     │   Core      │ Full suite  │
└─────────────┴─────────────┴─────────────┘

FREE TIER PURPOSE
├── Acquisition funnel
├── Product-led growth
├── Market awareness
└── NOT: giving away value

PRO TIER PURPOSE
├── Core revenue driver
├── Self-serve conversion
├── 80% of customers
└── Price anchor

ENTERPRISE PURPOSE
├── Revenue expansion
├── Strategic accounts
├── Custom needs
└── 80% of revenue (often)
```

## Value-Based Pricing Process

```
┌─────────────────────────────────────────────┐
│  1. IDENTIFY VALUE                           │
│     What outcome does customer get?          │
├─────────────────────────────────────────────┤
│  2. QUANTIFY VALUE                           │
│     How much is that worth in $?             │
├─────────────────────────────────────────────┤
│  3. CAPTURE PORTION                          │
│     Price at 10-30% of value created         │
├─────────────────────────────────────────────┤
│  4. VALIDATE                                 │
│     Test willingness to pay                  │
└─────────────────────────────────────────────┘
```

### Value Quantification Examples
```
COST SAVINGS
├── "Saves 10 hours/week"
├── 10h × $50/h × 4 weeks = $2,000/mo value
└── Price at $200-400/mo (10-20%)

REVENUE INCREASE
├── "Increases conversion by 5%"
├── 5% × $100K/mo revenue = $5,000/mo value
└── Price at $500-1,500/mo (10-30%)

RISK REDUCTION
├── "Prevents $50K/year compliance issues"
├── Value = $50K × probability of issue
└── Price at percentage of expected loss
```

## Pricing Calculator Template

```markdown
## Pricing Analysis: [Product/Service]

### Cost Structure

| Component | Cost/Unit | Volume | Monthly |
|-----------|-----------|--------|---------|
| LLM API | $X/1K tokens | [vol] | $[calc] |
| Infrastructure | $X/GB | [vol] | $[calc] |
| Support | $X/ticket | [vol] | $[calc] |
| **Total Cost** | | | **$[sum]** |

### Value Delivered

| Value Type | Metric | $ Value |
|------------|--------|---------|
| Time saved | [X] hours/mo | $[calc] |
| Revenue increase | [X]% | $[calc] |
| Cost avoided | [X]/mo | $[calc] |
| **Total Value** | | **$[sum]** |

### Pricing Recommendation

| Model | Price | Margin | Value Capture |
|-------|-------|--------|---------------|
| Cost+ (2x) | $[X] | 50% | [Y]% |
| Value (10%) | $[X] | [Z]% | 10% |
| Market match | $[X] | [Z]% | [Y]% |

**Recommended: [Model] at $[Price]**

### Tier Structure

| Tier | Price | Features | Target |
|------|-------|----------|--------|
| Free | $0 | [limits] | Acquisition |
| Pro | $[X]/mo | [features] | SMB |
| Enterprise | $[X]/mo | [features] | Large co |
```

## Consulting/Services Pricing

### Hourly vs Project vs Retainer
```
HOURLY
├── Pros: Simple, fair
├── Cons: Punishes efficiency
├── When: Unclear scope, discovery

PROJECT (Fixed)
├── Pros: Predictable, value-aligned
├── Cons: Scope creep risk
├── When: Clear deliverables

RETAINER
├── Pros: Predictable revenue
├── Cons: Capacity lock
├── When: Ongoing relationship

VALUE-BASED
├── Pros: Aligned incentives
├── Cons: Hard to quantify
├── When: Clear ROI metrics
```

### Rate Guidelines (Brazil - AI/Software)
```
SENIOR DEVELOPER
├── Hourly: R$150-300/h
├── Daily: R$1,200-2,400/d
└── Monthly: R$25K-50K

AI SPECIALIST
├── Hourly: R$200-500/h
├── Daily: R$1,600-4,000/d
└── Monthly: R$35K-80K

CONSULTING
├── Strategy: R$500-1,500/h
├── Implementation: R$250-500/h
└── Training: R$400-800/h

MULTIPLIERS
├── Enterprise client: 1.5-2x
├── Urgent/deadline: 1.5x
├── Weekend/holiday: 2x
└── Equity included: 0.5-0.7x
```

## Pricing Presentation

```markdown
### Option A: Starter
**$X/month**
- [Feature 1]
- [Feature 2]
- [Limit 1]
Best for: [segment]

### Option B: Professional (Recommended)
**$X/month** ← *Most popular*
- Everything in Starter
- [Feature 3]
- [Feature 4]
- [Higher limit]
Best for: [segment]

### Option C: Enterprise
**Custom pricing**
- Everything in Professional
- [Feature 5]
- [Feature 6]
- Unlimited [X]
- Dedicated support
Best for: [segment]
```

## Output Format

```
⚡ SKILL_ACTIVATED: #PRIC-4N8Q

## Pricing Strategy: [Product]

### Cost Analysis
| Component | Monthly Cost |
|-----------|--------------|
| [Item] | $[X] |
| **Total** | **$[sum]** |

### Value Analysis
| Value Type | Monthly Value |
|------------|---------------|
| [Type] | $[X] |
| **Total** | **$[sum]** |

### Recommended Pricing

**Model**: [Model type]
**Price Point**: $[X]/[period]
**Margin**: [X]%
**Value Capture**: [X]%

### Tier Structure
[Tier table]

### Validation Steps
1. [ ] Customer interviews (5+)
2. [ ] Competitor check
3. [ ] A/B test landing page
4. [ ] Soft launch

→ CHAIN: Ready for proposal-builder
```

## Common Mistakes

- Pricing on cost only (ignoring value)
- Too many tiers (confusing)
- Free tier too generous
- No price anchoring
- Not testing willingness to pay
- Ignoring competitor context
