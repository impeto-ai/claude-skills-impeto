---
name: testing-strategy
description: Use when designing test strategies, improving coverage, setting up testing frameworks. Activates for "testing strategy", "test coverage", "test pyramid", "how to test", "which tests".
chain: none
---

# Testing Strategy

Expert in test architecture, coverage strategies, and testing best practices.

## When to Use

- Designing test strategy for a project
- Deciding what/how to test
- Improving test coverage
- User says: testing strategy, test pyramid, coverage
- NOT when: writing specific tests (use test-driven-development)

## Test Pyramid

```
                    ╱╲
                   ╱  ╲
                  ╱ E2E╲        Few, slow, expensive
                 ╱──────╲
                ╱        ╲
               ╱Integration╲    Some, medium speed
              ╱────────────╲
             ╱              ╲
            ╱   Unit Tests   ╲  Many, fast, cheap
           ╱──────────────────╲
```

## Test Types & When to Use

| Type | What | When | Speed | Cost |
|------|------|------|-------|------|
| Unit | Single function/class | Business logic | Fast | Low |
| Integration | Components together | APIs, DB queries | Medium | Medium |
| E2E | Full user flows | Critical paths | Slow | High |
| Contract | API contracts | Microservices | Fast | Low |
| Performance | Load, stress | Before release | Slow | High |
| Security | Vulnerabilities | Continuous | Medium | Medium |

## Coverage Targets

```
┌─────────────────────────────────────────────────────────────────┐
│                    COVERAGE STRATEGY                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   CRITICAL PATH (auth, payments)     → 90%+ coverage           │
│   BUSINESS LOGIC (services, models)  → 80%+ coverage           │
│   INFRASTRUCTURE (utils, helpers)    → 70%+ coverage           │
│   UI COMPONENTS                      → 60%+ (snapshot + key)   │
│                                                                 │
│   OVERALL TARGET: 80%                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Unit Testing Patterns

### Arrange-Act-Assert (AAA)
```python
def test_calculate_total_with_discount():
    # Arrange
    order = Order(items=[Item(price=100), Item(price=50)])
    discount = Discount(percent=10)

    # Act
    total = calculate_total(order, discount)

    # Assert
    assert total == 135.0  # (100 + 50) * 0.9
```

### Given-When-Then (BDD)
```python
def test_user_can_checkout():
    # Given a user with items in cart
    user = create_user_with_cart(items=3)

    # When they checkout
    result = checkout_service.process(user)

    # Then order is created
    assert result.status == "completed"
    assert result.order_id is not None
```

### Test Naming Convention
```
test_<unit>_<scenario>_<expected>

Examples:
- test_calculate_total_empty_cart_returns_zero
- test_user_login_invalid_password_raises_error
- test_order_process_insufficient_stock_fails
```

## Mocking Strategy

### What to Mock
```
✓ MOCK:
- External APIs (Stripe, SendGrid)
- Database (for unit tests)
- Time/Date
- Random values
- File system
- Network calls

✗ DON'T MOCK:
- The unit under test
- Simple value objects
- Pure functions
- Your own code (in integration tests)
```

### Mocking Examples

```python
# Python with pytest
from unittest.mock import Mock, patch

@patch('services.email.send_email')
def test_order_sends_confirmation(mock_send):
    order_service.create_order(order)
    mock_send.assert_called_once_with(
        to=order.customer_email,
        template='order_confirmation'
    )

# With fixtures
@pytest.fixture
def mock_db():
    with patch('db.session') as mock:
        mock.query.return_value.filter.return_value.first.return_value = User(id=1)
        yield mock
```

```typescript
// TypeScript with Jest
jest.mock('./emailService');

test('order sends confirmation email', async () => {
  const mockSend = jest.mocked(sendEmail);

  await orderService.createOrder(order);

  expect(mockSend).toHaveBeenCalledWith({
    to: order.customerEmail,
    template: 'order_confirmation'
  });
});
```

## Integration Testing

### API Testing
```python
# FastAPI with TestClient
from fastapi.testclient import TestClient

def test_create_user_api():
    client = TestClient(app)

    response = client.post("/users", json={
        "email": "test@example.com",
        "name": "Test User"
    })

    assert response.status_code == 201
    assert response.json()["email"] == "test@example.com"
```

### Database Testing
```python
# With test database
@pytest.fixture
def test_db():
    # Setup: Create test database
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    session = Session(engine)

    yield session

    # Teardown
    session.close()

def test_user_repository(test_db):
    repo = UserRepository(test_db)
    user = repo.create(User(email="test@test.com"))

    found = repo.find_by_id(user.id)
    assert found.email == "test@test.com"
```

## E2E Testing

### Playwright Example
```typescript
test('user can complete checkout', async ({ page }) => {
  // Login
  await page.goto('/login');
  await page.fill('[name="email"]', 'user@test.com');
  await page.fill('[name="password"]', 'password');
  await page.click('button[type="submit"]');

  // Add to cart
  await page.goto('/products/1');
  await page.click('button:text("Add to Cart")');

  // Checkout
  await page.goto('/checkout');
  await page.fill('[name="card"]', '4242424242424242');
  await page.click('button:text("Pay")');

  // Verify
  await expect(page).toHaveURL(/\/order\/\d+/);
  await expect(page.locator('.order-status')).toHaveText('Confirmed');
});
```

## Test Configuration

### pytest (Python)
```ini
# pytest.ini
[pytest]
testpaths = tests
python_files = test_*.py
python_functions = test_*
addopts = -v --cov=src --cov-report=html --cov-fail-under=80
markers =
    slow: marks tests as slow
    integration: marks tests as integration
```

### Jest (TypeScript)
```javascript
// jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/index.ts'
  ]
};
```

## Test Organization

```
tests/
├── unit/
│   ├── services/
│   │   ├── test_order_service.py
│   │   └── test_user_service.py
│   └── models/
│       └── test_order.py
├── integration/
│   ├── api/
│   │   └── test_orders_api.py
│   └── repositories/
│       └── test_user_repository.py
├── e2e/
│   └── test_checkout_flow.py
├── fixtures/
│   └── users.py
└── conftest.py
```

## Output Format

```
⚡ SKILL_ACTIVATED: #TEST-9C2M

## Testing Strategy: [Project/Feature]

### Test Pyramid Distribution
- Unit: X tests (target: 70%)
- Integration: Y tests (target: 25%)
- E2E: Z tests (target: 5%)

### Coverage Targets
| Component | Current | Target |
|-----------|---------|--------|
| [component] | X% | Y% |

### Recommended Tests
1. Unit: [what to test]
2. Integration: [what to test]
3. E2E: [critical paths]

### Test Files to Create
- `tests/unit/test_[name].py`
- `tests/integration/test_[name].py`
```

## Common Mistakes

- Testing implementation, not behavior
- Too many E2E tests (slow, flaky)
- Not testing edge cases
- Mocking too much or too little
- No test isolation (shared state)
- Flaky tests (timing, order-dependent)
