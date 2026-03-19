---
name: golang-dev
description: Use when developing Go applications, writing idiomatic Go code, or user mentions "go", "golang", "goroutine", "channel". Activates for Go development following Google/Uber style guides.
chain: none
---

# Go Development Specialist

Expert-level Go development following Google Style Guide, Uber Style Guide, and Effective Go patterns. Production-ready, idiomatic, and performant code.

## When to Use

- Writing new Go code (functions, structs, interfaces)
- Refactoring existing Go code
- Implementing concurrency patterns (goroutines, channels)
- Error handling and wrapping
- Writing table-driven tests
- Configuring golangci-lint
- Project structure decisions

## NOT When To Use

- Simple questions about Go syntax (just answer directly)
- Non-Go projects

---

## PART 1: Project Structure

### Standard Layout

```
project/
├── cmd/
│   └── myapp/
│       └── main.go           # Entry point - minimal, just wires things up
├── internal/                  # Private packages (Go enforces this)
│   ├── domain/               # Business entities, interfaces
│   ├── usecase/              # Business logic
│   ├── repository/           # Data access implementations
│   ├── handler/              # HTTP/gRPC handlers
│   └── config/               # Configuration
├── pkg/                       # Public libraries (only if needed)
├── api/                       # OpenAPI specs, proto files
├── migrations/               # Database migrations
├── scripts/                  # Build/deploy scripts
├── .golangci.yml             # Linter config
├── Makefile                  # Common tasks
├── go.mod
└── go.sum
```

### Key Principles

1. **Start simple, grow when needed** - Don't over-engineer initial structure
2. **`internal/` is your friend** - Go enforces it can't be imported externally
3. **`cmd/` for entry points** - Each subdirectory = one binary
4. **Avoid `pkg/` unless truly public** - Most code belongs in `internal/`

---

## PART 2: Naming Conventions

### Package Names

```go
// GOOD: Short, lowercase, single word
package http
package user
package auth

// BAD: Underscores, camelCase, plural
package user_service  // NO
package userService   // NO
package users         // NO (use singular)
```

### Variable Names

```go
// Short names for short-lived variables
for i := 0; i < len(items); i++ { }
for _, v := range values { }

// Descriptive names for longer-lived or exported
var userRepository UserRepository
var maxRetryAttempts = 3

// Acronyms: ALL CAPS or all lowercase
var httpClient *http.Client  // lowercase in middle
var HTTPClient *http.Client  // exported, all caps
var userID string            // ID not Id
var xmlParser XMLParser      // XML not Xml
```

### Interface Names

```go
// Single-method interfaces: method name + "er"
type Reader interface { Read(p []byte) (n int, err error) }
type Stringer interface { String() string }
type Closer interface { Close() error }

// Multi-method: descriptive noun
type Repository interface {
    Find(id string) (*Entity, error)
    Save(entity *Entity) error
    Delete(id string) error
}
```

### Receiver Names

```go
// Short, 1-2 letter abbreviation of type
func (u *User) FullName() string { }
func (r *Repository) Find(id string) { }
func (h *Handler) ServeHTTP(w, r) { }

// NEVER use "this" or "self"
func (this *User) FullName() string { } // NO!
```

---

## PART 3: Error Handling

### The Golden Rules

1. **Handle errors only once** (don't log AND return)
2. **Add context when wrapping** (where + what failed)
3. **Use `%w` for wrappable errors** (allows Is/As checks)
4. **Use `%v` for opaque errors** (hides implementation)

### Error Wrapping Pattern

```go
// GOOD: Add context at each layer
func (r *Repository) FindUser(id string) (*User, error) {
    user, err := r.db.Query(ctx, query, id)
    if err != nil {
        return nil, fmt.Errorf("repository.FindUser(%s): %w", id, err)
    }
    return user, nil
}

func (s *Service) GetUser(id string) (*User, error) {
    user, err := s.repo.FindUser(id)
    if err != nil {
        return nil, fmt.Errorf("getting user: %w", err)
    }
    return user, nil
}
```

### Sentinel Errors

```go
// Define at package level for expected errors
var (
    ErrNotFound     = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
    ErrInvalidInput = errors.New("invalid input")
)

// Use errors.Is to check
if errors.Is(err, ErrNotFound) {
    // handle not found
}
```

### Custom Error Types

```go
// When you need structured error data
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed on %s: %s", e.Field, e.Message)
}

// Use errors.As to extract
var valErr *ValidationError
if errors.As(err, &valErr) {
    log.Printf("Invalid field: %s", valErr.Field)
}
```

### Error Handling Anti-Patterns

```go
// BAD: Logging AND returning (handles twice)
if err != nil {
    log.Printf("error: %v", err)
    return err
}

// BAD: Wrapping without context
return fmt.Errorf("error: %w", err)  // Useless

// BAD: Ignoring errors
result, _ := riskyOperation()  // NO!

// BAD: Over-wrapping
return fmt.Errorf("in GetUser: %w",
    fmt.Errorf("calling repo: %w", err))  // Pick one layer
```

---

## PART 4: Concurrency Patterns

### Goroutine Safety Rules

1. **Never start a goroutine without knowing when it will stop**
2. **Use context.Context for cancellation**
3. **Use WaitGroup to wait for goroutines**
4. **Use channels for communication, mutexes for state**

### Worker Pool Pattern

```go
func WorkerPool(ctx context.Context, jobs <-chan Job, workers int) <-chan Result {
    results := make(chan Result)
    var wg sync.WaitGroup

    for i := 0; i < workers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for {
                select {
                case <-ctx.Done():
                    return
                case job, ok := <-jobs:
                    if !ok {
                        return
                    }
                    results <- process(job)
                }
            }
        }()
    }

    go func() {
        wg.Wait()
        close(results)
    }()

    return results
}
```

### Fan-Out/Fan-In Pattern

```go
func FanOutFanIn(ctx context.Context, input <-chan int, workers int) <-chan int {
    // Fan-out: distribute to workers
    channels := make([]<-chan int, workers)
    for i := 0; i < workers; i++ {
        channels[i] = worker(ctx, input)
    }

    // Fan-in: merge results
    return merge(ctx, channels...)
}

func merge(ctx context.Context, channels ...<-chan int) <-chan int {
    out := make(chan int)
    var wg sync.WaitGroup

    for _, ch := range channels {
        wg.Add(1)
        go func(c <-chan int) {
            defer wg.Done()
            for v := range c {
                select {
                case <-ctx.Done():
                    return
                case out <- v:
                }
            }
        }(ch)
    }

    go func() {
        wg.Wait()
        close(out)
    }()

    return out
}
```

### Context Usage

```go
// ALWAYS pass context as first parameter
func ProcessRequest(ctx context.Context, req *Request) (*Response, error) {
    // Check cancellation early
    if err := ctx.Err(); err != nil {
        return nil, err
    }

    // Use context for downstream calls
    data, err := fetchData(ctx, req.ID)
    if err != nil {
        return nil, err
    }

    // Respect context in loops
    for _, item := range items {
        select {
        case <-ctx.Done():
            return nil, ctx.Err()
        default:
            process(item)
        }
    }

    return &Response{Data: data}, nil
}
```

### Mutex vs Channel Decision

```go
// Use MUTEX when:
// - Protecting a cache or map
// - Simple state updates
// - Performance critical (less overhead)

type Cache struct {
    mu    sync.RWMutex
    items map[string]Item
}

func (c *Cache) Get(key string) (Item, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock()
    item, ok := c.items[key]
    return item, ok
}

// Use CHANNEL when:
// - Passing ownership of data
// - Coordinating goroutines
// - Implementing pipelines
// - Signaling events

jobs := make(chan Job, 100)  // Buffered for async
done := make(chan struct{})  // Signal completion
```

---

## PART 5: Testing

### Table-Driven Tests (The Go Way)

```go
func TestParseURL(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    *URL
        wantErr bool
    }{
        {
            name:  "valid http url",
            input: "http://example.com/path",
            want:  &URL{Scheme: "http", Host: "example.com", Path: "/path"},
        },
        {
            name:    "empty string",
            input:   "",
            wantErr: true,
        },
        {
            name:    "invalid scheme",
            input:   "ftp://example.com",
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseURL(tt.input)

            if (err != nil) != tt.wantErr {
                t.Errorf("ParseURL() error = %v, wantErr %v", err, tt.wantErr)
                return
            }

            if !reflect.DeepEqual(got, tt.want) {
                t.Errorf("ParseURL() = %v, want %v", got, tt.want)
            }
        })
    }
}
```

### Parallel Table Tests

```go
func TestProcess(t *testing.T) {
    tests := []struct {
        name  string
        input int
        want  int
    }{
        {"positive", 5, 10},
        {"zero", 0, 0},
        {"negative", -5, -10},
    }

    for _, tt := range tests {
        tt := tt // CRITICAL: Capture loop variable!
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel() // Run in parallel
            got := Process(tt.input)
            if got != tt.want {
                t.Errorf("got %d, want %d", got, tt.want)
            }
        })
    }
}
```

### Testing with Interfaces (Mocking)

```go
// Define interface for dependency
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
}

// Production implementation
type PostgresUserRepo struct { db *sql.DB }

// Test mock
type MockUserRepo struct {
    FindByIDFunc func(ctx context.Context, id string) (*User, error)
}

func (m *MockUserRepo) FindByID(ctx context.Context, id string) (*User, error) {
    return m.FindByIDFunc(ctx, id)
}

// In tests
func TestService_GetUser(t *testing.T) {
    mockRepo := &MockUserRepo{
        FindByIDFunc: func(ctx context.Context, id string) (*User, error) {
            return &User{ID: id, Name: "Test"}, nil
        },
    }

    svc := NewService(mockRepo)
    user, err := svc.GetUser(context.Background(), "123")

    if err != nil {
        t.Fatal(err)
    }
    if user.Name != "Test" {
        t.Errorf("got %s, want Test", user.Name)
    }
}
```

### Test Helpers

```go
// t.Helper() marks function as helper (better error locations)
func assertNoError(t *testing.T, err error) {
    t.Helper()
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
}

func assertEqual[T comparable](t *testing.T, got, want T) {
    t.Helper()
    if got != want {
        t.Errorf("got %v, want %v", got, want)
    }
}

// t.Cleanup() for automatic cleanup
func TestWithTempFile(t *testing.T) {
    f, err := os.CreateTemp("", "test")
    assertNoError(t, err)

    t.Cleanup(func() {
        os.Remove(f.Name())
    })

    // Test using f...
}
```

---

## PART 6: golangci-lint Configuration

### Recommended `.golangci.yml` (2025)

```yaml
# golangci-lint v2 configuration
version: "2"

linters:
  default: standard
  enable:
    # Essential
    - errcheck          # Check error returns
    - govet             # Go vet checks
    - staticcheck       # Comprehensive static analysis
    - gosimple          # Simplify code
    - ineffassign       # Detect ineffectual assignments
    - unused            # Find unused code

    # Security
    - gosec             # Security issues

    # Style & Quality
    - revive            # Fast, configurable linter
    - gofmt             # Formatting
    - goimports         # Import organization
    - misspell          # Spelling mistakes

    # Bugs & Performance
    - bodyclose         # HTTP body close
    - noctx             # HTTP without context
    - sqlclosecheck     # SQL rows close
    - exportloopref     # Loop variable capture (pre Go 1.22)

    # Complexity
    - gocyclo           # Cyclomatic complexity
    - gocognit          # Cognitive complexity
    - funlen            # Function length

    # Modern Go
    - modernize         # Use modern Go features

linters-settings:
  errcheck:
    check-type-assertions: true
    check-blank: true

  govet:
    enable-all: true

  gocyclo:
    min-complexity: 15

  gocognit:
    min-complexity: 20

  funlen:
    lines: 100
    statements: 50

  revive:
    rules:
      - name: blank-imports
      - name: context-as-argument
      - name: context-keys-type
      - name: error-return
      - name: error-strings
      - name: error-naming
      - name: exported
      - name: increment-decrement
      - name: var-naming
      - name: package-comments
      - name: range
      - name: receiver-naming
      - name: time-naming
      - name: unexported-return
      - name: indent-error-flow
      - name: errorf
      - name: empty-block
      - name: superfluous-else
      - name: unused-parameter
      - name: unreachable-code

run:
  timeout: 5m
  tests: true
  modules-download-mode: readonly

issues:
  max-issues-per-linter: 0
  max-same-issues: 0

  exclude-rules:
    # Allow long test functions
    - path: _test\.go
      linters:
        - funlen
        - gocyclo

    # Allow dot imports in tests
    - path: _test\.go
      text: "should not use dot imports"

output:
  formats:
    - format: colored-line-number
  print-issued-lines: true
  print-linter-name: true
```

---

## PART 7: Performance Patterns

### Preallocate Slices

```go
// BAD: Grows slice multiple times
var items []Item
for _, raw := range rawItems {
    items = append(items, convert(raw))
}

// GOOD: Preallocate
items := make([]Item, 0, len(rawItems))
for _, raw := range rawItems {
    items = append(items, convert(raw))
}
```

### String Builder for Concatenation

```go
// BAD: Creates many intermediate strings
result := ""
for _, s := range parts {
    result += s
}

// GOOD: Use strings.Builder
var b strings.Builder
for _, s := range parts {
    b.WriteString(s)
}
result := b.String()
```

### Sync.Pool for Object Reuse

```go
var bufferPool = sync.Pool{
    New: func() interface{} {
        return new(bytes.Buffer)
    },
}

func ProcessData(data []byte) {
    buf := bufferPool.Get().(*bytes.Buffer)
    defer func() {
        buf.Reset()
        bufferPool.Put(buf)
    }()

    // Use buf...
}
```

### Avoid Unnecessary Allocations

```go
// BAD: Allocates on every call
func (u *User) FullName() string {
    return fmt.Sprintf("%s %s", u.First, u.Last)
}

// GOOD: Direct concatenation (faster for simple cases)
func (u *User) FullName() string {
    return u.First + " " + u.Last
}
```

---

## PART 8: Common Idioms

### Accept Interfaces, Return Structs

```go
// GOOD: Accept interface, return concrete
func NewService(repo Repository) *Service {
    return &Service{repo: repo}
}

// BAD: Return interface
func NewService(repo Repository) ServiceInterface {
    return &Service{repo: repo}
}
```

### Functional Options Pattern

```go
type Server struct {
    host    string
    port    int
    timeout time.Duration
}

type Option func(*Server)

func WithHost(host string) Option {
    return func(s *Server) { s.host = host }
}

func WithPort(port int) Option {
    return func(s *Server) { s.port = port }
}

func WithTimeout(d time.Duration) Option {
    return func(s *Server) { s.timeout = d }
}

func NewServer(opts ...Option) *Server {
    s := &Server{
        host:    "localhost",
        port:    8080,
        timeout: 30 * time.Second,
    }
    for _, opt := range opts {
        opt(s)
    }
    return s
}

// Usage
srv := NewServer(
    WithHost("0.0.0.0"),
    WithPort(9000),
)
```

### Constructor Validation

```go
func NewUser(name, email string) (*User, error) {
    if name == "" {
        return nil, fmt.Errorf("name cannot be empty")
    }
    if !isValidEmail(email) {
        return nil, fmt.Errorf("invalid email: %s", email)
    }
    return &User{Name: name, Email: email}, nil
}
```

### Defer for Cleanup

```go
func ReadFile(path string) ([]byte, error) {
    f, err := os.Open(path)
    if err != nil {
        return nil, err
    }
    defer f.Close()  // Always close, even on error

    return io.ReadAll(f)
}
```

---

## PART 9: Structured Logging (slog)

### Basic Setup (Go 1.21+)

```go
import "log/slog"

// JSON handler for production
logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelInfo,
}))

// Text handler for development
logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelDebug,
}))

// Set as default
slog.SetDefault(logger)
```

### Logging Pattern

```go
func (s *Service) ProcessOrder(ctx context.Context, orderID string) error {
    logger := slog.With(
        "order_id", orderID,
        "trace_id", ctx.Value("trace_id"),
    )

    logger.Info("processing order")

    if err := s.validate(ctx, orderID); err != nil {
        logger.Error("validation failed",
            "error", err,
        )
        return fmt.Errorf("validating order: %w", err)
    }

    logger.Info("order processed successfully")
    return nil
}
```

---

## Checklist Before Committing

```
[ ] go fmt ./... passes
[ ] go vet ./... passes
[ ] golangci-lint run passes
[ ] All tests pass (go test ./...)
[ ] No race conditions (go test -race ./...)
[ ] Errors are wrapped with context
[ ] Context is passed through call chain
[ ] Goroutines have cleanup mechanism
[ ] No TODO/FIXME left behind
[ ] Exported functions have comments
```

---

## Sources & References

- [Google Go Style Guide](https://google.github.io/styleguide/go/best-practices.html)
- [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md)
- [Effective Go](https://go.dev/doc/effective_go)
- [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments)
- [Go Proverbs](https://go-proverbs.github.io/)
- [golangci-lint](https://golangci-lint.run/)
- [Go Patterns](https://github.com/tmrts/go-patterns)
