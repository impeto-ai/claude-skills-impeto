---
name: price-review
description: Audita implementacoes no Innovagro Price verificando aderencia aos padroes GOLD. Activates for review price, auditar price, verificar padroes price, code review price.
chain: none
code: "#PRVW-3M8K"
---

# Price Review - Auditor de Padrões GOLD

**Codigo da Skill:** `#PRVW-3M8K`

Skill especializada em auditar implementações no projeto Innovagro Price, verificando aderência aos padrões GOLD estabelecidos. Identifica gaps de padronização, type safety, componentização, e qualidade de código.

## When to Use

- Após implementar feature com price-dev
- Antes de criar pull request
- Ao fazer code review de PR
- Quando usuário menciona: "review price", "auditar price", "verificar padrões"
- Para validar aderência aos padrões GOLD
- NOT when: desenvolvimento de features (use price-dev)

---

## Audit Dimensions

```
┌─────────────────────────────────────────────────────────────────┐
│                   PRICE REVIEW DIMENSIONS                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   1. TYPE SAFETY      → Zero any, entities.ts usage            │
│   2. STRUCTURE        → Directory organization, naming          │
│   3. COMPONENTS       → Size limit, atomic design              │
│   4. HOOKS            → useCallback, useMemo, encapsulation    │
│   5. API ROUTES       → Validation, auth, error handling       │
│   6. SERVICES         → Business logic separation              │
│   7. CONTEXTS         → Provider pattern, useMemo              │
│   8. CODE QUALITY     → Clean code, no duplication             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Audit Checklist (GOLD STANDARD)

### 1. TYPE SAFETY (Critical)

**Zero ANY Policy**

```
✅ VERIFICAR:

[ ] Nenhum `: any` no código
[ ] Nenhum `as any` no código
[ ] Nenhum parâmetro implícito any
[ ] Todos os imports de types vêm de entities.ts ou [feature].types.ts
[ ] Props de componentes estão tipadas
[ ] Return types de funções são explícitos
[ ] State está tipado corretamente
[ ] API responses têm tipos definidos
```

**Commands para verificar:**
```bash
# Detectar any
grep -rn ": any\|as any\| any\[" --include="*.ts" --include="*.tsx" [path]

# Verificar parâmetros implícitos
grep -rn "(.*) =>" --include="*.ts" --include="*.tsx" [path] | grep -v ":"
```

**❌ ANTI-PATTERNS:**
```typescript
// ❌ CRÍTICO
const data: any = await fetch();
const handler = (e: any) => {};
const result = value as any;
function process(x) { } // implicit any

// ✅ CORRETO
const data: Solicitacao[] = await fetch();
const handler = (e: React.ChangeEvent<HTMLInputElement>) => {};
const result = value as Solicitacao;
function process(x: Solicitacao) { }
```

**Score Mapping:**
| any count | Score |
|-----------|-------|
| 0 | 10/10 |
| 1-2 | 7/10 |
| 3-5 | 4/10 |
| 6+ | 0/10 |

---

### 2. DIRECTORY STRUCTURE

**Padrão GOLD:**

```
✅ VERIFICAR:

[ ] app/api/[feature]/ para API routes
[ ] components/[feature]/ para componentes da feature
[ ] components/molecules/ para componentes reutilizáveis
[ ] components/organisms/ para composições complexas
[ ] hooks/use-[feature].ts para hooks customizados
[ ] lib/[feature]-service.ts para lógica de negócio
[ ] lib/database/[feature]-queries.ts para queries DB
[ ] types/[feature].types.ts ou entities.ts para tipos
```

**❌ ANTI-PATTERNS:**
```
❌ Componentes na raiz de components/
❌ Hooks dentro de components/
❌ Services dentro de app/
❌ Types espalhados em múltiplos arquivos duplicados
```

**Score Mapping:**
| Conformidade | Score |
|--------------|-------|
| 100% | 10/10 |
| 75-99% | 7/10 |
| 50-74% | 4/10 |
| <50% | 0/10 |

---

### 3. NAMING CONVENTIONS

**Padrão GOLD:**

```
✅ VERIFICAR:

Files:
[ ] Componentes: kebab-case.tsx (solicitacao-card.tsx)
[ ] Hooks: use-kebab-case.ts (use-solicitacoes.ts)
[ ] Services: kebab-case-service.ts (contratos-service.ts)
[ ] Types: kebab-case.types.ts (comercializacao.types.ts)
[ ] API routes: route.ts em pastas kebab-case

Code:
[ ] Componentes: PascalCase (SolicitacaoCard)
[ ] Variáveis: camelCase (grupoFamiliarId)
[ ] Constantes: UPPER_SNAKE_CASE (MAX_PAGE_SIZE)
[ ] DB fields: snake_case (grupo_familiar_id)
```

**Commands para verificar:**
```bash
# Arquivos em CamelCase (ERRADO)
find [path] -name "*[A-Z]*.tsx" -o -name "*[A-Z]*.ts"

# Hooks sem prefixo use-
find [path]/hooks -name "*.ts" | grep -v "use-"
```

**❌ ANTI-PATTERNS:**
```
❌ SolicitacaoCard.tsx (deve ser solicitacao-card.tsx)
❌ useSolicitacoes.ts (deve ser use-solicitacoes.ts)
❌ ContratosService.ts (deve ser contratos-service.ts)
```

---

### 4. COMPONENT PATTERNS

**Size Limit: MAX 300 LINES**

```
✅ VERIFICAR:

[ ] Nenhum componente com mais de 300 linhas
[ ] Lógica extraída para hooks customizados
[ ] Componentes reutilizáveis em molecules/
[ ] Composições complexas em organisms/
[ ] Props tipadas com interface
[ ] Server Components por padrão (sem "use client" desnecessário)
```

**Commands para verificar:**
```bash
# Componentes grandes
find [path] -name "*.tsx" -exec wc -l {} + | sort -rn | head -20

# Verificar "use client" desnecessário
grep -l "use client" [path]/**/*.tsx
```

**God Component Detection:**
| Lines | Status |
|-------|--------|
| < 150 | ✅ Excelente |
| 150-300 | ⚠️ Aceitável |
| 300-500 | ❌ Refatorar |
| 500+ | 🔴 Crítico |

**❌ ANTI-PATTERNS:**
```typescript
// ❌ CRÍTICO - Componente com 500+ linhas
// ❌ Lógica de negócio no componente
// ❌ Múltiplas responsabilidades
// ❌ Props sem tipos
```

---

### 5. HOOK PATTERNS

**Padrão GOLD:**

```
✅ VERIFICAR:

[ ] useCallback para todas as funções passadas como props
[ ] useMemo para valores derivados complexos
[ ] useReducer para estado complexo (3+ campos relacionados)
[ ] Retorno memoizado com useMemo
[ ] Nenhum fetch direto no componente (usar hook)
[ ] Error handling consistente
[ ] Loading states
```

**Commands para verificar:**
```bash
# Hooks sem useCallback
grep -rL "useCallback" hooks/

# Hooks sem useMemo no retorno
grep -rL "return useMemo" hooks/

# Fetch direto em componentes
grep -rn "fetch\|axios" components/ --include="*.tsx"
```

**❌ ANTI-PATTERNS:**
```typescript
// ❌ Função não memoizada
const handleClick = () => {};

// ✅ CORRETO
const handleClick = useCallback(() => {}, [deps]);

// ❌ Retorno não memoizado
return { data, loading, fetch };

// ✅ CORRETO
return useMemo(() => ({ data, loading, fetch }), [data, loading, fetch]);
```

---

### 6. API ROUTE PATTERNS

**Padrão GOLD:**

```
✅ VERIFICAR:

[ ] Zod schema para validação de input
[ ] Autenticação verificada (getUserFromRequest)
[ ] Autorização verificada (roles/permissions)
[ ] Error handling com try/catch
[ ] Response format consistente { data } ou { error }
[ ] Logging de erros
[ ] Status codes corretos (200, 201, 400, 401, 500)
```

**Estrutura obrigatória:**
```typescript
// 1. Imports
// 2. Validation schemas (Zod)
// 3. GET handler
// 4. POST handler
// 5. PATCH handler (se aplicável)
// 6. DELETE handler (se aplicável)
```

**❌ ANTI-PATTERNS:**
```typescript
// ❌ Sem validação
const body = await request.json();

// ✅ CORRETO
const result = schema.safeParse(await request.json());
if (!result.success) return NextResponse.json({ error: ... }, { status: 400 });

// ❌ Sem autenticação
export async function GET(request: NextRequest) {
  const { data } = await supabase.from('table').select();
}

// ✅ CORRETO
export async function GET(request: NextRequest) {
  const user = await getUserFromRequest(request);
  if (!user) return NextResponse.json({ error: ... }, { status: 401 });
}

// ❌ Sem error handling
const { data } = await supabase.from('table').select();
return NextResponse.json({ data });

// ✅ CORRETO
try {
  const { data, error } = await supabase.from('table').select();
  if (error) throw error;
  return NextResponse.json({ data });
} catch (err) {
  console.error('[API] Error:', err);
  return NextResponse.json({ error: ... }, { status: 500 });
}
```

---

### 7. SERVICE LAYER

**Padrão GOLD:**

```
✅ VERIFICAR:

[ ] Toda lógica de negócio em [feature]-service.ts
[ ] Service encapsula operações DB
[ ] Service usa transformers para conversão DB ↔ App
[ ] Service retorna { data, error } consistente
[ ] Service não faz logging de dados sensíveis
[ ] Service é singleton ou class stateless
```

**Estrutura obrigatória:**
```typescript
// lib/[feature]-service.ts
class FeatureService {
  async list(filter: Filter): Promise<ServiceResult<Item[]>> {}
  async getById(id: string): Promise<ServiceResult<Item>> {}
  async create(data: CreateInput): Promise<ServiceResult<Item>> {}
  async update(id: string, data: UpdateInput): Promise<ServiceResult<Item>> {}
  async delete(id: string): Promise<ServiceResult<void>> {}
}

export const featureService = new FeatureService();
```

**❌ ANTI-PATTERNS:**
```typescript
// ❌ Lógica de negócio no componente
// ❌ Lógica de negócio no API route
// ❌ Service acoplado a componentes
// ❌ Service sem error handling
```

---

### 8. CONTEXT PATTERNS

**Padrão GOLD:**

```
✅ VERIFICAR:

[ ] Provider wrapper com useMemo no value
[ ] Hook consumidor com throw se fora do Provider
[ ] Context value tipado
[ ] Não criar Context para estado local (1-2 componentes)
[ ] Context em lib/[feature]-context.tsx
```

**❌ ANTI-PATTERNS:**
```typescript
// ❌ CRÍTICO - Sem useMemo (causa re-renders)
return (
  <Context.Provider value={{ state, dispatch }}>
    {children}
  </Context.Provider>
);

// ✅ CORRETO
const contextValue = useMemo(
  () => ({ state, dispatch }),
  [state, dispatch]
);
return (
  <Context.Provider value={contextValue}>
    {children}
  </Context.Provider>
);

// ❌ Hook consumidor sem verificação
export function useFeature() {
  return useContext(FeatureContext); // pode retornar null
}

// ✅ CORRETO
export function useFeature() {
  const context = useContext(FeatureContext);
  if (!context) {
    throw new Error('useFeature must be used within FeatureProvider');
  }
  return context;
}
```

---

### 9. CODE QUALITY

**Padrão GOLD:**

```
✅ VERIFICAR:

[ ] Sem código duplicado
[ ] Sem console.log (apenas console.error para erros)
[ ] Imports organizados (react, next, libs, local)
[ ] Funções com responsabilidade única
[ ] Nomes descritivos (variáveis, funções, componentes)
[ ] Comentários apenas onde necessário (código deve ser auto-explicativo)
[ ] Sem magic numbers/strings (usar constantes)
[ ] Sem nested ternaries complexos
```

**Commands para verificar:**
```bash
# console.log (remover)
grep -rn "console.log" --include="*.ts" --include="*.tsx" [path]

# Magic numbers
grep -rn "[0-9]\{3,\}" --include="*.ts" --include="*.tsx" [path]

# Código duplicado (manual review)
```

**❌ ANTI-PATTERNS:**
```typescript
// ❌ Magic number
if (items.length > 20) { }

// ✅ CORRETO
const MAX_ITEMS_PER_PAGE = 20;
if (items.length > MAX_ITEMS_PER_PAGE) { }

// ❌ Nested ternary
const result = a ? (b ? x : y) : (c ? w : z);

// ✅ CORRETO
const getResult = () => {
  if (a && b) return x;
  if (a) return y;
  if (c) return w;
  return z;
};

// ❌ console.log deixado no código
console.log('debug', data);

// ✅ CORRETO (apenas para erros)
console.error('[Service] Error:', error);
```

---

## Audit Report Template

```markdown
## 🔍 PRICE REVIEW: [Feature/Component Name]

⚡ SKILL_ACTIVATED: #PRVW-3M8K

**Feature Auditada:** /[path]
**Data:** [timestamp]
**Padrão:** GOLD STANDARD Price

---

### 📊 RESUMO EXECUTIVO

| Dimensão | Status | Score |
|----------|--------|-------|
| Type Safety | ✅ PASS / ⚠️ WARN / ❌ FAIL | X/10 |
| Structure | ✅ PASS / ⚠️ WARN / ❌ FAIL | X/10 |
| Naming | ✅ PASS / ⚠️ WARN / ❌ FAIL | X/10 |
| Components | ✅ PASS / ⚠️ WARN / ❌ FAIL | X/10 |
| Hooks | ✅ PASS / ⚠️ WARN / ❌ FAIL | X/10 |
| API Routes | ✅ PASS / ⚠️ WARN / ❌ FAIL | X/10 |
| Services | ✅ PASS / ⚠️ WARN / ❌ FAIL | X/10 |
| Contexts | ✅ PASS / ⚠️ WARN / ❌ FAIL | X/10 |
| Code Quality | ✅ PASS / ⚠️ WARN / ❌ FAIL | X/10 |

**SCORE GERAL:** X/90 (XX%)

**VEREDITO:** ✅ APROVADO / ⚠️ PRECISA MELHORIAS / ❌ REPROVADO

---

### ❌ ISSUES CRÍTICOS (Bloqueiam merge)

**[TYPE SAFETY] `any` detectado**
- **Localização:** `components/feature/component.tsx:45`
- **Código:** `const data: any = await fetch();`
- **Ação Requerida:**
  ```typescript
  // Trocar por:
  const data: Solicitacao[] = await fetch();
  ```
- **Severidade:** 🔴 CRÍTICO

**[COMPONENT] God Component (>300 linhas)**
- **Localização:** `components/feature/form.tsx (487 linhas)`
- **Problema:** Componente viola limite de 300 linhas
- **Ação Requerida:**
  ```
  1. Extrair lógica para hooks/use-feature-form.ts
  2. Extrair seções para molecules/
  3. Manter componente principal < 300 linhas
  ```
- **Severidade:** 🔴 CRÍTICO

---

### ⚠️ WARNINGS (Corrigir em breve)

**[HOOKS] Função não memoizada**
- **Localização:** `hooks/use-feature.ts:23`
- **Código:** `const handleSubmit = () => {};`
- **Ação Requerida:**
  ```typescript
  const handleSubmit = useCallback(() => {}, [deps]);
  ```
- **Severidade:** 🟡 MÉDIO

**[NAMING] Arquivo em CamelCase**
- **Localização:** `components/feature/FeatureCard.tsx`
- **Ação Requerida:** Renomear para `feature-card.tsx`
- **Severidade:** 🟡 MÉDIO

---

### ✅ PONTOS POSITIVOS

- ✅ Usa entities.ts para tipos
- ✅ Service layer implementado
- ✅ API routes com validação Zod
- ✅ Context com useMemo
- ✅ Error handling consistente

---

### 🎯 AÇÕES REQUERIDAS (Prioritizado)

**CRÍTICO** (bloqueiam merge):
1. [ ] Remover todos os `any` (3 ocorrências)
2. [ ] Refatorar god component form.tsx
3. [ ] Adicionar autenticação em GET /api/feature

**MÉDIO** (corrigir em breve):
1. [ ] Adicionar useCallback em handleSubmit
2. [ ] Renomear arquivos CamelCase
3. [ ] Adicionar useMemo no retorno do hook

**BAIXO** (melhoria futura):
1. [ ] Remover console.log (2 ocorrências)
2. [ ] Extrair magic numbers para constantes
3. [ ] Melhorar nomes de variáveis

---

### 📝 COMPARAÇÃO COM GOLD STANDARD

| Aspecto | GOLD | Implementado | Gap |
|---------|------|--------------|-----|
| Zero any | ✅ | ❌ 3 any | 🔴 |
| < 300 linhas | ✅ | ❌ 487 linhas | 🔴 |
| useCallback | ✅ | ⚠️ Parcial | 🟡 |
| Naming kebab | ✅ | ⚠️ Mix | 🟡 |
| Zod validation | ✅ | ✅ | ✅ |
| Service layer | ✅ | ✅ | ✅ |
| Context useMemo | ✅ | ✅ | ✅ |

---

### 🔗 PRÓXIMOS PASSOS

1. Corrigir issues CRÍTICOS
2. Criar PR com fixes
3. Re-executar price-review
4. Merge apenas se score > 80%
```

---

## Severity Levels

| Level | Icon | Descrição | Ação |
|-------|------|-----------|------|
| CRÍTICO | 🔴 | Viola padrões fundamentais, segurança | Bloqueia merge |
| MÉDIO | 🟡 | Gap de padronização | Corrigir em breve |
| BAIXO | 🔵 | Melhoria recomendada | Opcional |

---

## Score Thresholds

| Score | Veredito | Ação |
|-------|----------|------|
| 90-100% | ✅ APROVADO | Pode fazer merge |
| 70-89% | ⚠️ PRECISA MELHORIAS | Corrigir críticos antes do merge |
| <70% | ❌ REPROVADO | Refatoração necessária |

---

## Audit Workflow

```
1. RECEIVE request de audit
      │
2. IDENTIFY scope (feature/component/PR)
      │
3. EXECUTE audit commands
      │  ├─ grep para any
      │  ├─ wc -l para size
      │  ├─ find para naming
      │  └─ grep para patterns
      │
4. READ código relevante
      │  ├─ Componentes
      │  ├─ Hooks
      │  ├─ Services
      │  ├─ API routes
      │  └─ Types
      │
5. EVALUATE cada dimensão (1-9)
      │
6. CALCULATE score
      │
7. GENERATE report com:
      │  ├─ Issues críticos
      │  ├─ Warnings
      │  ├─ Pontos positivos
      │  ├─ Ações requeridas
      │  └─ Comparação GOLD
      │
8. OUTPUT report + veredito
```

---

## Quick Audit Commands

```bash
# 1. Detectar any
grep -rn ": any\|as any\| any\[" --include="*.ts" --include="*.tsx" [path]

# 2. Componentes grandes (>300 linhas)
find [path] -name "*.tsx" -exec wc -l {} + | sort -rn | head -20

# 3. Arquivos CamelCase (naming violation)
find [path] -name "*[A-Z]*.tsx" -o -name "*[A-Z]*.ts" | grep -v node_modules

# 4. Hooks sem useCallback
grep -rL "useCallback" [path]/hooks/

# 5. Context sem useMemo
grep -L "useMemo" [path]/lib/*-context.tsx 2>/dev/null

# 6. console.log (remover)
grep -rn "console.log" --include="*.ts" --include="*.tsx" [path]

# 7. fetch direto em componentes
grep -rn "fetch\(" --include="*.tsx" [path]/components/

# 8. API routes sem validação
grep -rL "safeParse\|parse" [path]/app/api/**/route.ts

# 9. API routes sem autenticação
grep -rL "getUserFromRequest\|getUser" [path]/app/api/**/route.ts

# 10. Imports de entities.ts
grep -rc "from.*types/entities" --include="*.ts" --include="*.tsx" [path]
```

---

## Common Anti-Patterns to Detect

### Anti-Pattern 1: Any Usage
```typescript
// ❌ DETECTAR
const data: any = ...
function handler(x: any) { }
value as any
```

### Anti-Pattern 2: God Component
```typescript
// ❌ DETECTAR: Arquivo com 300+ linhas
// Sinais:
// - Múltiplos useState/useEffect
// - Múltiplas funções handler
// - JSX extenso (100+ linhas de render)
```

### Anti-Pattern 3: Fetch no Componente
```typescript
// ❌ DETECTAR
useEffect(() => {
  fetch('/api/data')
    .then(r => r.json())
    .then(setData);
}, []);
```

### Anti-Pattern 4: Context sem useMemo
```typescript
// ❌ DETECTAR
<Context.Provider value={{ state, dispatch }}>
```

### Anti-Pattern 5: Hook sem useCallback
```typescript
// ❌ DETECTAR
export function useFeature() {
  const handleAction = () => { }; // não memoizado
  return { handleAction };
}
```

### Anti-Pattern 6: API sem Validação
```typescript
// ❌ DETECTAR
export async function POST(request: NextRequest) {
  const body = await request.json(); // sem validação Zod
}
```

### Anti-Pattern 7: API sem Auth
```typescript
// ❌ DETECTAR
export async function GET(request: NextRequest) {
  // sem verificação de autenticação
  const { data } = await supabase.from('table').select();
}
```

### Anti-Pattern 8: Naming Incorreto
```typescript
// ❌ DETECTAR
// Arquivos: PedidoCard.tsx, usePedidos.ts
// Deveria: pedido-card.tsx, use-pedidos.ts
```

---

## Chain Behavior

Esta skill **NÃO** encadeia automaticamente.

**Fluxo típico:**
```
price-dev (implementação)
    │
    ▼
price-review (auditoria) ← VOCÊ ESTÁ AQUI
    │
    ├─ PASS (>80%) → Pode fazer merge ✅
    │
    └─ FAIL (<80%) → Correções necessárias
                          │
                          ▼
                     price-dev (correções)
                          │
                          ▼
                     price-review (re-audit)
```

---

## Related Skills

- **price-dev** - Desenvolvimento seguindo padrões GOLD
- **clean-code** - Princípios SOLID e clean code
- **code-reviewer** - Code review técnico genérico

---

## Common Mistakes (Auditor)

1. ❌ Não executar todos os comandos de verificação
2. ❌ Não ler código, apenas confiar em grep
3. ❌ Não priorizar issues (crítico vs warning)
4. ❌ Report genérico sem exemplos de correção
5. ❌ Não comparar com GOLD standard
6. ❌ Não dar score numérico
7. ❌ Aprovar código com any (NUNCA aprovar)
8. ❌ Aprovar god components (>300 linhas)
9. ❌ Não verificar autenticação em APIs
10. ❌ Não sugerir próximos passos

---

## Instructions

**Ao receber solicitação de audit:**

### FASE 1: PREPARAÇÃO
```
1. IDENTIFY scope do audit (feature, component, PR, full codebase)
2. EXECUTE comandos de verificação
3. COLLECT metrics (any count, line counts, pattern matches)
```

### FASE 2: ANÁLISE
```
1. READ código relevante (componentes, hooks, services, APIs)
2. EVALUATE cada dimensão (1-9)
3. IDENTIFY issues críticos, warnings, positivos
4. CALCULATE scores por dimensão
```

### FASE 3: REPORT
```
1. GENERATE report estruturado
2. PRIORITIZE ações (crítico → médio → baixo)
3. INCLUDE exemplos de correção
4. CALCULATE score geral
5. EMIT veredito (APROVADO/PRECISA MELHORIAS/REPROVADO)
```

---

## Examples

### Example 1: Audit Completo de Feature

**Input:** "review price solicitacoes"

**Execução:**
```bash
# Comandos executados
grep -rn ": any" app/ components/solicitacoes/ hooks/use-solicitacoes.ts
find components/solicitacoes/ -name "*.tsx" -exec wc -l {} +
grep -rL "useCallback" hooks/use-solicitacoes.ts
grep -L "useMemo" lib/solicitacoes-context.tsx
```

**Output:**
```
🔍 PRICE REVIEW: Solicitações

⚡ SKILL_ACTIVATED: #PRVW-3M8K

📊 RESUMO EXECUTIVO

| Dimensão | Status | Score |
|----------|--------|-------|
| Type Safety | ✅ PASS | 10/10 |
| Structure | ✅ PASS | 9/10 |
| Naming | ✅ PASS | 10/10 |
| Components | ⚠️ WARN | 7/10 |
| Hooks | ✅ PASS | 9/10 |
| API Routes | ✅ PASS | 10/10 |
| Services | ✅ PASS | 10/10 |
| Contexts | ✅ PASS | 10/10 |
| Code Quality | ⚠️ WARN | 8/10 |

SCORE GERAL: 83/90 (92%)

VEREDITO: ✅ APROVADO

---

⚠️ WARNINGS

[COMPONENTS] Componente próximo do limite
- Localização: components/solicitacoes/solicitacao-form.tsx (280 linhas)
- Problema: Próximo do limite de 300 linhas
- Ação: Considerar extrair seções para molecules/

[CODE QUALITY] console.log encontrado
- Localização: hooks/use-solicitacoes.ts:45
- Ação: Remover ou trocar por console.error

---

✅ PONTOS POSITIVOS

- ✅ Zero any no código
- ✅ Naming 100% kebab-case
- ✅ Service layer bem estruturado
- ✅ API routes com Zod + Auth
- ✅ Context com useMemo
- ✅ Hooks com useCallback
- ✅ Types centralizados em entities.ts

---

🎯 AÇÕES RECOMENDADAS

BAIXO:
1. [ ] Remover console.log em use-solicitacoes.ts:45
2. [ ] Considerar split de solicitacao-form.tsx em futuras iterações

---

🔗 PRÓXIMOS PASSOS

1. Código aprovado para merge
2. Considerar refatoração preventiva do form
```

---

### Example 2: Audit com Falhas

**Input:** "review price nova-feature"

**Output:**
```
🔍 PRICE REVIEW: Nova Feature

⚡ SKILL_ACTIVATED: #PRVW-3M8K

📊 RESUMO EXECUTIVO

| Dimensão | Status | Score |
|----------|--------|-------|
| Type Safety | ❌ FAIL | 2/10 |
| Structure | ⚠️ WARN | 6/10 |
| Naming | ❌ FAIL | 4/10 |
| Components | ❌ FAIL | 3/10 |
| Hooks | ⚠️ WARN | 5/10 |
| API Routes | ❌ FAIL | 4/10 |
| Services | ⚠️ WARN | 6/10 |
| Contexts | ✅ PASS | 9/10 |
| Code Quality | ⚠️ WARN | 6/10 |

SCORE GERAL: 45/90 (50%)

VEREDITO: ❌ REPROVADO - Refatoração necessária

---

❌ ISSUES CRÍTICOS

[TYPE SAFETY] 8 ocorrências de `any`
- Localizações:
  - components/nova-feature/Form.tsx:23, 45, 78
  - hooks/useNovaFeature.ts:12, 34
  - lib/nova-feature-service.ts:56, 89, 112
- Ação: Substituir todos por tipos específicos

[COMPONENTS] God Component detectado
- Localização: components/nova-feature/Form.tsx (623 linhas)
- Ação: Refatorar urgentemente

[API ROUTES] Sem autenticação
- Localização: app/api/nova-feature/route.ts
- Ação: Adicionar getUserFromRequest

[NAMING] Arquivos em CamelCase
- Form.tsx, Card.tsx, useNovaFeature.ts
- Ação: Renomear para kebab-case

---

⚠️ WARNINGS

[API ROUTES] Sem validação Zod
[HOOKS] Sem useCallback
[SERVICES] Sem error handling

---

🎯 AÇÕES REQUERIDAS (BLOQUEIAM MERGE)

1. [ ] Remover todos os `any` (8 ocorrências)
2. [ ] Refatorar Form.tsx (623 → <300 linhas)
3. [ ] Adicionar autenticação em API routes
4. [ ] Renomear arquivos para kebab-case
5. [ ] Adicionar validação Zod
6. [ ] Adicionar useCallback nos hooks
```
