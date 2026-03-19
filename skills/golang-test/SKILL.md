---
name: golang-test
description: Use when writing Go tests, benchmarks, fuzz tests, or user mentions "test go", "benchmark", "fuzz", "testcontainers". Advanced testing patterns.
chain: none
---

# Go Testing Specialist

Expert Go testing covering unit tests, table-driven tests, benchmarks, fuzz testing, integration tests with testcontainers, and mocking strategies.

## When to Use

- Writing new tests for Go code
- Adding benchmarks
- Setting up fuzz testing
- Integration tests with databases/containers
- Improving test coverage
- Mocking dependencies

## NOT When To Use

- Writing production code (use `golang-dev`)
- Code review (use `golang-review`)

---

## PART 1: Test Organization

### File Structure

```
mypackage/
├── user.go              # Production code
├── user_test.go         # Unit tests (same package)
├── user_internal_test.go # Internal tests (same package)
├── user_export_test.go  # Black-box tests (package_test)
├── testdata/            # Test fixtures
│   ├── golden/          # Golden files
│   └── fixtures/        # Test data
└── integration/         # Integration tests (build tag)
    └── user_test.go     # //go:build integration
```

### Package Naming

```go
// Same package - access internals
package user

func TestInternalHelper(t *testing.T) {
    result := internalHelper()  // Can access unexported
}

// Different package - black-box testing
package user_test

import "myapp/user"

func TestPublicAPI(t *testing.T) {
    result := user.Create()  // Only exported
}
```

---

## PART 2: Table-Driven Tests

### Basic Pattern

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name string
        a, b int
        want int
    }{
        {"positive numbers", 2, 3, 5},
        {"negative numbers", -2, -3, -5},
        {"zero", 0, 0, 0},
        {"mixed", -2, 5, 3},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.want {
                t.Errorf("Add(%d, %d) = %d, want %d",
                    tt.a, tt.b, got, tt.want)
            }
        })
    }
}
```

### With Error Cases

```go
func TestParseConfig(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    *Config
        wantErr error
    }{
        {
            name:  "valid config",
            input: `{"port": 8080}`,
            want:  &Config{Port: 8080},
        },
        {
            name:    "invalid json",
            input:   `{invalid}`,
            wantErr: ErrInvalidJSON,
        },
        {
            name:    "missing required field",
            input:   `{}`,
            wantErr: ErrMissingPort,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseConfig(tt.input)

            // Check error
            if !errors.Is(err, tt.wantErr) {
                t.Errorf("error = %v, wantErr %v", err, tt.wantErr)
                return
            }

            // Check result
            if !reflect.DeepEqual(got, tt.want) {
                t.Errorf("got %+v, want %+v", got, tt.want)
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
        {"case1", 1, 2},
        {"case2", 2, 4},
        {"case3", 3, 6},
    }

    for _, tt := range tests {
        tt := tt // CRITICAL: Capture loop variable!
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel() // Run concurrently

            got := Process(tt.input)
            if got != tt.want {
                t.Errorf("got %d, want %d", got, tt.want)
            }
        })
    }
}
```

---

## PART 3: Test Helpers

### Basic Helper

```go
// t.Helper() improves error location reporting
func assertEqual[T comparable](t *testing.T, got, want T) {
    t.Helper()
    if got != want {
        t.Errorf("got %v, want %v", got, want)
    }
}

func assertNoError(t *testing.T, err error) {
    t.Helper()
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
}

func assertError(t *testing.T, err, target error) {
    t.Helper()
    if !errors.Is(err, target) {
        t.Errorf("error = %v, want %v", err, target)
    }
}
```

### Cleanup with t.Cleanup

```go
func TestWithTempDir(t *testing.T) {
    // Create temp directory
    dir, err := os.MkdirTemp("", "test-*")
    assertNoError(t, err)

    // Register cleanup - runs after test
    t.Cleanup(func() {
        os.RemoveAll(dir)
    })

    // Test using dir...
}

func TestWithServer(t *testing.T) {
    srv := httptest.NewServer(handler)
    t.Cleanup(srv.Close)

    // Test using srv.URL...
}
```

### Test Fixtures

```go
func loadTestData(t *testing.T, name string) []byte {
    t.Helper()
    path := filepath.Join("testdata", name)
    data, err := os.ReadFile(path)
    if err != nil {
        t.Fatalf("failed to load test data %s: %v", name, err)
    }
    return data
}

func TestParse(t *testing.T) {
    input := loadTestData(t, "valid_input.json")
    // ...
}
```

---

## PART 4: Golden Files

### Pattern for Complex Output

```go
var update = flag.Bool("update", false, "update golden files")

func TestRender(t *testing.T) {
    tests := []struct {
        name   string
        input  *Template
        golden string
    }{
        {"basic", basicTemplate, "basic.golden"},
        {"complex", complexTemplate, "complex.golden"},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Render(tt.input)

            goldenPath := filepath.Join("testdata", "golden", tt.golden)

            if *update {
                // Update golden file
                os.WriteFile(goldenPath, []byte(got), 0644)
                return
            }

            // Compare with golden
            want, err := os.ReadFile(goldenPath)
            assertNoError(t, err)

            if got != string(want) {
                t.Errorf("output mismatch.\ngot:\n%s\nwant:\n%s",
                    got, want)
            }
        })
    }
}
```

Usage:
```bash
# Run tests
go test ./...

# Update golden files
go test ./... -update
```

---

## PART 5: HTTP Testing

### Testing Handlers

```go
func TestUserHandler(t *testing.T) {
    // Create handler
    handler := NewUserHandler(mockRepo)

    tests := []struct {
        name       string
        method     string
        path       string
        body       string
        wantStatus int
        wantBody   string
    }{
        {
            name:       "get existing user",
            method:     "GET",
            path:       "/users/123",
            wantStatus: http.StatusOK,
            wantBody:   `{"id":"123","name":"Test"}`,
        },
        {
            name:       "user not found",
            method:     "GET",
            path:       "/users/999",
            wantStatus: http.StatusNotFound,
        },
        {
            name:       "create user",
            method:     "POST",
            path:       "/users",
            body:       `{"name":"New User"}`,
            wantStatus: http.StatusCreated,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Create request
            var body io.Reader
            if tt.body != "" {
                body = strings.NewReader(tt.body)
            }
            req := httptest.NewRequest(tt.method, tt.path, body)
            req.Header.Set("Content-Type", "application/json")

            // Record response
            rec := httptest.NewRecorder()
            handler.ServeHTTP(rec, req)

            // Assert status
            if rec.Code != tt.wantStatus {
                t.Errorf("status = %d, want %d", rec.Code, tt.wantStatus)
            }

            // Assert body (if specified)
            if tt.wantBody != "" {
                got := strings.TrimSpace(rec.Body.String())
                if got != tt.wantBody {
                    t.Errorf("body = %s, want %s", got, tt.wantBody)
                }
            }
        })
    }
}
```

### Testing HTTP Clients

```go
func TestClient(t *testing.T) {
    // Create mock server
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        switch r.URL.Path {
        case "/users/123":
            w.WriteHeader(http.StatusOK)
            w.Write([]byte(`{"id":"123","name":"Test"}`))
        default:
            w.WriteHeader(http.StatusNotFound)
        }
    }))
    t.Cleanup(server.Close)

    // Create client with test server URL
    client := NewClient(server.URL)

    // Test
    user, err := client.GetUser(context.Background(), "123")
    assertNoError(t, err)
    assertEqual(t, user.Name, "Test")
}
```

---

## PART 6: Mocking with Interfaces

### Define Interface at Consumer

```go
// service.go
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
    Save(ctx context.Context, user *User) error
}

type Service struct {
    repo UserRepository
}

func (s *Service) GetUser(ctx context.Context, id string) (*User, error) {
    return s.repo.FindByID(ctx, id)
}
```

### Create Mock

```go
// service_test.go
type mockUserRepo struct {
    findByIDFunc func(ctx context.Context, id string) (*User, error)
    saveFunc     func(ctx context.Context, user *User) error
}

func (m *mockUserRepo) FindByID(ctx context.Context, id string) (*User, error) {
    if m.findByIDFunc != nil {
        return m.findByIDFunc(ctx, id)
    }
    return nil, errors.New("not implemented")
}

func (m *mockUserRepo) Save(ctx context.Context, user *User) error {
    if m.saveFunc != nil {
        return m.saveFunc(ctx, user)
    }
    return errors.New("not implemented")
}
```

### Use Mock in Tests

```go
func TestService_GetUser(t *testing.T) {
    tests := []struct {
        name     string
        mockRepo *mockUserRepo
        userID   string
        want     *User
        wantErr  error
    }{
        {
            name: "found",
            mockRepo: &mockUserRepo{
                findByIDFunc: func(ctx context.Context, id string) (*User, error) {
                    return &User{ID: id, Name: "Test"}, nil
                },
            },
            userID: "123",
            want:   &User{ID: "123", Name: "Test"},
        },
        {
            name: "not found",
            mockRepo: &mockUserRepo{
                findByIDFunc: func(ctx context.Context, id string) (*User, error) {
                    return nil, ErrNotFound
                },
            },
            userID:  "999",
            wantErr: ErrNotFound,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            svc := &Service{repo: tt.mockRepo}

            got, err := svc.GetUser(context.Background(), tt.userID)

            if !errors.Is(err, tt.wantErr) {
                t.Errorf("error = %v, want %v", err, tt.wantErr)
            }
            if !reflect.DeepEqual(got, tt.want) {
                t.Errorf("got %+v, want %+v", got, tt.want)
            }
        })
    }
}
```

---

## PART 7: Benchmarks

### Basic Benchmark

```go
func BenchmarkProcess(b *testing.B) {
    input := prepareInput()

    b.ResetTimer() // Exclude setup time

    for b.Loop() {  // Go 1.24+
        Process(input)
    }
}

// Pre-1.24 style
func BenchmarkProcessOld(b *testing.B) {
    input := prepareInput()
    b.ResetTimer()

    for i := 0; i < b.N; i++ {
        Process(input)
    }
}
```

### Benchmark with Sub-benchmarks

```go
func BenchmarkSort(b *testing.B) {
    sizes := []int{10, 100, 1000, 10000}

    for _, size := range sizes {
        b.Run(fmt.Sprintf("size-%d", size), func(b *testing.B) {
            data := generateData(size)

            b.ResetTimer()
            for b.Loop() {
                Sort(data)
            }
        })
    }
}
```

### Memory Benchmarks

```go
func BenchmarkAllocations(b *testing.B) {
    b.ReportAllocs() // Report allocations

    for b.Loop() {
        _ = ProcessWithAllocs()
    }
}
```

### Running Benchmarks

```bash
# Run all benchmarks
go test -bench=. ./...

# Run specific benchmark
go test -bench=BenchmarkSort ./...

# With memory stats
go test -bench=. -benchmem ./...

# Multiple runs for comparison
go test -bench=. -count=5 ./...

# Compare with benchstat
go test -bench=. -count=10 > old.txt
# make changes
go test -bench=. -count=10 > new.txt
benchstat old.txt new.txt
```

---

## PART 8: Fuzz Testing

### Basic Fuzz Test

```go
func FuzzParseJSON(f *testing.F) {
    // Add seed corpus
    f.Add([]byte(`{"name":"test"}`))
    f.Add([]byte(`{}`))
    f.Add([]byte(`{"nested":{"key":"value"}}`))

    f.Fuzz(func(t *testing.T, data []byte) {
        // Should not panic
        result, err := ParseJSON(data)

        // If no error, result should be valid
        if err == nil && result == nil {
            t.Error("nil result without error")
        }
    })
}
```

### Fuzz with Multiple Args

```go
func FuzzConcat(f *testing.F) {
    f.Add("hello", "world")
    f.Add("", "")
    f.Add("a", "b")

    f.Fuzz(func(t *testing.T, a, b string) {
        result := Concat(a, b)

        // Verify properties
        if len(result) != len(a)+len(b) {
            t.Errorf("length mismatch: got %d, want %d",
                len(result), len(a)+len(b))
        }

        if !strings.HasPrefix(result, a) {
            t.Error("result should start with a")
        }
    })
}
```

### Running Fuzz Tests

```bash
# Run fuzz test for 30 seconds
go test -fuzz=FuzzParseJSON -fuzztime=30s

# Run with specific corpus
go test -fuzz=FuzzParseJSON -fuzztime=1m

# Run seed corpus only (no fuzzing)
go test -run=FuzzParseJSON

# Run with race detector
go test -fuzz=FuzzParseJSON -race -fuzztime=30s
```

### Corpus Management

```
testdata/
└── fuzz/
    └── FuzzParseJSON/
        ├── seed1        # Manual seed
        ├── seed2        # Manual seed
        └── <hash>       # Auto-generated interesting inputs
```

---

## PART 9: Integration Tests with Testcontainers

### Setup

```go
//go:build integration

package integration

import (
    "context"
    "testing"
    "github.com/testcontainers/testcontainers-go"
    "github.com/testcontainers/testcontainers-go/modules/postgres"
)
```

### PostgreSQL Container

```go
func TestWithPostgres(t *testing.T) {
    ctx := context.Background()

    // Start container
    pgContainer, err := postgres.Run(ctx,
        "postgres:16-alpine",
        postgres.WithDatabase("testdb"),
        postgres.WithUsername("test"),
        postgres.WithPassword("test"),
    )
    if err != nil {
        t.Fatalf("failed to start postgres: %v", err)
    }
    t.Cleanup(func() {
        pgContainer.Terminate(ctx)
    })

    // Get connection string
    connStr, err := pgContainer.ConnectionString(ctx, "sslmode=disable")
    if err != nil {
        t.Fatalf("failed to get connection string: %v", err)
    }

    // Connect and test
    db, err := sql.Open("postgres", connStr)
    if err != nil {
        t.Fatalf("failed to connect: %v", err)
    }
    t.Cleanup(func() { db.Close() })

    // Run migrations
    runMigrations(db)

    // Test your repository
    repo := NewUserRepository(db)
    // ...
}
```

### Redis Container

```go
func TestWithRedis(t *testing.T) {
    ctx := context.Background()

    redisContainer, err := testcontainers.GenericContainer(ctx,
        testcontainers.GenericContainerRequest{
            ContainerRequest: testcontainers.ContainerRequest{
                Image:        "redis:7-alpine",
                ExposedPorts: []string{"6379/tcp"},
                WaitingFor:   wait.ForLog("Ready to accept connections"),
            },
            Started: true,
        })
    if err != nil {
        t.Fatalf("failed to start redis: %v", err)
    }
    t.Cleanup(func() { redisContainer.Terminate(ctx) })

    endpoint, _ := redisContainer.Endpoint(ctx, "")

    // Test with Redis
    cache := NewRedisCache(endpoint)
    // ...
}
```

### Using Build Tags

```go
// integration_test.go
//go:build integration

package myapp_test

// This file only compiles with: go test -tags=integration
```

```bash
# Run unit tests only
go test ./...

# Run integration tests
go test -tags=integration ./...

# Run both
go test -tags=integration ./...
```

---

## PART 10: TestMain for Setup/Teardown

### Global Setup

```go
func TestMain(m *testing.M) {
    // Setup
    setup()

    // Run tests
    code := m.Run()

    // Teardown
    teardown()

    os.Exit(code)
}

func setup() {
    // Initialize database
    // Start mock servers
    // Load config
}

func teardown() {
    // Clean up resources
}
```

### With Testcontainers

```go
var testDB *sql.DB

func TestMain(m *testing.M) {
    ctx := context.Background()

    // Start postgres
    pgContainer, err := postgres.Run(ctx, "postgres:16-alpine")
    if err != nil {
        log.Fatalf("failed to start postgres: %v", err)
    }

    connStr, _ := pgContainer.ConnectionString(ctx, "sslmode=disable")
    testDB, _ = sql.Open("postgres", connStr)

    // Run tests
    code := m.Run()

    // Cleanup
    testDB.Close()
    pgContainer.Terminate(ctx)

    os.Exit(code)
}

func TestRepository(t *testing.T) {
    // Use testDB
    repo := NewRepository(testDB)
    // ...
}
```

---

## PART 11: Coverage

### Running Coverage

```bash
# Basic coverage
go test -cover ./...

# Coverage with profile
go test -coverprofile=coverage.out ./...

# View in terminal
go tool cover -func=coverage.out

# View in browser (HTML)
go tool cover -html=coverage.out

# Coverage for specific package
go test -coverprofile=coverage.out -coverpkg=./internal/... ./...
```

### Coverage in CI

```yaml
# GitHub Actions example
- name: Test with coverage
  run: go test -coverprofile=coverage.out -covermode=atomic ./...

- name: Upload coverage
  uses: codecov/codecov-action@v3
  with:
    files: coverage.out
```

---

## PART 12: Test Commands Cheatsheet

```bash
# Run all tests
go test ./...

# Verbose output
go test -v ./...

# Run specific test
go test -run TestUserCreate ./...

# Run tests matching pattern
go test -run "TestUser.*" ./...

# With race detector
go test -race ./...

# With timeout
go test -timeout 30s ./...

# Short mode (skip long tests)
go test -short ./...

# Parallel tests (default: GOMAXPROCS)
go test -parallel 4 ./...

# Benchmarks
go test -bench=. -benchmem ./...

# Fuzz testing
go test -fuzz=FuzzParse -fuzztime=1m ./...

# Coverage
go test -cover -coverprofile=coverage.out ./...

# Integration tests
go test -tags=integration ./...

# Clear test cache
go clean -testcache
```

---

## Sources

- [Go Testing Package](https://pkg.go.dev/testing)
- [Testcontainers Go](https://golang.testcontainers.org/)
- [Go Fuzz Testing](https://go.dev/doc/security/fuzz/)
- [Table-Driven Tests Wiki](https://go.dev/wiki/TableDrivenTests)
- [Go 1.24 T.Context](https://boldlygo.tech/archive/2025-04-09-t.context/)
