---
name: price-dev
description: Desenvolvimento de features no Innovagro Price seguindo padrões GOLD. Activates for price, inova-price, desenvolver price, criar feature price, implementar price.
chain: price-review
code: "#PDEV-7K4X"
---

# Price Dev - Desenvolvimento de Alto Nível

**Codigo da Skill:** `#PDEV-7K4X`

Skill especializada em desenvolver features no projeto Innovagro Price (inova-price) seguindo os padrões GOLD estabelecidos. Foco em construir código de alto nível, type-safe, reutilizável e manutenível.

## When to Use

- Ao criar nova feature no price
- Ao implementar componentes
- Ao criar APIs/routes
- Ao adicionar hooks customizados
- Quando usuário menciona: "price", "desenvolver price", "criar feature", "implementar"
- NOT when: apenas auditoria (use price-review)

---

## Tech Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRICE TECH STACK                             │
├─────────────────────────────────────────────────────────────────┤
│  Framework:     Next.js 14.2+ (App Router)                      │
│  Language:      TypeScript 5.9.3 (STRICT mode required)         │
│  Styling:       Tailwind CSS 3.4.17 + Shadcn/ui                 │
│  UI Base:       Radix UI primitives                             │
│  Backend:       Supabase (PostgreSQL) + Agrotita API            │
│  State:         React Context API + Custom Hooks                │
│  Auth:          JWT-based (cookies) + Supabase Auth             │
│  Validation:    Zod                                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## GOLD STANDARD Architecture

### 1. Directory Structure

```
/price
├── app/                          # Next.js App Router
│   ├── api/                      # API Routes (feature-based)
│   │   └── [feature]/
│   │       ├── route.ts          # GET/POST handlers
│   │       └── [id]/
│   │           └── route.ts      # GET/PATCH/DELETE by ID
│   │
│   └── [feature]/                # Pages
│       ├── page.tsx              # Server Component (list/main)
│       └── [id]/
│           └── page.tsx          # Detail page
│
├── components/                   # React Components
│   ├── ui/                       # Base UI (Shadcn)
│   ├── molecules/                # Reusable patterns
│   ├── organisms/                # Complex compositions
│   ├── forms/                    # Form components
│   └── [feature]/                # Feature-specific
│       ├── [feature]-list.tsx
│       ├── [feature]-card.tsx
│       ├── [feature]-table.tsx
│       ├── [feature]-form.tsx
│       └── molecules/            # Feature molecules
│
├── hooks/                        # Custom Hooks
│   ├── use-[feature].ts          # Feature hook
│   ├── use-[feature]-form.ts     # Form state hook
│   └── use-[feature]-params.ts   # Parameters hook
│
├── lib/                          # Utilities & Services
│   ├── [feature]-service.ts      # Business logic
│   ├── database/                 # DB queries
│   │   ├── [feature]-queries.ts
│   │   ├── [feature]-types.ts
│   │   └── [feature]-transformers.ts
│   └── utils/                    # Helpers
│       └── [feature]-helpers.ts
│
├── types/                        # Type Definitions
│   ├── entities.ts               # SINGLE SOURCE OF TRUTH
│   └── [feature].types.ts        # Feature-specific
│
└── actions/                      # Server Actions
    └── [feature]/
        └── actions.ts
```

---

### 2. Naming Conventions (OBRIGATÓRIO)

| Element | Convention | Example |
|---------|------------|---------|
| **Files** | kebab-case | `solicitacao-card.tsx` |
| **Components** | PascalCase | `SolicitacaoCard` |
| **Hooks** | use-kebab-case | `use-solicitacoes.ts` |
| **Services** | kebab-case-service | `contratos-service.ts` |
| **Types files** | kebab-case.types | `comercializacao.types.ts` |
| **DB fields** | snake_case | `grupo_familiar_id` |
| **JS variables** | camelCase | `grupoFamiliarId` |
| **Constants** | UPPER_SNAKE_CASE | `MAX_PAGE_SIZE` |
| **Routes** | kebab-case | `/solicitacoes-contrato` |

---

### 3. Component Patterns (GOLD)

#### A. Server vs Client Components

```typescript
// SERVER COMPONENT (default) - data fetching direto
// app/solicitacoes/page.tsx
export default async function SolicitacoesPage() {
  const data = await fetchSolicitacoes(); // Direct DB access
  return <SolicitacoesList data={data} />;
}

// CLIENT COMPONENT - interatividade
// components/solicitacoes/solicitacoes-list.tsx
"use client";

export function SolicitacoesList({ data }: Props) {
  const [filter, setFilter] = useState<Filter>({});
  // Interactive logic here
}
```

#### B. Component Size Limit: MAX 300 LINES

Se exceder, extrair para:
- Molecules (reusable pieces)
- Custom hooks (business logic)
- Helpers (utility functions)

#### C. Atomic Design

```
ui/           → Atoms (Button, Input, Dialog)
molecules/    → Molecules (MetricCard, StatusBadge)
organisms/    → Organisms (DashboardMetrics, SolicitacaoEditarWrapper)
forms/        → Form Components (FormComercializacaoModern)
[feature]/    → Feature-specific compositions
```

#### D. Wrapper Pattern (para reutilização)

```typescript
// GOLD: components/organisms/SolicitacaoEditarWrapper.tsx
interface WrapperProps {
  solicitacao: Solicitacao;
  isBackoffice?: boolean;
  onSave: (data: Partial<Solicitacao>) => Promise<void>;
  onClose: () => void;
}

export function SolicitacaoEditarWrapper({
  solicitacao,
  isBackoffice = false,
  onSave,
  onClose
}: WrapperProps) {
  // Encapsula lógica de edição
  // Reutiliza FormComercializacaoModern (ZERO duplicação)
  return (
    <Dialog>
      <FormComercializacaoModern
        mode="edit"
        defaultValues={solicitacao}
        onSubmit={onSave}
        isBackoffice={isBackoffice}
      />
    </Dialog>
  );
}
```

---

### 4. Hook Patterns (GOLD)

#### A. Feature Hook Structure

```typescript
// hooks/use-solicitacoes.ts
"use client";

import { useState, useCallback, useMemo } from "react";
import { Solicitacao, SolicitacaoFilter } from "@/types/entities";

interface UseSolicitacoesReturn {
  // State
  data: Solicitacao[];
  loading: boolean;
  error: Error | null;

  // Actions
  fetch: (filter?: SolicitacaoFilter) => Promise<void>;
  create: (data: Partial<Solicitacao>) => Promise<Solicitacao>;
  update: (id: string, data: Partial<Solicitacao>) => Promise<void>;
  remove: (id: string) => Promise<void>;

  // Utilities
  refresh: () => Promise<void>;
  clearError: () => void;
}

export function useSolicitacoes(): UseSolicitacoesReturn {
  const [data, setData] = useState<Solicitacao[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const fetch = useCallback(async (filter?: SolicitacaoFilter) => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.get('/api/solicitacoes-contrato', { params: filter });
      setData(response.data);
    } catch (err) {
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  }, []);

  // ... other methods with useCallback

  return useMemo(() => ({
    data,
    loading,
    error,
    fetch,
    create,
    update,
    remove,
    refresh,
    clearError
  }), [data, loading, error, fetch, create, update, remove, refresh, clearError]);
}
```

#### B. Form Hook Structure

```typescript
// hooks/use-solicitacao-form.ts
"use client";

import { useReducer, useCallback } from "react";
import { z } from "zod";

// Schema validation
const solicitacaoSchema = z.object({
  produtor_id: z.string().min(1, "Produtor obrigatório"),
  produto_id: z.string().min(1, "Produto obrigatório"),
  quantidade: z.number().positive("Quantidade deve ser positiva"),
  // ... other fields
});

type SolicitacaoFormData = z.infer<typeof solicitacaoSchema>;

interface FormState {
  data: Partial<SolicitacaoFormData>;
  errors: Record<string, string>;
  isDirty: boolean;
  isSubmitting: boolean;
}

type FormAction =
  | { type: 'SET_FIELD'; field: keyof SolicitacaoFormData; value: any }
  | { type: 'SET_ERRORS'; errors: Record<string, string> }
  | { type: 'RESET'; initialData?: Partial<SolicitacaoFormData> }
  | { type: 'SUBMIT_START' }
  | { type: 'SUBMIT_END' };

function formReducer(state: FormState, action: FormAction): FormState {
  switch (action.type) {
    case 'SET_FIELD':
      return {
        ...state,
        data: { ...state.data, [action.field]: action.value },
        isDirty: true,
        errors: { ...state.errors, [action.field]: '' }
      };
    case 'SET_ERRORS':
      return { ...state, errors: action.errors };
    case 'RESET':
      return {
        data: action.initialData || {},
        errors: {},
        isDirty: false,
        isSubmitting: false
      };
    case 'SUBMIT_START':
      return { ...state, isSubmitting: true };
    case 'SUBMIT_END':
      return { ...state, isSubmitting: false };
    default:
      return state;
  }
}

export function useSolicitacaoForm(initialData?: Partial<SolicitacaoFormData>) {
  const [state, dispatch] = useReducer(formReducer, {
    data: initialData || {},
    errors: {},
    isDirty: false,
    isSubmitting: false
  });

  const setField = useCallback(<K extends keyof SolicitacaoFormData>(
    field: K,
    value: SolicitacaoFormData[K]
  ) => {
    dispatch({ type: 'SET_FIELD', field, value });
  }, []);

  const validate = useCallback((): boolean => {
    const result = solicitacaoSchema.safeParse(state.data);
    if (!result.success) {
      const errors: Record<string, string> = {};
      result.error.errors.forEach(err => {
        errors[err.path[0] as string] = err.message;
      });
      dispatch({ type: 'SET_ERRORS', errors });
      return false;
    }
    return true;
  }, [state.data]);

  const handleSubmit = useCallback(async (
    onSubmit: (data: SolicitacaoFormData) => Promise<void>
  ) => {
    if (!validate()) return;

    dispatch({ type: 'SUBMIT_START' });
    try {
      await onSubmit(state.data as SolicitacaoFormData);
    } finally {
      dispatch({ type: 'SUBMIT_END' });
    }
  }, [state.data, validate]);

  return {
    ...state,
    setField,
    validate,
    handleSubmit,
    reset: (data?: Partial<SolicitacaoFormData>) =>
      dispatch({ type: 'RESET', initialData: data })
  };
}
```

---

### 5. Type Safety (GOLD - ZERO ANY)

#### A. Central Types (entities.ts)

```typescript
// types/entities.ts - SINGLE SOURCE OF TRUTH

// Base interfaces
export interface BaseEntity {
  id: string;
  created_at: string;
  updated_at: string;
}

// Domain entities
export interface Solicitacao extends BaseEntity {
  numero_solicitacao: number;
  status: SolicitacaoStatus;
  produtor_id: string;
  produtor_nome: string;
  grupo_familiar_id: string;
  produto_id: string;
  produto_nome: string;
  quantidade: number;
  unidade: string;
  preco_unitario: number;
  moeda: Moeda;
  // ... all fields strictly typed
}

export type SolicitacaoStatus =
  | 'rascunho'
  | 'pendente'
  | 'aprovado'
  | 'recusado'
  | 'em_processamento'
  | 'finalizado';

export type Moeda = 'BRL' | 'USD' | 'EUR';

// Filter types
export interface SolicitacaoFilter {
  status?: SolicitacaoStatus[];
  produtor_id?: string;
  grupo_familiar_id?: string;
  data_inicio?: string;
  data_fim?: string;
  page?: number;
  limit?: number;
}

// Form types (partial for creation/edit)
export type SolicitacaoCreate = Omit<Solicitacao, keyof BaseEntity | 'numero_solicitacao'>;
export type SolicitacaoUpdate = Partial<SolicitacaoCreate>;
```

#### B. API Response Types

```typescript
// types/api.types.ts

export interface ApiResponse<T> {
  data: T;
  error: null;
}

export interface ApiError {
  data: null;
  error: {
    code: string;
    message: string;
    details?: Record<string, string>;
  };
}

export type ApiResult<T> = ApiResponse<T> | ApiError;

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}
```

#### C. Component Props Types

```typescript
// components/solicitacoes/solicitacao-card.tsx

import { Solicitacao } from "@/types/entities";

interface SolicitacaoCardProps {
  solicitacao: Solicitacao;
  onEdit?: (id: string) => void;
  onDelete?: (id: string) => void;
  isCompact?: boolean;
  className?: string;
}

export function SolicitacaoCard({
  solicitacao,
  onEdit,
  onDelete,
  isCompact = false,
  className
}: SolicitacaoCardProps) {
  // ...
}
```

---

### 6. API Route Patterns (GOLD)

#### A. Route Handler Structure

```typescript
// app/api/solicitacoes-contrato/route.ts
import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { supabaseAdmin } from "@/lib/supabase";
import { getUserFromRequest } from "@/lib/auth-middleware-server";
import { Solicitacao, SolicitacaoCreate } from "@/types/entities";

// Validation schemas
const querySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  status: z.string().optional(),
  grupo_familiar_id: z.string().uuid().optional()
});

const createSchema = z.object({
  produtor_id: z.string().uuid(),
  produto_id: z.string().uuid(),
  quantidade: z.number().positive(),
  preco_unitario: z.number().positive(),
  moeda: z.enum(['BRL', 'USD', 'EUR'])
  // ... all required fields
});

// GET - List with pagination
export async function GET(request: NextRequest) {
  try {
    // 1. Authentication
    const user = await getUserFromRequest(request);
    if (!user) {
      return NextResponse.json(
        { error: { code: 'UNAUTHORIZED', message: 'Não autenticado' } },
        { status: 401 }
      );
    }

    // 2. Parse & validate query params
    const searchParams = Object.fromEntries(request.nextUrl.searchParams);
    const validationResult = querySchema.safeParse(searchParams);

    if (!validationResult.success) {
      return NextResponse.json(
        { error: { code: 'VALIDATION_ERROR', message: 'Parâmetros inválidos', details: validationResult.error.flatten().fieldErrors } },
        { status: 400 }
      );
    }

    const { page, limit, status, grupo_familiar_id } = validationResult.data;

    // 3. Build query
    let query = supabaseAdmin
      .from('solicitacoes_contrato')
      .select('*', { count: 'exact' });

    // 4. Apply filters
    if (status) {
      query = query.eq('status', status);
    }
    if (grupo_familiar_id) {
      query = query.eq('grupo_familiar_id', grupo_familiar_id);
    }

    // 5. Apply pagination
    const from = (page - 1) * limit;
    const to = from + limit - 1;
    query = query.range(from, to).order('created_at', { ascending: false });

    // 6. Execute
    const { data, error, count } = await query;

    if (error) {
      console.error('[API] Database error:', error);
      return NextResponse.json(
        { error: { code: 'DATABASE_ERROR', message: 'Erro ao buscar dados' } },
        { status: 500 }
      );
    }

    // 7. Return with pagination
    return NextResponse.json({
      data,
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit)
      }
    });

  } catch (err) {
    console.error('[API] Unexpected error:', err);
    return NextResponse.json(
      { error: { code: 'INTERNAL_ERROR', message: 'Erro interno do servidor' } },
      { status: 500 }
    );
  }
}

// POST - Create
export async function POST(request: NextRequest) {
  try {
    // 1. Authentication
    const user = await getUserFromRequest(request);
    if (!user) {
      return NextResponse.json(
        { error: { code: 'UNAUTHORIZED', message: 'Não autenticado' } },
        { status: 401 }
      );
    }

    // 2. Parse & validate body
    const body = await request.json();
    const validationResult = createSchema.safeParse(body);

    if (!validationResult.success) {
      return NextResponse.json(
        { error: { code: 'VALIDATION_ERROR', message: 'Dados inválidos', details: validationResult.error.flatten().fieldErrors } },
        { status: 400 }
      );
    }

    // 3. Create record
    const { data, error } = await supabaseAdmin
      .from('solicitacoes_contrato')
      .insert({
        ...validationResult.data,
        criado_por: user.id,
        status: 'rascunho'
      })
      .select()
      .single();

    if (error) {
      console.error('[API] Insert error:', error);
      return NextResponse.json(
        { error: { code: 'DATABASE_ERROR', message: 'Erro ao criar registro' } },
        { status: 500 }
      );
    }

    return NextResponse.json({ data }, { status: 201 });

  } catch (err) {
    console.error('[API] Unexpected error:', err);
    return NextResponse.json(
      { error: { code: 'INTERNAL_ERROR', message: 'Erro interno do servidor' } },
      { status: 500 }
    );
  }
}
```

---

### 7. Service Layer Pattern (GOLD)

```typescript
// lib/solicitacoes-service.ts

import { supabaseAdmin } from "@/lib/supabase";
import {
  Solicitacao,
  SolicitacaoCreate,
  SolicitacaoUpdate,
  SolicitacaoFilter
} from "@/types/entities";
import {
  transformToDatabase,
  transformFromDatabase
} from "@/lib/database/solicitacoes-transformers";

interface ServiceResult<T> {
  data: T | null;
  error: string | null;
}

class SolicitacoesService {
  async list(filter: SolicitacaoFilter): Promise<ServiceResult<Solicitacao[]>> {
    try {
      let query = supabaseAdmin
        .from('solicitacoes_contrato')
        .select('*');

      // Apply filters
      if (filter.status?.length) {
        query = query.in('status', filter.status);
      }
      if (filter.grupo_familiar_id) {
        query = query.eq('grupo_familiar_id', filter.grupo_familiar_id);
      }
      if (filter.data_inicio) {
        query = query.gte('created_at', filter.data_inicio);
      }
      if (filter.data_fim) {
        query = query.lte('created_at', filter.data_fim);
      }

      // Pagination
      const page = filter.page || 1;
      const limit = filter.limit || 20;
      const from = (page - 1) * limit;

      query = query.range(from, from + limit - 1);
      query = query.order('created_at', { ascending: false });

      const { data, error } = await query;

      if (error) throw error;

      return {
        data: data?.map(transformFromDatabase) || [],
        error: null
      };
    } catch (err) {
      console.error('[SolicitacoesService] list error:', err);
      return {
        data: null,
        error: 'Erro ao buscar solicitações'
      };
    }
  }

  async getById(id: string): Promise<ServiceResult<Solicitacao>> {
    try {
      const { data, error } = await supabaseAdmin
        .from('solicitacoes_contrato')
        .select('*')
        .eq('id', id)
        .single();

      if (error) throw error;

      return {
        data: transformFromDatabase(data),
        error: null
      };
    } catch (err) {
      console.error('[SolicitacoesService] getById error:', err);
      return {
        data: null,
        error: 'Erro ao buscar solicitação'
      };
    }
  }

  async create(
    data: SolicitacaoCreate,
    userId: string
  ): Promise<ServiceResult<Solicitacao>> {
    try {
      const dbData = transformToDatabase({
        ...data,
        criado_por: userId,
        status: 'rascunho'
      });

      const { data: created, error } = await supabaseAdmin
        .from('solicitacoes_contrato')
        .insert(dbData)
        .select()
        .single();

      if (error) throw error;

      return {
        data: transformFromDatabase(created),
        error: null
      };
    } catch (err) {
      console.error('[SolicitacoesService] create error:', err);
      return {
        data: null,
        error: 'Erro ao criar solicitação'
      };
    }
  }

  async update(
    id: string,
    data: SolicitacaoUpdate
  ): Promise<ServiceResult<Solicitacao>> {
    try {
      const dbData = transformToDatabase(data);

      const { data: updated, error } = await supabaseAdmin
        .from('solicitacoes_contrato')
        .update(dbData)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;

      return {
        data: transformFromDatabase(updated),
        error: null
      };
    } catch (err) {
      console.error('[SolicitacoesService] update error:', err);
      return {
        data: null,
        error: 'Erro ao atualizar solicitação'
      };
    }
  }

  async delete(id: string): Promise<ServiceResult<void>> {
    try {
      const { error } = await supabaseAdmin
        .from('solicitacoes_contrato')
        .delete()
        .eq('id', id);

      if (error) throw error;

      return { data: undefined, error: null };
    } catch (err) {
      console.error('[SolicitacoesService] delete error:', err);
      return {
        data: null,
        error: 'Erro ao deletar solicitação'
      };
    }
  }
}

export const solicitacoesService = new SolicitacoesService();
```

---

### 8. UI Component Patterns (Shadcn + Custom)

#### A. Use Base Components

```typescript
// SEMPRE usar componentes de components/ui/
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader } from "@/components/ui/dialog";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger } from "@/components/ui/select";

// Form system customizado
import {
  ModernFormContainer,
  FormSection,
  FormGrid,
  ModernInput,
  ModernSelect,
  ModernButton,
  CurrencyInput,
  ServerSearchbox
} from "@/components/ui/modern-form";
```

#### B. Molecule Pattern

```typescript
// components/molecules/metric-card.tsx
import { Card, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";

interface MetricCardProps {
  title: string;
  value: string | number;
  trend?: {
    value: number;
    isPositive: boolean;
  };
  icon?: React.ReactNode;
  className?: string;
}

export function MetricCard({
  title,
  value,
  trend,
  icon,
  className
}: MetricCardProps) {
  return (
    <Card className={cn("", className)}>
      <CardContent className="p-4">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm text-muted-foreground">{title}</p>
            <p className="text-2xl font-bold">{value}</p>
            {trend && (
              <p className={cn(
                "text-xs",
                trend.isPositive ? "text-green-600" : "text-red-600"
              )}>
                {trend.isPositive ? "+" : ""}{trend.value}%
              </p>
            )}
          </div>
          {icon && (
            <div className="text-muted-foreground">{icon}</div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
```

---

### 9. Context Provider Pattern (GOLD)

```typescript
// lib/solicitacoes-context.tsx
"use client";

import {
  createContext,
  useContext,
  useMemo,
  useCallback,
  ReactNode
} from "react";
import { useSolicitacoes } from "@/hooks/use-solicitacoes";
import { Solicitacao, SolicitacaoFilter } from "@/types/entities";

interface SolicitacoesContextValue {
  // State
  solicitacoes: Solicitacao[];
  loading: boolean;
  error: Error | null;

  // Actions
  fetch: (filter?: SolicitacaoFilter) => Promise<void>;
  refresh: () => Promise<void>;
  create: (data: Partial<Solicitacao>) => Promise<Solicitacao>;
  update: (id: string, data: Partial<Solicitacao>) => Promise<void>;
  remove: (id: string) => Promise<void>;
}

const SolicitacoesContext = createContext<SolicitacoesContextValue | null>(null);

export function SolicitacoesProvider({ children }: { children: ReactNode }) {
  const {
    data: solicitacoes,
    loading,
    error,
    fetch,
    create,
    update,
    remove,
    refresh
  } = useSolicitacoes();

  // CRITICAL: useMemo para evitar re-renders desnecessários
  const contextValue = useMemo(() => ({
    solicitacoes,
    loading,
    error,
    fetch,
    create,
    update,
    remove,
    refresh
  }), [solicitacoes, loading, error, fetch, create, update, remove, refresh]);

  return (
    <SolicitacoesContext.Provider value={contextValue}>
      {children}
    </SolicitacoesContext.Provider>
  );
}

export function useSolicitacoesContext() {
  const context = useContext(SolicitacoesContext);
  if (!context) {
    throw new Error(
      'useSolicitacoesContext must be used within SolicitacoesProvider'
    );
  }
  return context;
}
```

---

### 10. Database Query Patterns

```typescript
// lib/database/solicitacoes-queries.ts

import { supabaseAdmin } from "@/lib/supabase";
import { SolicitacaoFilter } from "@/types/entities";
import { SolicitacaoDB } from "./solicitacoes-types";

export async function querySolicitacoes(filter: SolicitacaoFilter) {
  let query = supabaseAdmin
    .from('solicitacoes_contrato')
    .select(`
      *,
      produtor:produtores!produtor_id(id, nome, cpf_cnpj),
      produto:produtos!produto_id(id, nome, unidade),
      grupo_familiar:grupos_familiares!grupo_familiar_id(id, nome)
    `, { count: 'exact' });

  // Filters
  if (filter.status?.length) {
    query = query.in('status', filter.status);
  }

  if (filter.grupo_familiar_id) {
    query = query.eq('grupo_familiar_id', filter.grupo_familiar_id);
  }

  if (filter.data_inicio && filter.data_fim) {
    query = query.gte('created_at', filter.data_inicio)
                 .lte('created_at', filter.data_fim);
  }

  // Pagination
  const page = filter.page || 1;
  const limit = Math.min(filter.limit || 20, 100);
  const from = (page - 1) * limit;

  query = query
    .range(from, from + limit - 1)
    .order('created_at', { ascending: false });

  return query;
}

// lib/database/solicitacoes-transformers.ts

import { Solicitacao } from "@/types/entities";
import { SolicitacaoDB } from "./solicitacoes-types";

export function transformFromDatabase(db: SolicitacaoDB): Solicitacao {
  return {
    id: db.id,
    numeroSolicitacao: db.numero_solicitacao,
    status: db.status,
    produtorId: db.produtor_id,
    produtorNome: db.produtor?.nome || '',
    grupoFamiliarId: db.grupo_familiar_id,
    produtoId: db.produto_id,
    produtoNome: db.produto?.nome || '',
    quantidade: db.quantidade,
    unidade: db.unidade,
    precoUnitario: db.preco_unitario,
    moeda: db.moeda,
    createdAt: db.created_at,
    updatedAt: db.updated_at
  };
}

export function transformToDatabase(data: Partial<Solicitacao>): Partial<SolicitacaoDB> {
  const result: Partial<SolicitacaoDB> = {};

  if (data.produtorId !== undefined) result.produtor_id = data.produtorId;
  if (data.grupoFamiliarId !== undefined) result.grupo_familiar_id = data.grupoFamiliarId;
  if (data.produtoId !== undefined) result.produto_id = data.produtoId;
  if (data.quantidade !== undefined) result.quantidade = data.quantidade;
  if (data.precoUnitario !== undefined) result.preco_unitario = data.precoUnitario;
  if (data.moeda !== undefined) result.moeda = data.moeda;
  if (data.status !== undefined) result.status = data.status;

  return result;
}
```

---

## Development Workflow

### STEP 1: Plan (Before Coding)

```
1. IDENTIFY feature requirements
2. DEFINE types in /types/entities.ts or [feature].types.ts
3. DESIGN component hierarchy (page → organisms → molecules)
4. PLAN API routes needed
5. IDENTIFY reusable hooks/services
```

### STEP 2: Types First

```
1. CREATE or UPDATE types in /types/
2. DEFINE all interfaces/types BEFORE implementation
3. ZERO any usage
4. USE Zod schemas for runtime validation
```

### STEP 3: Service Layer

```
1. CREATE [feature]-service.ts in /lib/
2. ENCAPSULATE all business logic
3. HANDLE errors consistently
4. USE transformers for DB ↔ App mapping
```

### STEP 4: API Routes

```
1. CREATE route.ts in /app/api/[feature]/
2. IMPLEMENT GET/POST/PATCH/DELETE
3. VALIDATE with Zod
4. USE service layer for logic
5. RETURN consistent response format
```

### STEP 5: Hooks

```
1. CREATE use-[feature].ts in /hooks/
2. ENCAPSULATE API calls and state
3. RETURN memoized values
4. USE useCallback for functions
```

### STEP 6: Components

```
1. CREATE molecules first (reusable pieces)
2. CREATE organisms (compositions)
3. CREATE page component (Server Component)
4. KEEP under 300 lines
5. USE existing UI components
```

### STEP 7: Test & Validate

```
1. TEST API routes manually
2. VERIFY types are correct
3. CHECK for any usage
4. VALIDATE component renders
5. RUN price-review skill
```

---

## Anti-Patterns to AVOID

### 1. ANY Usage
```typescript
// ❌ PROIBIDO
const data: any = await fetch();
const handler = (x: any) => {};

// ✅ CORRETO
const data: Solicitacao[] = await fetch();
const handler = (x: Solicitacao) => {};
```

### 2. Inline API Calls
```typescript
// ❌ PROIBIDO - fetch no componente
export function Component() {
  useEffect(() => {
    fetch('/api/data').then(r => r.json()).then(setData);
  }, []);
}

// ✅ CORRETO - usar hook
export function Component() {
  const { data, loading } = useSolicitacoes();
}
```

### 3. God Components (>300 lines)
```typescript
// ❌ PROIBIDO - componente com 500+ linhas
// ✅ CORRETO - extrair para molecules/hooks
```

### 4. Duplicate Types
```typescript
// ❌ PROIBIDO - tipos duplicados em vários arquivos
// ✅ CORRETO - usar entities.ts como fonte única
```

### 5. Missing Error Handling
```typescript
// ❌ PROIBIDO
const { data } = await supabase.from('table').select();

// ✅ CORRETO
const { data, error } = await supabase.from('table').select();
if (error) {
  console.error('[Context] Error:', error);
  throw new Error('Failed to fetch');
}
```

### 6. Context Without useMemo
```typescript
// ❌ PROIBIDO
<Context.Provider value={{ state, dispatch }}>

// ✅ CORRETO
const contextValue = useMemo(() => ({ state, dispatch }), [state, dispatch]);
<Context.Provider value={contextValue}>
```

---

## Chain Behavior

Esta skill **ENCADEIA** para `price-review` após completar implementação.

```
price-dev (implementação)
    │
    ▼
price-review (auditoria)
    │
    ├─ PASS → Implementação aprovada ✅
    └─ FAIL → Correções necessárias ❌
```

---

## Common Mistakes

1. ❌ Começar a codar sem definir types
2. ❌ Ignorar padrão de nomenclatura
3. ❌ Criar componentes com mais de 300 linhas
4. ❌ Fazer fetch direto no componente
5. ❌ Não usar service layer
6. ❌ Context sem useMemo
7. ❌ Não validar input com Zod
8. ❌ Não tratar erros de API
9. ❌ Usar any em qualquer lugar
10. ❌ Duplicar types existentes

---

## Quick Reference Commands

```bash
# Verificar any usage
grep -r ": any\|as any" --include="*.ts" --include="*.tsx" app/ components/ hooks/ lib/

# Verificar componentes grandes (>300 linhas)
find . -name "*.tsx" -exec wc -l {} + | sort -rn | head -20

# Verificar imports de types/entities
grep -r "from.*types/entities" --include="*.ts" --include="*.tsx"

# Verificar hooks sem useCallback
grep -rL "useCallback" hooks/

# Verificar Contexts sem useMemo
grep -rL "useMemo" lib/*-context.tsx
```

---

## Related Skills

- **price-review** - Auditoria após desenvolvimento
- **clean-code** - Princípios SOLID
- **testing-strategy** - Estratégia de testes
