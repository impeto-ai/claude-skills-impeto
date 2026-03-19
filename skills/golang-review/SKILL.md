---
name: golang-review
description: Use when reviewing Go code, auditing PRs, or user mentions "review go", "code review golang", "revisar codigo go". Chains FROM golang-dev.
chain: none
---

# Go Code Review Specialist

Expert Go code reviewer following Google Code Review Comments, Uber Style Guide, and community best practices. Catches bugs, race conditions, and anti-patterns.

## When to Use

- Reviewing Go code before merge
- Auditing existing Go codebase
- After `golang-dev` completes implementation
- PR review checklist

## NOT When To Use

- Writing new code (use `golang-dev`)
- Non-Go projects

---

## PART 1: Review Checklist Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    GO CODE REVIEW                           │
├─────────────────────────────────────────────────────────────┤
│  1. FORMATTING      │ gofmt, goimports                      │
│  2. ERRORS          │ Handling, wrapping, sentinel          │
│  3. CONCURRENCY     │ Goroutines, channels, race            │
│  4. INTERFACES      │ Design, size, usage                   │
│  5. NAMING          │ Packages, vars, receivers             │
│  6. PERFORMANCE     │ Allocations, prealloc, escape         │
│  7. TESTING         │ Coverage, table-driven, mocks         │
│  8. SECURITY        │ Input validation, injection           │
│  9. DOCUMENTATION   │ Exported symbols, examples            │
│ 10. ARCHITECTURE    │ Package structure, dependencies       │
└─────────────────────────────────────────────────────────────┘
```

---

## PART 2: Error Handling Review

### Must Check

```go
// RED FLAG: Ignored error
result, _ := riskyOperation()  // FAIL: Error ignored

// RED FLAG: Error not wrapped
if err != nil {
    return err  // WARN: No context added
}

// RED FLAG: Double handling
if err != nil {
    log.Printf("error: %v", err)
    return err  // FAIL: Logged AND returned
}

// RED FLAG: String comparison
if err.Error() == "not found" {  // FAIL: Use errors.Is
```

### Correct Patterns

```go
// OK: Error wrapped with context
if err != nil {
    return fmt.Errorf("processing user %s: %w", userID, err)
}

// OK: Sentinel error check
if errors.Is(err, ErrNotFound) {
    return nil, ErrNotFound
}

// OK: Type assertion with errors.As
var pathErr *os.PathError
if errors.As(err, &pathErr) {
    log.Printf("path error: %s", pathErr.Path)
}
```

### Review Questions

- [ ] Are all errors checked (no `_` ignoring)?
- [ ] Are errors wrapped with meaningful context?
- [ ] Is `%w` used for wrappable errors?
- [ ] Are sentinel errors defined at package level?
- [ ] Is error handling happening only once (not log + return)?
- [ ] Are `errors.Is`/`errors.As` used instead of string comparison?

---

## PART 3: Concurrency Review (CRITICAL)

### Goroutine Leaks

```go
// RED FLAG: Goroutine without termination plan
go func() {
    for {
        processItem(<-ch)  // FAIL: No exit condition
    }
}()

// RED FLAG: Blocked goroutine
go func() {
    ch <- result  // FAIL: May block forever if no receiver
}()
```

### Correct Patterns

```go
// OK: Goroutine with context cancellation
go func() {
    for {
        select {
        case <-ctx.Done():
            return  // Clean exit
        case item := <-ch:
            processItem(item)
        }
    }
}()

// OK: WaitGroup for coordination
var wg sync.WaitGroup
for _, item := range items {
    wg.Add(1)
    go func(i Item) {
        defer wg.Done()
        process(i)
    }(item)  // NOTE: Loop variable captured!
}
wg.Wait()
```

### Race Conditions

```go
// RED FLAG: Shared state without protection
var counter int
for i := 0; i < 10; i++ {
    go func() {
        counter++  // FAIL: Data race
    }()
}

// RED FLAG: Map concurrent access
var cache = make(map[string]Value)
go func() { cache["key"] = value }()  // FAIL: Concurrent map write
go func() { _ = cache["key"] }()      // FAIL: Concurrent map read
```

### Correct Patterns

```go
// OK: Mutex protection
var (
    mu      sync.Mutex
    counter int
)
go func() {
    mu.Lock()
    counter++
    mu.Unlock()
}()

// OK: sync.Map for concurrent access
var cache sync.Map
cache.Store("key", value)
if v, ok := cache.Load("key"); ok {
    // use v
}

// OK: Atomic operations
var counter int64
atomic.AddInt64(&counter, 1)
```

### Channel Review

```go
// RED FLAG: Nil channel (blocks forever)
var ch chan int
ch <- 1  // FAIL: Send to nil channel blocks

// RED FLAG: Closed channel send
close(ch)
ch <- 1  // PANIC: Send on closed channel

// RED FLAG: Double close
close(ch)
close(ch)  // PANIC: Close of closed channel
```

### Review Questions

- [ ] Does every goroutine have a clear termination path?
- [ ] Is `context.Context` used for cancellation?
- [ ] Are shared variables protected (mutex, atomic, channel)?
- [ ] Is `sync.WaitGroup` used correctly (Add before go)?
- [ ] Are loop variables captured in goroutine closures?
- [ ] Is the race detector passing (`go test -race`)?
- [ ] Are channels properly closed (only by sender)?
- [ ] Is channel capacity intentional (buffered vs unbuffered)?

---

## PART 4: Interface Review

### Must Check

```go
// RED FLAG: Large interfaces
type UserService interface {
    GetUser(id string) (*User, error)
    CreateUser(u *User) error
    UpdateUser(u *User) error
    DeleteUser(id string) error
    ListUsers() ([]*User, error)
    GetUserByEmail(email string) (*User, error)
    // ... 10 more methods
}  // WARN: Interface too large, hard to mock

// RED FLAG: Interface defined by implementer
// producer.go
type Producer interface { ... }
type ConcreteProducer struct { ... }
// FAIL: Interface should be defined by consumer
```

### Correct Patterns

```go
// OK: Small, focused interfaces
type UserGetter interface {
    GetUser(ctx context.Context, id string) (*User, error)
}

type UserCreator interface {
    CreateUser(ctx context.Context, u *User) error
}

// OK: Interface defined where used (consumer)
// handler.go
type UserGetter interface {
    GetUser(ctx context.Context, id string) (*User, error)
}

type Handler struct {
    users UserGetter  // Accepts interface
}
```

### Review Questions

- [ ] Are interfaces small (1-3 methods)?
- [ ] Are interfaces defined by consumers, not producers?
- [ ] Does the code "accept interfaces, return structs"?
- [ ] Are interface names verb+er (Reader, Writer, Closer)?

---

## PART 5: Naming Review

### Package Names

```go
// RED FLAGS
package user_service   // FAIL: Underscore
package userService    // FAIL: CamelCase
package users          // WARN: Plural (use singular)
package util           // WARN: Too generic
package common         // WARN: Too generic
package base           // WARN: Too generic

// OK
package user
package auth
package http
```

### Variable Names

```go
// RED FLAGS
var usrAcctMgr UserAccountManager  // FAIL: Abbreviations
var u *User                         // WARN: Too short if long-lived
var theUserFromDatabase *User       // FAIL: Verbose

// OK
var user *User                      // Clear
var mgr *AccountManager             // Acceptable abbreviation
for i := range items { }            // Short in small scope
```

### Receiver Names

```go
// RED FLAGS
func (this *User) Name() string { }  // FAIL: this
func (self *User) Name() string { }  // FAIL: self
func (user *User) Name() string { }  // WARN: Too long

// OK
func (u *User) Name() string { }     // 1-2 letters
func (r *Repository) Find() { }
func (h *Handler) ServeHTTP() { }
```

### Review Questions

- [ ] Are package names short, lowercase, single-word?
- [ ] Are variable names clear without being verbose?
- [ ] Are receivers 1-2 letter abbreviations (not `this`/`self`)?
- [ ] Are acronyms consistent (ID, URL, HTTP all caps)?

---

## PART 6: Performance Review

### Allocations

```go
// RED FLAG: Slice grows in loop
var items []Item
for _, raw := range data {
    items = append(items, convert(raw))  // WARN: Multiple allocations
}

// OK: Preallocated
items := make([]Item, 0, len(data))
for _, raw := range data {
    items = append(items, convert(raw))
}
```

### String Operations

```go
// RED FLAG: String concatenation in loop
result := ""
for _, s := range parts {
    result += s  // FAIL: O(n²) allocations
}

// OK: strings.Builder
var b strings.Builder
for _, s := range parts {
    b.WriteString(s)
}
result := b.String()
```

### Memory Leaks

```go
// RED FLAG: Subslice keeps underlying array
func getFirst10(data []byte) []byte {
    return data[:10]  // WARN: Holds reference to full array
}

// OK: Copy to new slice
func getFirst10(data []byte) []byte {
    result := make([]byte, 10)
    copy(result, data[:10])
    return result
}
```

### Review Questions

- [ ] Are slices preallocated when size is known?
- [ ] Is `strings.Builder` used for concatenation loops?
- [ ] Are subslices copied when original can be GC'd?
- [ ] Is `sync.Pool` used for frequently allocated objects?

---

## PART 7: Context Review

### Must Check

```go
// RED FLAG: Context in struct
type Service struct {
    ctx context.Context  // FAIL: Don't store context
}

// RED FLAG: context.Background() everywhere
func (s *Service) Process() error {
    return s.db.Query(context.Background(), ...)  // WARN: Should pass ctx
}

// RED FLAG: Context not first parameter
func Process(id string, ctx context.Context) error {  // FAIL: ctx should be first
```

### Correct Patterns

```go
// OK: Context as first parameter
func (s *Service) Process(ctx context.Context, id string) error {
    // Check cancellation
    if err := ctx.Err(); err != nil {
        return err
    }

    // Pass to downstream
    return s.db.Query(ctx, query, id)
}

// OK: Respect context in loops
for _, item := range items {
    select {
    case <-ctx.Done():
        return ctx.Err()
    default:
        process(item)
    }
}
```

### Review Questions

- [ ] Is context passed as first parameter?
- [ ] Is context NOT stored in structs?
- [ ] Is context passed to all downstream calls?
- [ ] Is `ctx.Err()` checked in long operations?
- [ ] Is `context.Background()` only used at top-level?

---

## PART 8: Security Review

### Input Validation

```go
// RED FLAG: SQL injection
query := fmt.Sprintf("SELECT * FROM users WHERE id = '%s'", userInput)
// FAIL: Never interpolate user input

// OK: Parameterized query
query := "SELECT * FROM users WHERE id = $1"
db.Query(ctx, query, userInput)
```

### Path Traversal

```go
// RED FLAG: Path traversal
path := filepath.Join("/uploads", userInput)
// FAIL: userInput could be "../../../etc/passwd"

// OK: Validate and clean
path := filepath.Join("/uploads", filepath.Base(userInput))
if !strings.HasPrefix(path, "/uploads/") {
    return errors.New("invalid path")
}
```

### Secrets

```go
// RED FLAGS in code
const apiKey = "sk-12345..."           // FAIL: Hardcoded secret
var password = os.Getenv("PASSWORD")   // OK but log it? FAIL

// RED FLAGS in logs
log.Printf("Connecting with password: %s", password)  // FAIL
```

### Review Questions

- [ ] Are SQL queries parameterized?
- [ ] Is user input validated before use in paths?
- [ ] Are secrets NOT hardcoded?
- [ ] Are secrets NOT logged?
- [ ] Is `crypto/rand` used instead of `math/rand` for security?

---

## PART 9: Testing Review

### Must Check

```go
// RED FLAG: No subtests
func TestUser(t *testing.T) {
    // tests valid user
    // tests invalid user
    // tests empty user
    // All in one function - hard to identify failures
}

// RED FLAG: Test depends on order
var globalUser *User

func TestCreate(t *testing.T) {
    globalUser = createUser()
}

func TestUpdate(t *testing.T) {
    updateUser(globalUser)  // FAIL: Depends on TestCreate
}
```

### Correct Patterns

```go
// OK: Table-driven with subtests
func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        wantErr bool
    }{
        {"valid email", "test@example.com", false},
        {"missing @", "testexample.com", true},
        {"empty", "", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ValidateEmail(tt.email)
            if (err != nil) != tt.wantErr {
                t.Errorf("ValidateEmail(%q) error = %v, wantErr %v",
                    tt.email, err, tt.wantErr)
            }
        })
    }
}

// OK: Parallel tests
func TestProcess(t *testing.T) {
    for _, tt := range tests {
        tt := tt  // Capture!
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            // ...
        })
    }
}
```

### Review Questions

- [ ] Are table-driven tests used for multiple cases?
- [ ] Are subtests using `t.Run` for clear failure messages?
- [ ] Are tests independent (no shared state)?
- [ ] Is `t.Parallel()` used where safe?
- [ ] Are loop variables captured in parallel tests?
- [ ] Is test coverage adequate for critical paths?

---

## PART 10: Documentation Review

### Must Check

```go
// RED FLAG: Exported without doc
func ProcessOrder(ctx context.Context, order *Order) error {
    // No documentation - FAIL for exported function

// RED FLAG: Useless doc
// ProcessOrder processes the order
func ProcessOrder(ctx context.Context, order *Order) error {
    // FAIL: Just repeats the name

// RED FLAG: Outdated doc
// ProcessOrder sends order to warehouse
func ProcessOrder(ctx context.Context, order *Order) error {
    // Actually validates and saves to DB - doc is wrong
```

### Correct Patterns

```go
// OK: Meaningful documentation
// ProcessOrder validates the order, saves it to the database,
// and queues it for fulfillment. Returns ErrInvalidOrder if
// validation fails or ErrDuplicateOrder if order ID exists.
func ProcessOrder(ctx context.Context, order *Order) error {
```

### Review Questions

- [ ] Are all exported symbols documented?
- [ ] Do comments explain WHY, not just WHAT?
- [ ] Are comments accurate and up-to-date?
- [ ] Is the package documented in `doc.go`?

---

## PART 11: Final Checklist

### Before Approving

```
AUTOMATED CHECKS:
[ ] go fmt ./... passes
[ ] go vet ./... passes
[ ] golangci-lint run passes
[ ] go test ./... passes
[ ] go test -race ./... passes

MANUAL REVIEW:
[ ] No ignored errors
[ ] Errors wrapped with context
[ ] Goroutines have termination path
[ ] Shared state is protected
[ ] Context passed correctly
[ ] No security vulnerabilities
[ ] Tests are meaningful
[ ] Code is readable
[ ] No over-engineering

RED FLAGS TO BLOCK:
[ ] Ignored errors on critical paths
[ ] Race conditions
[ ] Goroutine leaks
[ ] Security vulnerabilities
[ ] No tests for business logic
```

---

## PART 12: Review Output Template

```markdown
## Go Code Review: [PR/File Name]

### Summary
[1-2 sentence overview]

### Blockers (Must Fix)
- [ ] **[ERROR]** [file:line] Description
- [ ] **[RACE]** [file:line] Description
- [ ] **[SECURITY]** [file:line] Description

### Warnings (Should Fix)
- [ ] **[PERF]** [file:line] Description
- [ ] **[STYLE]** [file:line] Description

### Suggestions (Consider)
- **[REFACTOR]** [file:line] Description
- **[TEST]** [file:line] Description

### Positive Notes
- [What was done well]

### Checklist
- [ ] Automated checks pass
- [ ] Error handling reviewed
- [ ] Concurrency reviewed
- [ ] Security reviewed
- [ ] Tests adequate
```

---

## Sources

- [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments)
- [Go Concurrency Checklist](https://github.com/code-review-checklists/go-concurrency)
- [Microsoft Go Code Reviews](https://microsoft.github.io/code-with-engineering-playbook/code-reviews/recipes/go/)
- [Effective Go](https://go.dev/doc/effective_go)
