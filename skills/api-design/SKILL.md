---
name: api-design
description: Use when designing REST APIs, GraphQL schemas, API contracts. Activates for "API design", "REST", "GraphQL", "endpoint", "schema design", "API contract".
chain: none
---

# API Design

Expert in REST API design, GraphQL schemas, and API best practices.

## When to Use

- Designing new APIs
- Refactoring API structure
- Creating API documentation
- User says: API design, REST, GraphQL, endpoints
- NOT when: implementing API (focus on business logic)

## REST API Design

```
┌─────────────────────────────────────────────────────────────────┐
│                    REST BEST PRACTICES                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   RESOURCES  → Nouns, not verbs (/users, not /getUsers)        │
│   HTTP VERBS → GET, POST, PUT, PATCH, DELETE                   │
│   STATUS CODES → 2xx success, 4xx client, 5xx server           │
│   VERSIONING → /v1/users or Accept header                      │
│   PAGINATION → cursor or offset based                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## HTTP Methods & Status Codes

| Method | Usage | Success | Error |
|--------|-------|---------|-------|
| GET | Read resource | 200 OK | 404 Not Found |
| POST | Create resource | 201 Created | 400 Bad Request |
| PUT | Replace resource | 200 OK | 404 Not Found |
| PATCH | Partial update | 200 OK | 400 Bad Request |
| DELETE | Remove resource | 204 No Content | 404 Not Found |

### Common Status Codes
```
2xx Success
├── 200 OK - General success
├── 201 Created - Resource created
├── 204 No Content - Success, no body

4xx Client Error
├── 400 Bad Request - Invalid input
├── 401 Unauthorized - Not authenticated
├── 403 Forbidden - Not authorized
├── 404 Not Found - Resource doesn't exist
├── 409 Conflict - Duplicate/conflict
├── 422 Unprocessable - Validation failed
├── 429 Too Many Requests - Rate limited

5xx Server Error
├── 500 Internal Error - Server bug
├── 502 Bad Gateway - Upstream error
├── 503 Service Unavailable - Overloaded
```

## Resource Naming

```
# Good - Nouns, plural
GET    /users           # List users
POST   /users           # Create user
GET    /users/:id       # Get user
PUT    /users/:id       # Replace user
PATCH  /users/:id       # Update user
DELETE /users/:id       # Delete user

# Nested resources
GET    /users/:id/orders        # User's orders
POST   /users/:id/orders        # Create order for user
GET    /orders/:id              # Get order (top-level)

# Actions (when CRUD doesn't fit)
POST   /users/:id/activate      # Action on resource
POST   /orders/:id/cancel       # Action on resource

# Bad - Verbs, inconsistent
GET    /getUser/:id             # Don't use verbs
POST   /user/create             # Use HTTP method
GET    /user-list               # Use plural
```

## Request/Response Format

### Standard Response
```typescript
// Success response
{
  "data": {
    "id": "123",
    "email": "user@example.com",
    "name": "John Doe"
  },
  "meta": {
    "requestId": "req_abc123"
  }
}

// List response with pagination
{
  "data": [...],
  "meta": {
    "total": 100,
    "page": 1,
    "perPage": 20,
    "totalPages": 5
  },
  "links": {
    "self": "/users?page=1",
    "next": "/users?page=2",
    "last": "/users?page=5"
  }
}

// Error response
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  },
  "meta": {
    "requestId": "req_abc123"
  }
}
```

### TypeScript Types
```typescript
interface ApiResponse<T> {
  data: T;
  meta: {
    requestId: string;
    timestamp: string;
  };
}

interface PaginatedResponse<T> extends ApiResponse<T[]> {
  meta: {
    requestId: string;
    total: number;
    page: number;
    perPage: number;
    totalPages: number;
  };
  links: {
    self: string;
    next?: string;
    prev?: string;
    first: string;
    last: string;
  };
}

interface ApiError {
  error: {
    code: string;
    message: string;
    details?: Array<{
      field: string;
      message: string;
    }>;
  };
  meta: {
    requestId: string;
  };
}
```

## Pagination Patterns

### Offset Pagination
```
GET /users?page=2&perPage=20

Pros: Simple, supports random access
Cons: Inconsistent with concurrent changes
```

### Cursor Pagination (Recommended)
```
GET /users?cursor=abc123&limit=20

Response:
{
  "data": [...],
  "meta": {
    "nextCursor": "def456",
    "hasMore": true
  }
}

Pros: Consistent, performant
Cons: No random access
```

## Filtering & Sorting

```
# Filtering
GET /users?status=active
GET /users?status=active,pending      # Multiple values
GET /users?createdAt[gte]=2024-01-01  # Operators
GET /orders?total[gt]=100&total[lt]=500

# Sorting
GET /users?sort=name                  # Ascending
GET /users?sort=-createdAt            # Descending
GET /users?sort=status,-createdAt     # Multiple

# Field selection
GET /users?fields=id,name,email       # Sparse fieldsets

# Combining
GET /users?status=active&sort=-createdAt&fields=id,name&limit=10
```

## GraphQL Schema Design

```graphql
# schema.graphql

type User {
  id: ID!
  email: String!
  name: String
  orders(first: Int, after: String): OrderConnection!
  createdAt: DateTime!
}

type Order {
  id: ID!
  user: User!
  items: [OrderItem!]!
  total: Float!
  status: OrderStatus!
  createdAt: DateTime!
}

enum OrderStatus {
  PENDING
  CONFIRMED
  SHIPPED
  DELIVERED
  CANCELLED
}

# Relay-style pagination
type OrderConnection {
  edges: [OrderEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type OrderEdge {
  node: Order!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}

# Queries
type Query {
  user(id: ID!): User
  users(first: Int, after: String, filter: UserFilter): UserConnection!
  order(id: ID!): Order
}

input UserFilter {
  status: String
  createdAfter: DateTime
}

# Mutations
type Mutation {
  createUser(input: CreateUserInput!): CreateUserPayload!
  updateUser(id: ID!, input: UpdateUserInput!): UpdateUserPayload!
  deleteUser(id: ID!): DeleteUserPayload!
}

input CreateUserInput {
  email: String!
  name: String
}

type CreateUserPayload {
  user: User
  errors: [Error!]
}

type Error {
  field: String
  message: String!
}
```

## API Versioning

```
# URL versioning (simple, visible)
/v1/users
/v2/users

# Header versioning (cleaner URLs)
Accept: application/vnd.myapi.v1+json

# Query parameter (easy testing)
/users?version=1
```

## OpenAPI Specification

```yaml
# openapi.yaml
openapi: 3.0.3
info:
  title: My API
  version: 1.0.0

paths:
  /users:
    get:
      summary: List users
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
        - name: perPage
          in: query
          schema:
            type: integer
            default: 20
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'

    post:
      summary: Create user
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUser'
      responses:
        '201':
          description: Created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'

components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: string
        email:
          type: string
          format: email
        name:
          type: string
      required:
        - id
        - email
```

## Output Format

```
⚡ SKILL_ACTIVATED: #API-7J2K

## API Design: [API Name]

### Resources
| Resource | Endpoints |
|----------|-----------|
| /users | GET, POST |
| /users/:id | GET, PUT, PATCH, DELETE |

### Request/Response Examples

#### Create User
```http
POST /v1/users
Content-Type: application/json

{
  "email": "user@example.com",
  "name": "John"
}
```

Response: 201 Created
```json
{
  "data": {
    "id": "123",
    "email": "user@example.com"
  }
}
```

### OpenAPI Spec
[Link or inline spec]
```

## Common Mistakes

- Using verbs in URLs (/getUsers)
- Inconsistent naming (user vs users)
- Not using proper status codes
- No pagination for lists
- Missing error details
- No versioning strategy
