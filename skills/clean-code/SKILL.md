---
name: clean-code
description: Use when refactoring code, improving code quality, applying SOLID principles. Activates for "clean code", "refactor", "SOLID", "code smell", "technical debt".
chain: code-reviewer
---

# Clean Code

Expert in SOLID principles, refactoring patterns, and code quality improvement.

## When to Use

- Refactoring existing code
- Improving code structure
- Eliminating code smells
- User says: clean code, refactor, SOLID, code smell
- NOT when: writing new features (focus on functionality first)

## SOLID Principles

```
┌─────────────────────────────────────────────────────────────────┐
│                      SOLID PRINCIPLES                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   S - Single Responsibility  → One reason to change            │
│   O - Open/Closed           → Open for extension, closed mod   │
│   L - Liskov Substitution   → Subtypes must be substitutable   │
│   I - Interface Segregation → Many specific interfaces         │
│   D - Dependency Inversion  → Depend on abstractions           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Refactoring Patterns

### Extract Method
```python
# BEFORE
def process_order(order):
    # validate
    if not order.items:
        raise ValueError("Empty order")
    if not order.customer:
        raise ValueError("No customer")
    # calculate
    total = sum(item.price * item.qty for item in order.items)
    tax = total * 0.1
    # save
    db.save(order)
    return total + tax

# AFTER
def process_order(order):
    validate_order(order)
    total = calculate_total(order)
    save_order(order)
    return total

def validate_order(order):
    if not order.items:
        raise ValueError("Empty order")
    if not order.customer:
        raise ValueError("No customer")

def calculate_total(order):
    subtotal = sum(item.price * item.qty for item in order.items)
    return subtotal * 1.1  # with tax

def save_order(order):
    db.save(order)
```

### Replace Conditional with Polymorphism
```python
# BEFORE
def calculate_shipping(order):
    if order.type == "express":
        return order.weight * 10
    elif order.type == "standard":
        return order.weight * 5
    elif order.type == "overnight":
        return order.weight * 20

# AFTER
class ShippingStrategy(Protocol):
    def calculate(self, weight: float) -> float: ...

class ExpressShipping:
    def calculate(self, weight: float) -> float:
        return weight * 10

class StandardShipping:
    def calculate(self, weight: float) -> float:
        return weight * 5

def calculate_shipping(order, strategy: ShippingStrategy):
    return strategy.calculate(order.weight)
```

### Dependency Injection
```python
# BEFORE (tight coupling)
class OrderService:
    def __init__(self):
        self.db = PostgresDB()  # Hard dependency
        self.mailer = SMTPMailer()

# AFTER (loose coupling)
class OrderService:
    def __init__(self, db: Database, mailer: Mailer):
        self.db = db
        self.mailer = mailer

# Usage
service = OrderService(
    db=PostgresDB(),
    mailer=SMTPMailer()
)
```

## Code Smells & Fixes

| Smell | Detection | Fix |
|-------|-----------|-----|
| Long Method | >20 lines | Extract Method |
| God Class | >300 lines, many responsibilities | Split into focused classes |
| Feature Envy | Method uses other class's data | Move method to that class |
| Data Clumps | Same params appear together | Create a class |
| Primitive Obsession | Using primitives for concepts | Create value objects |
| Switch Statements | Complex conditionals | Polymorphism |
| Duplicate Code | Copy-paste | Extract to shared function |
| Dead Code | Unused code | Delete it |

## Clean Code Checklist

```
NAMING
[ ] Variables describe content (user, not u)
[ ] Functions describe action (getUserById, not get)
[ ] Classes are nouns (OrderProcessor, not ProcessOrder)
[ ] Constants are SCREAMING_CASE
[ ] No abbreviations (config, not cfg)

FUNCTIONS
[ ] Do one thing (SRP)
[ ] Max 3 parameters (use object if more)
[ ] No side effects
[ ] Return early (guard clauses)
[ ] Max 20 lines

CLASSES
[ ] Single responsibility
[ ] Cohesive (methods use class state)
[ ] Low coupling (minimal dependencies)
[ ] Composition over inheritance

COMMENTS
[ ] Code is self-documenting
[ ] Comments explain WHY, not WHAT
[ ] No commented-out code
[ ] TODO with ticket number
```

## Refactoring Workflow

```
1. IDENTIFY
   │ Find code smell or SOLID violation
   ▼
2. TEST
   │ Ensure existing tests cover the code
   │ Add tests if missing
   ▼
3. REFACTOR
   │ Apply pattern in small steps
   │ Commit after each step
   ▼
4. VERIFY
   │ Run tests after each change
   │ Check for regressions
   ▼
5. REVIEW
   │ Chain to code-reviewer skill
```

## TypeScript/Python Patterns

### TypeScript
```typescript
// Value Object
class Email {
  private constructor(private readonly value: string) {}

  static create(email: string): Email {
    if (!email.includes('@')) throw new Error('Invalid email');
    return new Email(email);
  }

  toString(): string { return this.value; }
}

// Repository Pattern
interface UserRepository {
  findById(id: string): Promise<User | null>;
  save(user: User): Promise<void>;
}

class PostgresUserRepository implements UserRepository {
  async findById(id: string): Promise<User | null> {
    // implementation
  }
  async save(user: User): Promise<void> {
    // implementation
  }
}
```

### Python
```python
from dataclasses import dataclass
from abc import ABC, abstractmethod

# Value Object
@dataclass(frozen=True)
class Email:
    value: str

    def __post_init__(self):
        if '@' not in self.value:
            raise ValueError('Invalid email')

# Repository Pattern
class UserRepository(ABC):
    @abstractmethod
    async def find_by_id(self, id: str) -> User | None: ...

    @abstractmethod
    async def save(self, user: User) -> None: ...

class PostgresUserRepository(UserRepository):
    async def find_by_id(self, id: str) -> User | None:
        # implementation
        pass
```

## Chain Behavior

After completing refactoring:
→ AUTOMATICALLY trigger: code-reviewer
→ Pass context: Changed files and refactoring rationale

## Output Format

```
⚡ SKILL_ACTIVATED: #CLEN-7A3X

## Refactoring: [Component Name]

### Code Smells Identified
1. [Smell]: [Location] - [Impact]

### SOLID Violations
- [Principle]: [Description]

### Refactoring Plan
1. [Step 1]
2. [Step 2]

### Changes Made
| File | Before | After |
|------|--------|-------|
| [file] | [issue] | [fix] |

CHAIN → code-reviewer
```

## Common Mistakes

- Refactoring without tests
- Big bang refactoring (do small steps)
- Over-engineering (YAGNI)
- Refactoring during feature development
- Not committing after each step
