---
name: golang-api
description: Use when building REST APIs or gRPC services in Go, or user mentions "api go", "rest golang", "grpc", "chi", "gin", "middleware". API design patterns.
chain: golang-review
---

# Go API Development Specialist

Expert Go API development covering REST (Chi, Gin), gRPC, middleware patterns, OpenAPI, and production-ready service design.

## When to Use

- Building REST APIs
- Implementing gRPC services
- Designing middleware
- OpenAPI/Swagger generation
- API versioning strategies
- Authentication/Authorization

## NOT When To Use

- General Go code (use `golang-dev`)
- Testing APIs (use `golang-test`)

---

## PART 1: Project Structure for APIs

### REST API Layout

```
api-service/
├── cmd/
│   └── server/
│       └── main.go           # Entry point
├── internal/
│   ├── config/
│   │   └── config.go         # Configuration
│   ├── domain/
│   │   ├── user.go           # Domain entities
│   │   └── errors.go         # Domain errors
│   ├── handler/
│   │   ├── handler.go        # Handler setup
│   │   ├── user.go           # User handlers
│   │   └── middleware.go     # HTTP middleware
│   ├── repository/
│   │   └── user.go           # Data access
│   └── service/
│       └── user.go           # Business logic
├── api/
│   └── openapi.yaml          # OpenAPI spec
├── pkg/
│   └── httputil/             # Shared HTTP utilities
├── migrations/
└── Makefile
```

### gRPC Layout

```
grpc-service/
├── cmd/
│   └── server/
│       └── main.go
├── internal/
│   ├── server/
│   │   ├── server.go         # gRPC server setup
│   │   └── interceptor.go    # gRPC interceptors
│   └── service/
│       └── user.go           # Service implementations
├── proto/
│   └── user/
│       └── v1/
│           └── user.proto    # Protobuf definitions
├── gen/
│   └── proto/                # Generated code
└── buf.yaml                  # Buf configuration
```

---

## PART 2: Chi Router (Recommended)

### Basic Setup

```go
package main

import (
    "net/http"
    "github.com/go-chi/chi/v5"
    "github.com/go-chi/chi/v5/middleware"
)

func main() {
    r := chi.NewRouter()

    // Global middleware
    r.Use(middleware.RequestID)
    r.Use(middleware.RealIP)
    r.Use(middleware.Logger)
    r.Use(middleware.Recoverer)
    r.Use(middleware.Timeout(60 * time.Second))

    // Routes
    r.Get("/health", healthHandler)

    // API routes
    r.Route("/api/v1", func(r chi.Router) {
        r.Use(authMiddleware)

        r.Route("/users", func(r chi.Router) {
            r.Get("/", listUsers)
            r.Post("/", createUser)
            r.Route("/{userID}", func(r chi.Router) {
                r.Get("/", getUser)
                r.Put("/", updateUser)
                r.Delete("/", deleteUser)
            })
        })
    })

    http.ListenAndServe(":8080", r)
}
```

### Handler Pattern

```go
// handler/user.go
type UserHandler struct {
    service UserService
}

func NewUserHandler(svc UserService) *UserHandler {
    return &UserHandler{service: svc}
}

func (h *UserHandler) Routes() chi.Router {
    r := chi.NewRouter()

    r.Get("/", h.List)
    r.Post("/", h.Create)
    r.Route("/{userID}", func(r chi.Router) {
        r.Use(h.UserCtx)  // Load user into context
        r.Get("/", h.Get)
        r.Put("/", h.Update)
        r.Delete("/", h.Delete)
    })

    return r
}

func (h *UserHandler) UserCtx(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        userID := chi.URLParam(r, "userID")

        user, err := h.service.GetByID(r.Context(), userID)
        if err != nil {
            http.Error(w, "User not found", http.StatusNotFound)
            return
        }

        ctx := context.WithValue(r.Context(), userCtxKey, user)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}

func (h *UserHandler) Get(w http.ResponseWriter, r *http.Request) {
    user := r.Context().Value(userCtxKey).(*User)
    respondJSON(w, http.StatusOK, user)
}
```

### Mounting Handlers

```go
// main.go
func main() {
    r := chi.NewRouter()

    // Dependencies
    db := connectDB()
    userRepo := repository.NewUserRepository(db)
    userSvc := service.NewUserService(userRepo)
    userHandler := handler.NewUserHandler(userSvc)

    // Mount
    r.Mount("/api/v1/users", userHandler.Routes())

    http.ListenAndServe(":8080", r)
}
```

---

## PART 3: Gin Router (Alternative)

### Basic Setup

```go
package main

import (
    "github.com/gin-gonic/gin"
)

func main() {
    r := gin.Default() // Includes Logger and Recovery

    // Custom middleware
    r.Use(requestIDMiddleware())

    // Health check
    r.GET("/health", healthHandler)

    // API v1
    v1 := r.Group("/api/v1")
    v1.Use(authMiddleware())
    {
        users := v1.Group("/users")
        {
            users.GET("", listUsers)
            users.POST("", createUser)
            users.GET("/:id", getUser)
            users.PUT("/:id", updateUser)
            users.DELETE("/:id", deleteUser)
        }
    }

    r.Run(":8080")
}
```

### Handler Pattern

```go
type UserHandler struct {
    service UserService
}

func (h *UserHandler) GetUser(c *gin.Context) {
    id := c.Param("id")

    user, err := h.service.GetByID(c.Request.Context(), id)
    if err != nil {
        if errors.Is(err, ErrNotFound) {
            c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
            return
        }
        c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
        return
    }

    c.JSON(http.StatusOK, user)
}

func (h *UserHandler) CreateUser(c *gin.Context) {
    var req CreateUserRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    user, err := h.service.Create(c.Request.Context(), req)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create"})
        return
    }

    c.JSON(http.StatusCreated, user)
}
```

---

## PART 4: Middleware Patterns

### Logging Middleware

```go
func LoggingMiddleware(logger *slog.Logger) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            start := time.Now()

            // Wrap response writer to capture status
            ww := &responseWriter{ResponseWriter: w, status: http.StatusOK}

            // Process request
            next.ServeHTTP(ww, r)

            // Log
            logger.Info("request",
                "method", r.Method,
                "path", r.URL.Path,
                "status", ww.status,
                "duration", time.Since(start),
                "request_id", r.Context().Value(requestIDKey),
            )
        })
    }
}

type responseWriter struct {
    http.ResponseWriter
    status int
}

func (w *responseWriter) WriteHeader(code int) {
    w.status = code
    w.ResponseWriter.WriteHeader(code)
}
```

### Authentication Middleware

```go
func AuthMiddleware(tokenVerifier TokenVerifier) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            // Extract token
            authHeader := r.Header.Get("Authorization")
            if authHeader == "" {
                http.Error(w, "missing authorization", http.StatusUnauthorized)
                return
            }

            token := strings.TrimPrefix(authHeader, "Bearer ")
            if token == authHeader {
                http.Error(w, "invalid authorization format", http.StatusUnauthorized)
                return
            }

            // Verify token
            claims, err := tokenVerifier.Verify(r.Context(), token)
            if err != nil {
                http.Error(w, "invalid token", http.StatusUnauthorized)
                return
            }

            // Add to context
            ctx := context.WithValue(r.Context(), userClaimsKey, claims)
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}

// Helper to get claims from context
func GetUserClaims(ctx context.Context) (*UserClaims, bool) {
    claims, ok := ctx.Value(userClaimsKey).(*UserClaims)
    return claims, ok
}
```

### Rate Limiting Middleware

```go
func RateLimitMiddleware(rps int) func(http.Handler) http.Handler {
    limiter := rate.NewLimiter(rate.Limit(rps), rps*2)

    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            if !limiter.Allow() {
                http.Error(w, "rate limit exceeded", http.StatusTooManyRequests)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}

// Per-IP rate limiting
func PerIPRateLimitMiddleware(rps int) func(http.Handler) http.Handler {
    var (
        mu       sync.Mutex
        limiters = make(map[string]*rate.Limiter)
    )

    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            ip := r.RemoteAddr

            mu.Lock()
            limiter, exists := limiters[ip]
            if !exists {
                limiter = rate.NewLimiter(rate.Limit(rps), rps*2)
                limiters[ip] = limiter
            }
            mu.Unlock()

            if !limiter.Allow() {
                http.Error(w, "rate limit exceeded", http.StatusTooManyRequests)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}
```

### CORS Middleware

```go
func CORSMiddleware(allowedOrigins []string) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            origin := r.Header.Get("Origin")

            // Check if origin is allowed
            allowed := false
            for _, o := range allowedOrigins {
                if o == "*" || o == origin {
                    allowed = true
                    break
                }
            }

            if allowed {
                w.Header().Set("Access-Control-Allow-Origin", origin)
                w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
                w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
                w.Header().Set("Access-Control-Max-Age", "86400")
            }

            // Handle preflight
            if r.Method == "OPTIONS" {
                w.WriteHeader(http.StatusNoContent)
                return
            }

            next.ServeHTTP(w, r)
        })
    }
}
```

---

## PART 5: Request/Response Helpers

### JSON Response

```go
func respondJSON(w http.ResponseWriter, status int, data any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)

    if data != nil {
        if err := json.NewEncoder(w).Encode(data); err != nil {
            slog.Error("failed to encode response", "error", err)
        }
    }
}

func respondError(w http.ResponseWriter, status int, message string) {
    respondJSON(w, status, map[string]string{"error": message})
}
```

### Request Binding

```go
func bindJSON[T any](r *http.Request) (T, error) {
    var v T

    if r.Body == nil {
        return v, errors.New("empty body")
    }

    decoder := json.NewDecoder(r.Body)
    decoder.DisallowUnknownFields() // Strict binding

    if err := decoder.Decode(&v); err != nil {
        return v, fmt.Errorf("invalid JSON: %w", err)
    }

    return v, nil
}

// Usage
func (h *UserHandler) Create(w http.ResponseWriter, r *http.Request) {
    req, err := bindJSON[CreateUserRequest](r)
    if err != nil {
        respondError(w, http.StatusBadRequest, err.Error())
        return
    }

    // Validate
    if err := req.Validate(); err != nil {
        respondError(w, http.StatusBadRequest, err.Error())
        return
    }

    // Process...
}
```

### Validation

```go
type CreateUserRequest struct {
    Name  string `json:"name"`
    Email string `json:"email"`
    Age   int    `json:"age"`
}

func (r CreateUserRequest) Validate() error {
    var errs []string

    if r.Name == "" {
        errs = append(errs, "name is required")
    }
    if r.Email == "" {
        errs = append(errs, "email is required")
    } else if !isValidEmail(r.Email) {
        errs = append(errs, "invalid email format")
    }
    if r.Age < 0 || r.Age > 150 {
        errs = append(errs, "invalid age")
    }

    if len(errs) > 0 {
        return fmt.Errorf("validation failed: %s", strings.Join(errs, ", "))
    }
    return nil
}
```

---

## PART 6: Error Handling

### Domain Errors

```go
// domain/errors.go
var (
    ErrNotFound      = errors.New("not found")
    ErrConflict      = errors.New("conflict")
    ErrUnauthorized  = errors.New("unauthorized")
    ErrForbidden     = errors.New("forbidden")
    ErrInvalidInput  = errors.New("invalid input")
)

type ValidationError struct {
    Field   string `json:"field"`
    Message string `json:"message"`
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("%s: %s", e.Field, e.Message)
}
```

### Error Response Mapping

```go
type ErrorResponse struct {
    Error   string            `json:"error"`
    Details map[string]string `json:"details,omitempty"`
}

func handleError(w http.ResponseWriter, err error) {
    switch {
    case errors.Is(err, ErrNotFound):
        respondJSON(w, http.StatusNotFound, ErrorResponse{Error: "resource not found"})

    case errors.Is(err, ErrConflict):
        respondJSON(w, http.StatusConflict, ErrorResponse{Error: "resource already exists"})

    case errors.Is(err, ErrUnauthorized):
        respondJSON(w, http.StatusUnauthorized, ErrorResponse{Error: "unauthorized"})

    case errors.Is(err, ErrForbidden):
        respondJSON(w, http.StatusForbidden, ErrorResponse{Error: "forbidden"})

    case errors.Is(err, ErrInvalidInput):
        respondJSON(w, http.StatusBadRequest, ErrorResponse{Error: err.Error()})

    default:
        // Log internal errors
        slog.Error("internal error", "error", err)
        respondJSON(w, http.StatusInternalServerError, ErrorResponse{Error: "internal server error"})
    }
}
```

---

## PART 7: Graceful Shutdown

```go
func main() {
    // Setup
    router := setupRouter()
    srv := &http.Server{
        Addr:         ":8080",
        Handler:      router,
        ReadTimeout:  15 * time.Second,
        WriteTimeout: 15 * time.Second,
        IdleTimeout:  60 * time.Second,
    }

    // Start server
    go func() {
        slog.Info("starting server", "addr", srv.Addr)
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            slog.Error("server error", "error", err)
            os.Exit(1)
        }
    }()

    // Wait for interrupt
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    slog.Info("shutting down server...")

    // Graceful shutdown with timeout
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    if err := srv.Shutdown(ctx); err != nil {
        slog.Error("forced shutdown", "error", err)
    }

    slog.Info("server stopped")
}
```

---

## PART 8: gRPC Service

### Proto Definition

```protobuf
// proto/user/v1/user.proto
syntax = "proto3";

package user.v1;

option go_package = "myapp/gen/proto/user/v1;userv1";

service UserService {
    rpc GetUser(GetUserRequest) returns (GetUserResponse);
    rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
    rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);
    rpc UpdateUser(UpdateUserRequest) returns (UpdateUserResponse);
    rpc DeleteUser(DeleteUserRequest) returns (DeleteUserResponse);
}

message User {
    string id = 1;
    string name = 2;
    string email = 3;
    int32 age = 4;
}

message GetUserRequest {
    string id = 1;
}

message GetUserResponse {
    User user = 1;
}

message CreateUserRequest {
    string name = 1;
    string email = 2;
    int32 age = 3;
}

message CreateUserResponse {
    User user = 1;
}

message ListUsersRequest {
    int32 page_size = 1;
    string page_token = 2;
}

message ListUsersResponse {
    repeated User users = 1;
    string next_page_token = 2;
}
```

### Service Implementation

```go
// internal/server/user.go
type UserServer struct {
    userv1.UnimplementedUserServiceServer
    service UserService
}

func NewUserServer(svc UserService) *UserServer {
    return &UserServer{service: svc}
}

func (s *UserServer) GetUser(ctx context.Context, req *userv1.GetUserRequest) (*userv1.GetUserResponse, error) {
    user, err := s.service.GetByID(ctx, req.GetId())
    if err != nil {
        if errors.Is(err, ErrNotFound) {
            return nil, status.Error(codes.NotFound, "user not found")
        }
        return nil, status.Error(codes.Internal, "internal error")
    }

    return &userv1.GetUserResponse{
        User: &userv1.User{
            Id:    user.ID,
            Name:  user.Name,
            Email: user.Email,
            Age:   int32(user.Age),
        },
    }, nil
}

func (s *UserServer) CreateUser(ctx context.Context, req *userv1.CreateUserRequest) (*userv1.CreateUserResponse, error) {
    // Validate
    if req.GetName() == "" {
        return nil, status.Error(codes.InvalidArgument, "name is required")
    }

    user, err := s.service.Create(ctx, CreateUserInput{
        Name:  req.GetName(),
        Email: req.GetEmail(),
        Age:   int(req.GetAge()),
    })
    if err != nil {
        return nil, status.Error(codes.Internal, "failed to create user")
    }

    return &userv1.CreateUserResponse{
        User: &userv1.User{
            Id:    user.ID,
            Name:  user.Name,
            Email: user.Email,
            Age:   int32(user.Age),
        },
    }, nil
}
```

### gRPC Server Setup

```go
func main() {
    // Create gRPC server with interceptors
    srv := grpc.NewServer(
        grpc.ChainUnaryInterceptor(
            loggingInterceptor(),
            recoveryInterceptor(),
            authInterceptor(),
        ),
    )

    // Register services
    userSvc := service.NewUserService(repo)
    userv1.RegisterUserServiceServer(srv, server.NewUserServer(userSvc))

    // Enable reflection (for grpcurl)
    reflection.Register(srv)

    // Start server
    lis, err := net.Listen("tcp", ":9090")
    if err != nil {
        log.Fatalf("failed to listen: %v", err)
    }

    log.Println("gRPC server listening on :9090")
    if err := srv.Serve(lis); err != nil {
        log.Fatalf("failed to serve: %v", err)
    }
}
```

### gRPC Interceptors

```go
func loggingInterceptor() grpc.UnaryServerInterceptor {
    return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
        start := time.Now()

        resp, err := handler(ctx, req)

        slog.Info("grpc request",
            "method", info.FullMethod,
            "duration", time.Since(start),
            "error", err,
        )

        return resp, err
    }
}

func recoveryInterceptor() grpc.UnaryServerInterceptor {
    return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (resp any, err error) {
        defer func() {
            if r := recover(); r != nil {
                slog.Error("panic recovered", "panic", r, "stack", string(debug.Stack()))
                err = status.Error(codes.Internal, "internal error")
            }
        }()
        return handler(ctx, req)
    }
}
```

---

## PART 9: OpenAPI / Swagger

### Using oapi-codegen

```yaml
# api/openapi.yaml
openapi: 3.0.3
info:
  title: User API
  version: 1.0.0

paths:
  /users:
    get:
      summary: List users
      operationId: listUsers
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
      responses:
        '200':
          description: List of users
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/User'

    post:
      summary: Create user
      operationId: createUser
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
      responses:
        '201':
          description: Created user
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'

  /users/{id}:
    get:
      summary: Get user by ID
      operationId: getUser
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: User found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '404':
          description: User not found

components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: string
        name:
          type: string
        email:
          type: string
      required:
        - id
        - name
        - email

    CreateUserRequest:
      type: object
      properties:
        name:
          type: string
        email:
          type: string
      required:
        - name
        - email
```

### Generate Code

```bash
# Install oapi-codegen
go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest

# Generate types and server interface
oapi-codegen -package api -generate types,chi-server api/openapi.yaml > internal/api/openapi.gen.go
```

---

## PART 10: Health Checks

```go
type HealthChecker interface {
    Check(ctx context.Context) error
}

type HealthHandler struct {
    checkers map[string]HealthChecker
}

func (h *HealthHandler) Liveness(w http.ResponseWriter, r *http.Request) {
    respondJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *HealthHandler) Readiness(w http.ResponseWriter, r *http.Request) {
    ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
    defer cancel()

    results := make(map[string]string)
    allHealthy := true

    for name, checker := range h.checkers {
        if err := checker.Check(ctx); err != nil {
            results[name] = err.Error()
            allHealthy = false
        } else {
            results[name] = "ok"
        }
    }

    status := http.StatusOK
    if !allHealthy {
        status = http.StatusServiceUnavailable
    }

    respondJSON(w, status, map[string]any{
        "status": map[bool]string{true: "ok", false: "degraded"}[allHealthy],
        "checks": results,
    })
}

// Database health checker
type DBHealthChecker struct {
    db *sql.DB
}

func (c *DBHealthChecker) Check(ctx context.Context) error {
    return c.db.PingContext(ctx)
}
```

### Routes

```go
r.Get("/health/live", healthHandler.Liveness)
r.Get("/health/ready", healthHandler.Readiness)
```

---

## PART 11: API Versioning

### URL Versioning (Recommended)

```go
r.Route("/api", func(r chi.Router) {
    r.Mount("/v1", v1Router())
    r.Mount("/v2", v2Router())
})
```

### Header Versioning

```go
func VersionMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        version := r.Header.Get("API-Version")
        if version == "" {
            version = "v1" // Default
        }

        ctx := context.WithValue(r.Context(), apiVersionKey, version)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}
```

---

## PART 12: Production Checklist

```
SERVER CONFIGURATION:
[ ] Timeouts configured (read, write, idle)
[ ] Graceful shutdown implemented
[ ] Connection limits set

MIDDLEWARE:
[ ] Request ID for tracing
[ ] Logging with structured output
[ ] Panic recovery
[ ] CORS if needed
[ ] Rate limiting
[ ] Authentication/Authorization

SECURITY:
[ ] HTTPS only in production
[ ] Helmet-style security headers
[ ] Input validation
[ ] SQL injection prevention
[ ] No sensitive data in logs

OBSERVABILITY:
[ ] Health endpoints (/health/live, /health/ready)
[ ] Metrics endpoint (/metrics)
[ ] Request/response logging
[ ] Error tracking

DOCUMENTATION:
[ ] OpenAPI spec
[ ] Example requests
[ ] Error codes documented
```

---

## Sources

- [Chi Router](https://github.com/go-chi/chi)
- [Gin Framework](https://gin-gonic.com/)
- [gRPC Go](https://grpc.io/docs/languages/go/)
- [oapi-codegen](https://github.com/oapi-codegen/oapi-codegen)
- [Go API Patterns 2025](https://cristiancurteanu.com/5-api-design-patterns-in-go-that-solve-your-biggest-problems-2025/)
