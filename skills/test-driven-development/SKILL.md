---
name: test-driven-development
description: Use when writing new features, fixing bugs, or user mentions "tdd", "test first", "teste primeiro", "red green refactor". Enforces RED-GREEN-REFACTOR cycle.
---

# Test-Driven Development

Implements strict TDD cycle: write failing test → make it pass → refactor.

## When to Use

- Creating new features or functions
- Fixing bugs (write test that reproduces first)
- User mentions: tdd, test first, teste primeiro, red-green
- NOT when: exploring/prototyping, one-off scripts

## The TDD Cycle

```
┌─────────────────────────────────────────────────┐
│  1. RED: Write failing test                     │
│     - Test MUST fail first                      │
│     - If it passes, test is wrong               │
├─────────────────────────────────────────────────┤
│  2. GREEN: Minimum code to pass                 │
│     - Write ONLY enough to pass                 │
│     - No extra features                         │
│     - Ugly code is OK here                      │
├─────────────────────────────────────────────────┤
│  3. REFACTOR: Clean up                          │
│     - Tests must stay green                     │
│     - Remove duplication                        │
│     - Improve names, structure                  │
└─────────────────────────────────────────────────┘
```

## Instructions

### Before Writing Any Code

1. **Understand the requirement** - What behavior do we need?
2. **Write the test first** - Describe expected behavior
3. **Run test - it MUST fail** - If it passes, something is wrong
4. **Commit the failing test** - `test: add failing test for X`

### Making It Pass

1. **Write minimum code** - Just enough to pass
2. **Run test - it MUST pass** - If not, fix the code
3. **Commit passing code** - `feat: implement X`

### Refactoring

1. **Tests still green?** - Run before and after each change
2. **Remove duplication** - DRY principle
3. **Improve readability** - Better names, simpler logic
4. **Commit refactor** - `refactor: clean up X`

## Testing Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Testing implementation | Breaks on refactor | Test behavior only |
| Giant test files | Hard to maintain | One concept per test |
| Test interdependence | Order matters | Each test isolated |
| Ignoring edge cases | Bugs in production | Test boundaries |
| Mocking everything | Tests pass, code fails | Integration tests too |
| No assertion | Test always passes | Assert expected outcome |

## Test Structure (AAA Pattern)

```python
def test_user_can_login_with_valid_credentials():
    # Arrange - Set up test data
    user = create_user(email="test@example.com", password="secure123")

    # Act - Execute the behavior
    result = login(email="test@example.com", password="secure123")

    # Assert - Verify the outcome
    assert result.success is True
    assert result.user.id == user.id
```

## For AI Agents (Pydantic AI / LangGraph)

```python
# Test agent behavior, not internals
def test_agent_extracts_entities():
    # Arrange
    agent = EntityExtractorAgent()
    text = "John works at Acme Corp in New York"

    # Act
    result = agent.run(text)

    # Assert
    assert "John" in result.people
    assert "Acme Corp" in result.organizations
    assert "New York" in result.locations
```

## For Database (Postgres/Supabase)

```python
# Use transactions for isolation
@pytest.fixture
def db_session():
    with database.transaction() as tx:
        yield tx
        tx.rollback()  # Always clean up

def test_user_creation(db_session):
    # Arrange & Act
    user = create_user(db_session, name="Test")

    # Assert
    assert user.id is not None
    assert db_session.query(User).count() == 1
```

## Output Format

When TDD is active, structure responses as:

```
## RED Phase
- Test: `test_xxx.py::test_feature_does_something`
- Expected: [behavior]
- Status: FAILING ✗

## GREEN Phase
- Implementation: [file:line]
- Status: PASSING ✓

## REFACTOR Phase
- Changes: [what was improved]
- Tests: STILL GREEN ✓
```

## Common Mistakes

- Writing code before test (defeats the purpose)
- Test passes on first run (test is wrong or testing nothing)
- Testing private methods (test public interface)
- Skipping refactor phase (tech debt accumulates)
- Not running tests after each change
