---
name: database-migrations
description: Use when managing database migrations, schema changes, safe deployments. Activates for "migration", "schema change", "database migration", "alter table", "prisma migrate", "drizzle".
chain: none
---

# Database Migrations

Expert in safe database migrations, schema evolution, and zero-downtime deployments.

## When to Use

- Creating database migrations
- Changing database schema
- Planning safe schema evolution
- User says: migration, schema change, alter table
- NOT when: designing initial schema (use api-design)

## Migration Safety Levels

```
┌─────────────────────────────────────────────────────────────────┐
│                    MIGRATION SAFETY                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   SAFE (no lock, no data loss)                                 │
│   ├── ADD COLUMN (nullable, with default)                      │
│   ├── ADD INDEX CONCURRENTLY                                   │
│   ├── ADD TABLE                                                │
│   └── ADD CONSTRAINT (not validated)                           │
│                                                                 │
│   CAUTION (brief lock or careful execution)                    │
│   ├── ADD COLUMN NOT NULL (with default)                       │
│   ├── RENAME COLUMN (requires code change)                     │
│   └── ADD FOREIGN KEY                                          │
│                                                                 │
│   DANGEROUS (lock, data loss risk)                             │
│   ├── DROP COLUMN                                              │
│   ├── CHANGE COLUMN TYPE                                       │
│   ├── ADD INDEX (without CONCURRENTLY)                         │
│   └── RENAME TABLE                                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Safe Migration Patterns

### Adding a Column
```sql
-- SAFE: Nullable column
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- SAFE: With default (Postgres 11+)
ALTER TABLE users ADD COLUMN status VARCHAR(20) DEFAULT 'active';

-- UNSAFE: NOT NULL without default (locks table)
-- ALTER TABLE users ADD COLUMN status VARCHAR(20) NOT NULL;

-- SAFE: NOT NULL in steps
-- Step 1: Add nullable
ALTER TABLE users ADD COLUMN status VARCHAR(20);
-- Step 2: Backfill
UPDATE users SET status = 'active' WHERE status IS NULL;
-- Step 3: Add constraint
ALTER TABLE users ALTER COLUMN status SET NOT NULL;
```

### Adding an Index
```sql
-- UNSAFE: Locks table
-- CREATE INDEX idx_users_email ON users(email);

-- SAFE: Concurrent (Postgres)
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);

-- Note: Cannot be in a transaction
```

### Renaming a Column (Zero Downtime)
```
Phase 1: Deploy code that reads BOTH old and new column
Phase 2: Migration - add new column, copy data
Phase 3: Deploy code that writes to BOTH columns
Phase 4: Backfill remaining data
Phase 5: Deploy code that only uses new column
Phase 6: Migration - drop old column
```

### Dropping a Column
```sql
-- Step 1: Deploy code that doesn't use the column
-- Step 2: Wait for all old code to be replaced
-- Step 3: Drop the column
ALTER TABLE users DROP COLUMN old_column;
```

## Migration Tools

### Prisma
```typescript
// prisma/schema.prisma
model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String?
  status    String   @default("active")  // New field
  createdAt DateTime @default(now())
}

// Commands
// npx prisma migrate dev --name add_status_field
// npx prisma migrate deploy (production)
```

### Drizzle
```typescript
// drizzle/schema.ts
import { pgTable, serial, varchar, timestamp } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  email: varchar('email', { length: 255 }).unique().notNull(),
  name: varchar('name', { length: 255 }),
  status: varchar('status', { length: 50 }).default('active'),
  createdAt: timestamp('created_at').defaultNow(),
});

// Commands
// npx drizzle-kit generate:pg
// npx drizzle-kit push:pg
```

### Supabase
```sql
-- supabase/migrations/20240101_add_status.sql
ALTER TABLE users ADD COLUMN status VARCHAR(50) DEFAULT 'active';

-- Create index concurrently
CREATE INDEX CONCURRENTLY idx_users_status ON users(status);

-- Commands
-- supabase db push (development)
-- supabase db push --linked (production)
```

### Raw SQL (Postgres)
```sql
-- migrations/001_create_users.sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);

-- migrations/002_add_status.sql
ALTER TABLE users ADD COLUMN status VARCHAR(50) DEFAULT 'active';
CREATE INDEX CONCURRENTLY idx_users_status ON users(status);
```

## Rollback Strategies

### Reversible Migrations
```typescript
// migration.ts
export async function up(db) {
  await db.schema.alterTable('users', (table) => {
    table.addColumn('status', 'varchar(50)', (col) => col.defaultTo('active'));
  });
}

export async function down(db) {
  await db.schema.alterTable('users', (table) => {
    table.dropColumn('status');
  });
}
```

### Forward-Only (Recommended)
```sql
-- Instead of rolling back, apply a new forward migration
-- Migration 003: Add status
ALTER TABLE users ADD COLUMN status VARCHAR(50);

-- Migration 004: Oops, wrong type - fix it
ALTER TABLE users ALTER COLUMN status TYPE VARCHAR(100);
```

## Data Migrations

### Backfill Pattern
```sql
-- Batch update to avoid long locks
DO $$
DECLARE
  batch_size INT := 1000;
  rows_updated INT;
BEGIN
  LOOP
    UPDATE users
    SET status = 'active'
    WHERE id IN (
      SELECT id FROM users
      WHERE status IS NULL
      LIMIT batch_size
      FOR UPDATE SKIP LOCKED
    );

    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    EXIT WHEN rows_updated = 0;

    COMMIT;
    PERFORM pg_sleep(0.1);  -- Brief pause
  END LOOP;
END $$;
```

### Python Backfill
```python
async def backfill_status():
    batch_size = 1000
    while True:
        result = await db.execute(
            """
            UPDATE users
            SET status = 'active'
            WHERE id IN (
                SELECT id FROM users
                WHERE status IS NULL
                LIMIT :batch_size
            )
            RETURNING id
            """,
            {"batch_size": batch_size}
        )
        if result.rowcount == 0:
            break
        await asyncio.sleep(0.1)
```

## CI/CD Integration

### Pre-Deploy Check
```yaml
# .github/workflows/migration-check.yml
name: Migration Check

on: pull_request

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check migration safety
        run: |
          # Check for dangerous patterns
          if grep -r "DROP COLUMN\|DROP TABLE\|ALTER.*TYPE" migrations/; then
            echo "⚠️ Dangerous migration detected!"
            echo "Ensure zero-downtime deployment strategy"
          fi

      - name: Validate migration
        run: |
          # Test migration against shadow database
          npx prisma migrate deploy --preview-feature
```

### Deploy Order
```yaml
jobs:
  migrate:
    runs-on: ubuntu-latest
    steps:
      - name: Run migrations
        run: npx prisma migrate deploy

  deploy:
    needs: migrate
    runs-on: ubuntu-latest
    steps:
      - name: Deploy application
        run: railway up
```

## Output Format

```
⚡ SKILL_ACTIVATED: #MIGR-4H6T

## Database Migration: [Migration Name]

### Safety Assessment
- Risk Level: LOW/MEDIUM/HIGH
- Requires Lock: Yes/No
- Zero Downtime: Yes/No

### Migration Plan
1. [Step 1]
2. [Step 2]
3. [Step 3]

### SQL
```sql
[migration SQL]
```

### Rollback Plan
```sql
[rollback SQL if applicable]
```

### Pre-Deploy Checklist
- [ ] Tested on staging
- [ ] Backfill plan if needed
- [ ] Monitoring in place
- [ ] Rollback tested
```

## Common Mistakes

- Running migrations in transaction with CONCURRENTLY
- Not testing migrations on production-like data
- Dropping columns before removing code references
- Adding NOT NULL without default on large tables
- Not using batched updates for backfills
- Missing indexes after adding foreign keys
