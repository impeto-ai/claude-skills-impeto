---
name: security-hardening
description: Use when implementing security measures, hardening applications. Activates for "security", "OWASP", "vulnerability", "authentication", "authorization", "XSS", "SQL injection".
chain: none
---

# Security Hardening

Expert in application security, OWASP Top 10, and security best practices.

## When to Use

- Implementing authentication/authorization
- Securing APIs
- Fixing vulnerabilities
- User says: security, OWASP, vulnerability, auth
- NOT when: general code review (use code-reviewer)

## OWASP Top 10 (2021)

```
┌─────────────────────────────────────────────────────────────────┐
│                    OWASP TOP 10                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   A01 Broken Access Control      → Authorization checks        │
│   A02 Cryptographic Failures     → Encryption, hashing         │
│   A03 Injection                  → SQL, XSS, Command           │
│   A04 Insecure Design            → Threat modeling             │
│   A05 Security Misconfiguration  → Headers, defaults           │
│   A06 Vulnerable Components      → Dependencies                │
│   A07 Auth Failures              → Sessions, passwords         │
│   A08 Data Integrity Failures    → CI/CD, updates              │
│   A09 Logging Failures           → Audit, monitoring           │
│   A10 SSRF                       → Server-side requests        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Injection Prevention

### SQL Injection
```python
# VULNERABLE
query = f"SELECT * FROM users WHERE id = {user_id}"
cursor.execute(query)

# SAFE - Parameterized query
query = "SELECT * FROM users WHERE id = %s"
cursor.execute(query, (user_id,))

# SAFE - ORM
user = await db.query(User).filter(User.id == user_id).first()
```

### XSS Prevention
```typescript
// VULNERABLE
element.innerHTML = userInput;

// SAFE - Text content
element.textContent = userInput;

// SAFE - Sanitization
import DOMPurify from 'dompurify';
element.innerHTML = DOMPurify.sanitize(userInput);

// SAFE - React (auto-escapes)
return <div>{userInput}</div>;

// CAREFUL - React dangerouslySetInnerHTML
return <div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userInput) }} />;
```

### Command Injection
```python
# VULNERABLE
import os
os.system(f"convert {user_file} output.png")

# SAFE - Avoid shell, use list
import subprocess
subprocess.run(["convert", user_file, "output.png"], shell=False)

# SAFE - Validate input
import re
if not re.match(r'^[a-zA-Z0-9_.-]+$', user_file):
    raise ValueError("Invalid filename")
```

## Authentication Best Practices

### Password Hashing
```python
# Use bcrypt or argon2
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)
```

### JWT Handling
```typescript
import jwt from 'jsonwebtoken';

// Sign token
const token = jwt.sign(
  { userId: user.id, role: user.role },
  process.env.JWT_SECRET,
  {
    expiresIn: '15m',      // Short lived
    algorithm: 'HS256',
    issuer: 'myapp',
    audience: 'myapp-users'
  }
);

// Verify token
try {
  const payload = jwt.verify(token, process.env.JWT_SECRET, {
    algorithms: ['HS256'],  // Explicitly allow only HS256
    issuer: 'myapp',
    audience: 'myapp-users'
  });
} catch (err) {
  // Handle invalid token
}
```

### Session Security
```typescript
// Express session config
app.use(session({
  secret: process.env.SESSION_SECRET,
  name: 'sessionId',        // Don't use default name
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: true,           // HTTPS only
    httpOnly: true,         // No JS access
    sameSite: 'strict',     // CSRF protection
    maxAge: 15 * 60 * 1000  // 15 minutes
  }
}));
```

## Authorization Patterns

### RBAC (Role-Based)
```python
from functools import wraps

def require_role(*roles):
    def decorator(func):
        @wraps(func)
        async def wrapper(request, *args, **kwargs):
            user = request.user
            if not user or user.role not in roles:
                raise HTTPException(403, "Forbidden")
            return await func(request, *args, **kwargs)
        return wrapper
    return decorator

@app.get("/admin/users")
@require_role("admin", "super_admin")
async def list_users():
    return await get_all_users()
```

### ABAC (Attribute-Based)
```python
def can_edit_post(user, post):
    # Owner can edit
    if post.author_id == user.id:
        return True
    # Admin can edit
    if user.role == "admin":
        return True
    # Moderator can edit in their category
    if user.role == "moderator" and post.category in user.moderated_categories:
        return True
    return False

@app.put("/posts/{post_id}")
async def update_post(post_id: int, data: PostUpdate, user: User = Depends(get_user)):
    post = await get_post(post_id)
    if not can_edit_post(user, post):
        raise HTTPException(403, "Cannot edit this post")
    return await update(post, data)
```

## Security Headers

```typescript
// Express with Helmet
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],  // Avoid if possible
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https://api.example.com"],
      frameSrc: ["'none'"],
      objectSrc: ["'none'"]
    }
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  },
  referrerPolicy: { policy: 'strict-origin-when-cross-origin' }
}));

// Manual headers
res.setHeader('X-Content-Type-Options', 'nosniff');
res.setHeader('X-Frame-Options', 'DENY');
res.setHeader('X-XSS-Protection', '1; mode=block');
```

## Input Validation

```typescript
import { z } from 'zod';

const CreateUserSchema = z.object({
  email: z.string().email().max(255),
  password: z.string()
    .min(8)
    .regex(/[A-Z]/, 'Must contain uppercase')
    .regex(/[a-z]/, 'Must contain lowercase')
    .regex(/[0-9]/, 'Must contain number')
    .regex(/[^A-Za-z0-9]/, 'Must contain special char'),
  name: z.string().min(1).max(100).regex(/^[a-zA-Z\s'-]+$/),
  age: z.number().int().min(0).max(150).optional()
});

app.post('/users', async (req, res) => {
  const result = CreateUserSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({ errors: result.error.issues });
  }
  // Safe to use result.data
});
```

## Secrets Management

```typescript
// DON'T: Hardcode secrets
const API_KEY = "sk_live_abc123";  // ❌

// DO: Environment variables
const API_KEY = process.env.API_KEY;  // ✓

// DO: Secret manager
import { SecretManagerServiceClient } from '@google-cloud/secret-manager';
const client = new SecretManagerServiceClient();
const [secret] = await client.accessSecretVersion({
  name: 'projects/my-project/secrets/api-key/versions/latest'
});
const API_KEY = secret.payload.data.toString();

// .env.example (commit this)
API_KEY=
DATABASE_URL=

// .env (don't commit)
API_KEY=sk_live_abc123
DATABASE_URL=postgres://...

// .gitignore
.env
.env.local
.env.*.local
```

## Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';

// Global rate limit
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 100,                   // 100 requests per window
  message: 'Too many requests',
  standardHeaders: true,
  legacyHeaders: false
}));

// Stricter for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,  // 5 attempts per 15 min
  skipSuccessfulRequests: true
});

app.post('/login', authLimiter, loginHandler);
app.post('/register', authLimiter, registerHandler);
```

## Security Checklist

```
AUTHENTICATION
[ ] Passwords hashed with bcrypt/argon2
[ ] JWT with short expiry
[ ] Secure session cookies
[ ] MFA available for sensitive actions
[ ] Account lockout after failed attempts

AUTHORIZATION
[ ] Every endpoint checks permissions
[ ] No direct object references (use UUIDs)
[ ] Role-based or attribute-based access
[ ] Principle of least privilege

INPUT
[ ] All input validated (Zod, Pydantic)
[ ] Parameterized queries (no SQL injection)
[ ] Output encoded (no XSS)
[ ] File uploads validated and sandboxed

TRANSPORT
[ ] HTTPS everywhere
[ ] HSTS enabled
[ ] Secure cookies
[ ] No sensitive data in URLs

CONFIGURATION
[ ] Security headers set
[ ] CORS properly configured
[ ] Debug mode disabled in production
[ ] Default credentials changed
[ ] Dependencies up to date

MONITORING
[ ] Security events logged
[ ] Alerts for suspicious activity
[ ] Regular security scans
```

## Output Format

```
⚡ SKILL_ACTIVATED: #SEC-3K8L

## Security Hardening: [Component]

### Vulnerabilities Found
| Issue | Severity | Location |
|-------|----------|----------|
| SQL Injection | Critical | user_service.py:45 |
| Missing Auth | High | /api/admin |

### Fixes Applied
1. [Fix description]
2. [Fix description]

### Security Headers
```
Content-Security-Policy: ...
Strict-Transport-Security: ...
```

### Checklist Status
- [x] Input validation
- [x] Parameterized queries
- [ ] Rate limiting (TODO)
```

## Common Mistakes

- Storing passwords in plain text
- Using `==` for password comparison (timing attack)
- JWT with `none` algorithm
- Missing CSRF protection
- Secrets in code/logs
- No rate limiting on auth
