---
name: ai-product-strategy
description: Use when defining AI product strategy, MVP scoping, roadmaps. Activates for "estratégia AI", "produto AI", "MVP AI", "roadmap produto", "AI use case".
chain: pricing-strategy
---

# AI Product Strategy

Expert in AI product strategy, identifying AI use cases, MVP definition, and product roadmaps for AI-powered solutions.

## When to Use

- Defining AI product vision
- Identifying AI opportunities
- Scoping AI MVP
- User says: estratégia AI, produto AI, MVP, roadmap
- CHAIN: → pricing-strategy (after product defined)
- NOT when: building the product (use graph-agent)

## AI Opportunity Framework

```
┌─────────────────────────────────────────────────────────────────┐
│                    AI OPPORTUNITY ASSESSMENT                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   1. PROBLEM FIT   → Is AI the right solution?                 │
│   2. DATA READY    → Do we have the data?                      │
│   3. FEASIBILITY   → Can we build it?                          │
│   4. VALUE CLEAR   → Is ROI demonstrable?                      │
│   5. RISK MANAGED  → Can we handle failures?                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## AI Use Case Identification

### Good Candidates for AI
```
AUTOMATION
├── Repetitive tasks
├── Rule-based decisions
├── Data entry/extraction
└── Categorization/tagging

AUGMENTATION
├── Content creation/editing
├── Research/summarization
├── Decision support
└── Personalization

ANALYSIS
├── Pattern recognition
├── Anomaly detection
├── Prediction/forecasting
└── Sentiment analysis

INTERACTION
├── Customer support
├── Information retrieval
├── Onboarding/training
└── Accessibility
```

### AI Fit Assessment
```markdown
## AI Fit Assessment: [Use Case]

### Problem Statement
[What are we solving?]

### Is AI The Right Solution?

| Question | Answer | Notes |
|----------|--------|-------|
| Is there a pattern to learn? | Yes/No | [Details] |
| Is human-level accuracy acceptable? | Yes/No | [Details] |
| Is the task repetitive? | Yes/No | [Details] |
| Is the cost of errors manageable? | Yes/No | [Details] |
| Does it require reasoning? | Yes/No | [Details] |

### AI Approach Options

| Approach | Complexity | Cost | Accuracy |
|----------|------------|------|----------|
| Rules-based | Low | $ | High (for simple) |
| ML/Classification | Medium | $$ | Medium-High |
| LLM (prompt) | Low | $$$ | Medium |
| LLM (fine-tuned) | High | $$$$ | High |
| Hybrid | Medium | $$$ | High |

### Recommendation
[Which approach and why]
```

## Build vs Buy Matrix

```markdown
## Build vs Buy Analysis: [Solution]

### Options Evaluated

| Option | Pros | Cons | Cost | Time |
|--------|------|------|------|------|
| Build Custom | Full control, IP | Dev time, maintenance | $[X]/mo dev | [X] months |
| Use API (OpenAI, etc.) | Fast, scales | Dependency, cost at scale | $[X]/mo | [X] weeks |
| Buy Solution | Fast, supported | Less flexible, vendor lock | $[X]/mo | [X] days |
| Open Source | Free, control | Hosting, maintenance | $[X]/mo infra | [X] weeks |

### Decision Criteria

| Criteria | Weight | Build | API | Buy | Open Source |
|----------|--------|-------|-----|-----|-------------|
| Time to market | [X]% | [1-5] | [1-5] | [1-5] | [1-5] |
| Customization | [X]% | [1-5] | [1-5] | [1-5] | [1-5] |
| Total cost (1yr) | [X]% | [1-5] | [1-5] | [1-5] | [1-5] |
| Scalability | [X]% | [1-5] | [1-5] | [1-5] | [1-5] |
| **Weighted Score** | 100% | **[X]** | **[X]** | **[X]** | **[X]** |

### Recommendation
[Which option and why]
```

## AI MVP Definition

```markdown
# AI MVP: [Product Name]

## Vision
[One-sentence product vision]

## Success Metric
[Single metric that defines success]

## Target User
[Specific user persona]

## Core Value Proposition
[What problem solved, how AI helps]

---

## MVP Scope

### Must Have (MVP)
| Feature | AI Component | Priority |
|---------|--------------|----------|
| [Feature 1] | [LLM for X] | P0 |
| [Feature 2] | [Classification] | P0 |
| [Feature 3] | [Extraction] | P0 |

### V1.1 (Post-launch)
| Feature | AI Component | Priority |
|---------|--------------|----------|
| [Feature 4] | [Fine-tuning] | P1 |
| [Feature 5] | [Multi-modal] | P1 |

### Future (Backlog)
| Feature | AI Component | Priority |
|---------|--------------|----------|
| [Feature 6] | [Agents] | P2 |
| [Feature 7] | [Custom model] | P2 |

---

## Technical Approach

### AI Architecture
```
[User Input] → [Preprocessing] → [AI Model] → [Post-processing] → [Output]
```

### Model Selection
| Component | Model/Approach | Reason |
|-----------|----------------|--------|
| [Task 1] | Claude/GPT-4 | [Why] |
| [Task 2] | Embedding + Search | [Why] |
| [Task 3] | Custom classifier | [Why] |

### Data Requirements
| Data Needed | Source | Status |
|-------------|--------|--------|
| [Data 1] | [Source] | [Have/Need] |
| [Data 2] | [Source] | [Have/Need] |

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| AI accuracy too low | High | Human fallback, feedback loop |
| Cost too high | Medium | Caching, model optimization |
| Latency issues | Medium | Async processing, streaming |
| Hallucination | High | Grounding, validation |

---

## MVP Milestones

| Week | Milestone | Deliverable |
|------|-----------|-------------|
| 1-2 | Prototype | Working prompt/model |
| 3-4 | Alpha | Core feature complete |
| 5-6 | Beta | User testing ready |
| 7-8 | Launch | Production release |

---

## Success Criteria

| Metric | MVP Target | V1 Target |
|--------|------------|-----------|
| Accuracy | [X]% | [Y]% |
| Latency | [X]s | [Y]s |
| User satisfaction | [X]/5 | [Y]/5 |
| Cost per use | $[X] | $[Y] |
```

## Product Roadmap Template

```markdown
# AI Product Roadmap: [Product Name]

## Vision
[Where we're headed]

## Now (This Quarter)
### [Initiative 1]
- **Goal**: [What we're achieving]
- **Features**: [List of features]
- **AI Focus**: [What AI enables]
- **Success Metric**: [How we measure]

### [Initiative 2]
[Same structure]

## Next (Next Quarter)
### [Initiative 3]
[Same structure]

## Later (6+ months)
### [Initiative 4]
[Same structure]

---

## Roadmap View

```
      Q1         Q2         Q3         Q4
      ├──────────┼──────────┼──────────┤
MVP   [████████░░░░░░░░░░░░░░░░░░░░░░░░]
V1.0             [████████░░░░░░░░░░░░░]
V2.0                        [████████░░]
```

---

## Dependencies

| Initiative | Depends On | Owner |
|------------|------------|-------|
| [Feature A] | [Data pipeline] | [Team] |
| [Feature B] | [Model training] | [Team] |
```

## Output Format

```
⚡ SKILL_ACTIVATED: #AIST-2B6C

## AI Product Strategy: [Product]

### Opportunity Assessment
| Criteria | Score | Notes |
|----------|-------|-------|
| Problem fit | [X]/5 | [Note] |
| Data ready | [X]/5 | [Note] |
| Feasibility | [X]/5 | [Note] |
| Value clear | [X]/5 | [Note] |

### Recommended Approach
**[Build/Buy/API/Hybrid]**
Reason: [Why this approach]

### MVP Definition
| Feature | AI Component | Priority |
|---------|--------------|----------|
| [Feature] | [AI type] | P0 |

### Key Risks
| Risk | Mitigation |
|------|------------|
| [Risk] | [Plan] |

### Timeline
[High-level milestones]

→ CHAIN: Ready for pricing-strategy
```

## Common Mistakes

- AI for AI's sake (no real problem)
- Underestimating data needs
- Over-scoping MVP
- Ignoring edge cases
- No human fallback
- Not measuring AI performance
- Forgetting about cost at scale
