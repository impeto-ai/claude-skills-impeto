---
name: nextjs-architect
description: Use when building or reviewing Next.js App Router projects. Enforces folder architecture, route groups (list)/(write)/[uuid], component hierarchy, colocation, and naming conventions. Activates for "nextjs architecture", "next folder", "route groups", "organizar next", "estrutura next".
chain: none
---

# Next.js Architect

Especialista em arquitetura de projetos Next.js App Router. Pattern principal: **(list)/(write)/[uuid]** — separacao por INTENCAO, nao por URL.

## When to Use

- Criando estrutura de novo projeto Next.js
- Organizando pastas e rotas de projeto existente
- Decidindo onde colocar componentes (local vs compartilhado)
- Nomeando route groups, pastas e arquivos
- Revisando arquitetura de projeto Next.js
- NOT when: styling/CSS (use frontend-design)
- NOT when: API routes logic (use api-design)

---

## 1. CONVENCOES DO NEXT.JS APP ROUTER

### Arquivos Especiais (File Conventions)

```
Arquivo              Funcao
─────────────────────────────────────────────────────
page.tsx             Rota publica (renderiza a pagina)
layout.tsx           Layout compartilhado (persiste entre navegacoes)
loading.tsx          UI de loading (Suspense boundary automatico)
error.tsx            Error boundary (catch de erros no segmento)
not-found.tsx        UI para 404 no segmento
template.tsx         Layout que RE-MONTA a cada navegacao
default.tsx          Fallback para parallel routes
route.ts             API endpoint (GET, POST, PUT, DELETE)
middleware.ts        Middleware (raiz do projeto ou src/)
```

### Convencoes de Pasta

```
Convencao            Significado
─────────────────────────────────────────────────────
(folder)             Route Group — organiza sem afetar URL
[folder]             Segmento dinamico — /users/[id]
[...folder]          Catch-all — /docs/[...slug]
[[...folder]]        Optional catch-all
_folder              Pasta privada — opta OUT do routing
@folder              Parallel route slot
(.)folder            Intercepta rota no mesmo nivel
(..)folder           Intercepta rota um nivel acima
(...)folder          Intercepta rota da raiz
```

---

## 2. ARQUITETURA DE REFERENCIA

### Estrutura Raiz

```
src/
├── app/                          # App Router (ROTAS)
│   ├── layout.tsx                # Root layout
│   ├── page.tsx                  # Homepage /
│   ├── loading.tsx               # Global loading
│   ├── error.tsx                 # Global error
│   ├── not-found.tsx             # Global 404
│   │
│   ├── (pages)/                  # Route Group: todas as paginas
│   │   ├── layout.tsx            # Layout raiz das paginas
│   │   │
│   │   ├── (authenticated)/      # Route Group: requer auth
│   │   │   ├── layout.tsx        # Layout com sidebar/nav
│   │   │   ├── home/
│   │   │   │   └── page.tsx
│   │   │   ├── despesa/          # Feature completa (ver secao 3)
│   │   │   ├── pedido/           # Feature completa
│   │   │   ├── fornecedores/
│   │   │   ├── fazendas/
│   │   │   ├── contratos/
│   │   │   ├── perfil/
│   │   │   └── ...
│   │   │
│   │   ├── login/                # Paginas publicas
│   │   │   └── page.tsx
│   │   ├── register/
│   │   │   └── page.tsx
│   │   └── otp/
│   │       └── page.tsx
│   │
│   ├── api/                      # API Routes
│   │   └── webhooks/
│   │       └── route.ts
│   │
│   └── ui/                       # Shared UI & utilities da app
│       ├── components/           # Componentes reutilizaveis
│       ├── contexts/             # React Contexts globais
│       ├── css/                  # Estilos globais
│       ├── hooks/                # Hooks globais
│       └── layout/               # Componentes de layout
│
├── components/                   # COMPONENTES GLOBAIS (shadcn/ui)
│   └── ui/                       # Primitivos (Button, Input, Card)
│
├── lib/                          # UTILIDADES GLOBAIS
│   └── utils.ts                  # cn() e helpers puros
│
└── types/                        # TIPOS GLOBAIS
    └── index.ts
```

---

## 3. PATTERN PRINCIPAL: (list) / (write) / [uuid]

### Conceito

Cada feature CRUD e organizada por **INTENCAO**, usando route groups que nao afetam a URL:

```
feature/
├── (list)/          → LISTAR    — tudo relacionado a listagem
├── (write)/         → ESCREVER  — tudo relacionado a criacao/edicao
├── [uuid]/          → LER       — tudo relacionado ao detalhe de 1 registro
├── home/            → DASHBOARD — KPIs e visao geral (opcional)
└── importar/        → IMPORTAR  — importacao em massa (opcional)
```

### Exemplo Completo: /despesa

```
app/(pages)/(authenticated)/despesa/
│
├── (list)/                              # ══ LISTAGEM ══
│   ├── page.tsx                         # /despesa (lista)
│   ├── loading.tsx                      # Skeleton da lista
│   ├── _components/                     # UI exclusiva da listagem
│   │   ├── despesa-card.tsx             # Modo card
│   │   ├── despesa-card-skeleton.tsx
│   │   ├── despesa-table.tsx            # Modo tabela
│   │   ├── despesa-table-skeleton.tsx
│   │   ├── despesa-filters.tsx          # Barra de filtros
│   │   ├── despesa-filters-form.tsx     # Form dos filtros
│   │   ├── despesa-list.tsx             # Container da lista
│   │   ├── despesa-list-empty.tsx       # Estado vazio
│   │   ├── despesa-details-sheet.tsx    # Preview lateral
│   │   └── topbar-mobile.tsx
│   ├── _context/                        # Estado da listagem
│   │   └── despesa-listar-context.tsx
│   ├── _hooks/                          # Logica da listagem
│   │   └── use-despesa-listar.ts
│   └── _state/                          # Reducers da listagem
│       └── despesa-listar-filter-reducer.ts
│
├── (write)/                             # ══ ESCRITA ══
│   ├── criar/                           # /despesa/criar
│   │   ├── page.tsx                     # Selecao de modo
│   │   ├── _components/                 # Compartilhado entre modos
│   │   │   ├── progress-indicator.tsx
│   │   │   ├── review-item.tsx
│   │   │   ├── despesa-summary.tsx
│   │   │   └── bottom-action-bar.tsx
│   │   ├── _context/
│   │   │   ├── despesas-context.tsx
│   │   │   └── navigator-context.tsx
│   │   ├── _hooks/
│   │   │   ├── use-despesas.ts
│   │   │   └── use-navigator.ts
│   │   ├── _helpers/
│   │   │   ├── search-select-fazenda.ts
│   │   │   ├── search-select-fornecedores.ts
│   │   │   └── search-select-grupo-despesa.ts
│   │   ├── _state/
│   │   │   ├── despesas-reducer.ts
│   │   │   └── navigator-reducer.ts
│   │   │
│   │   └── (creation-mode)/             # Sub-modos de criacao
│   │       ├── manual/                  # /despesa/criar/manual
│   │       │   ├── page.tsx
│   │       │   ├── _components/
│   │       │   │   ├── despesa-flow-desktop.tsx
│   │       │   │   ├── despesa-flow-mobile.tsx
│   │       │   │   ├── despesa-review-desktop.tsx
│   │       │   │   └── despesa-review-mobile.tsx
│   │       │   └── _config/
│   │       │       ├── steps-desktop.ts
│   │       │       └── steps-mobile.ts
│   │       │
│   │       ├── xml/                     # /despesa/criar/xml
│   │       │   ├── page.tsx
│   │       │   ├── _components/
│   │       │   │   ├── upload-xml.tsx
│   │       │   │   └── xml-processed-info.tsx
│   │       │   └── _context/
│   │       │       └── xml-context.tsx
│   │       │
│   │       ├── clone/                   # /despesa/criar/clone
│   │       │   └── page.tsx
│   │       │
│   │       └── nota-fiscal/             # /despesa/criar/nota-fiscal
│   │           ├── page.tsx
│   │           ├── _components/
│   │           ├── _context/
│   │           └── _config/
│   │
│   ├── editar/                          # /despesa/editar/:uuid
│   │   └── [uuid]/
│   │       ├── page.tsx
│   │       ├── _components/
│   │       │   ├── despesa-form.tsx
│   │       │   └── anexo-item-edit.tsx
│   │       └── _hooks/
│   │           └── use-despesa-editar.ts
│   │
│   ├── _components/                     # Compartilhado entre criar e editar
│   │   ├── parcela-sheet.tsx
│   │   └── value-slider.tsx
│   └── _helpers/                        # Helpers compartilhados do write
│       ├── search-select-fazenda.ts
│       └── search-select-fornecedores.ts
│
├── [uuid]/                              # ══ DETALHE ══
│   ├── page.tsx                         # /despesa/:uuid (leitura)
│   ├── loading.tsx
│   ├── not-found.tsx
│   ├── _components/
│   │   ├── despesa-header-desktop.tsx
│   │   ├── despesa-header-mobile.tsx
│   │   ├── despesa-header-skeleton.tsx
│   │   ├── despesa-header-status-bar.tsx
│   │   ├── parcelas-list.tsx
│   │   ├── parcela-card.tsx
│   │   ├── parcelas-table.tsx
│   │   ├── documentos-list.tsx
│   │   └── topbar-mobile.tsx
│   └── _hooks/
│       ├── use-despesa-status.ts
│       └── use-parcelas-list.ts
│
├── home/                                # ══ DASHBOARD ══ (opcional)
│   ├── page.tsx                         # /despesa/home
│   ├── _components/
│   │   ├── despesa-dashboard-desktop.tsx
│   │   ├── despesa-kpi-cards.tsx
│   │   └── despesa-custo-matriz.tsx
│   └── _hooks/
│       ├── use-despesa-kpis.ts
│       └── use-despesa-matriz.ts
│
└── importar/                            # ══ IMPORTAR ══ (opcional)
    ├── page.tsx                         # /despesa/importar
    ├── _components/
    ├── _context/
    ├── _hooks/
    └── historico/                       # /despesa/importar/historico
        └── page.tsx
```

### Mapeamento URL → Intencao

```
URL                              Intencao      Arquivo
──────────────────────────────────────────────────────────────────
/despesa                         LIST          (list)/page.tsx
/despesa/criar                   CREATE        (write)/criar/page.tsx
/despesa/criar/manual            CREATE MODE   (write)/criar/(creation-mode)/manual/page.tsx
/despesa/criar/xml               CREATE MODE   (write)/criar/(creation-mode)/xml/page.tsx
/despesa/editar/:uuid            UPDATE        (write)/editar/[uuid]/page.tsx
/despesa/:uuid                   READ          [uuid]/page.tsx
/despesa/home                    DASHBOARD     home/page.tsx
/despesa/importar                IMPORT        importar/page.tsx
```

### Exemplo Simples: /pedido (menos rotas)

```
app/(pages)/(authenticated)/pedido/
│
├── (list)/                              # Listagem
│   ├── page.tsx
│   ├── _components/
│   │   ├── pedido-list.tsx
│   │   ├── pedido-table.tsx
│   │   ├── pedido-cards.tsx
│   │   ├── pedido-filters.tsx
│   │   └── pedido-list-empty.tsx
│   ├── _context/
│   │   └── pedido-listar-context.tsx
│   ├── _hooks/
│   │   └── use-pedido-listar.ts
│   └── _state/
│       └── pedido-listar-filter-reducer.ts
│
├── (write)/                             # Escrita
│   ├── criar/
│   │   └── page.tsx
│   ├── editar/
│   │   └── [uuid]/
│   │       ├── page.tsx
│   │       └── _components/
│   │           └── pedido-form.tsx
│   ├── _components/                     # Compartilhado write
│   │   ├── parcela-sheet.tsx
│   │   └── value-slider.tsx
│   ├── _helpers/
│   │   ├── search-select-fazenda.ts
│   │   └── search-select-fornecedores.ts
│   └── _hooks/
│       └── use-pedido-write.ts
│
└── [uuid]/                              # Detalhe
    ├── page.tsx
    ├── _components/
    │   ├── pedido-header-desktop.tsx
    │   ├── pedido-header-mobile.tsx
    │   ├── pedido-item-list.tsx
    │   └── pedido-item-card.tsx
    └── _hooks/
        └── use-pedido-item-form.ts
```

---

## 4. MICRO-MODULO: ANATOMIA DE UM ROUTE GROUP

Cada route group e um **micro-modulo autonomo** com tudo que precisa:

```
(list)/                    ou    (write)/
├── page.tsx               │     ├── criar/page.tsx
├── loading.tsx             │     ├── editar/[uuid]/page.tsx
├── _components/            │     ├── _components/      ← compartilhado write
│   ├── {entidade}-*.tsx   │     ├── _helpers/
│   └── topbar-mobile.tsx  │     ├── _hooks/
├── _context/               │     └── _state/
│   └── {entidade}-*-context.tsx
├── _hooks/
│   └── use-{entidade}-*.ts
├── _state/
│   └── {entidade}-*-reducer.ts
└── _helpers/
    └── search-select-*.ts
```

### Pastas Privadas dentro de Route Groups

```
_components/     → UI exclusiva deste contexto
_context/        → React Context providers
_hooks/          → Custom hooks de logica
_state/          → Reducers e state machines
_helpers/        → Funcoes auxiliares (fetchers, search selects)
_config/         → Configuracoes (steps de wizard, tipos)
_actions/        → Server Actions
_types/          → Tipos locais
```

**TODAS com prefixo `_`** — garante que Next.js nao trata como rota.

---

## 5. HIERARQUIA DE COMPONENTES (Regra de Escopo)

A regra de ouro: **componente vive no nivel mais proximo de onde e usado**.

```
ESCOPO                      LOCAL                                EXEMPLO
────────────────────────────────────────────────────────────────────────────
App inteira                 src/components/ui/                   button.tsx
App inteira                 app/ui/components/                   search-input.tsx
Feature inteira             feature/_components/                 (nao recomendado*)
Contexto inteiro (list)     feature/(list)/_components/          despesa-table.tsx
Contexto inteiro (write)    feature/(write)/_components/         parcela-sheet.tsx
Pagina unica                feature/(write)/criar/_components/   progress-indicator.tsx
Sub-modo unico              ...(creation-mode)/manual/_comps/    despesa-flow-desktop.tsx
```

*No pattern (list)/(write)/[uuid], raramente existe _components/ no nivel da feature — cada route group cuida do seu.

### Fluxo de Decisao

```
Pergunta: "Onde coloco este componente?"

1. E usado em 3+ features DIFERENTES?
   → src/components/ ou app/ui/components/

2. E usado em (list) E (write) da MESMA feature?
   → feature/_components/ (nivel feature, raro)

3. E usado SOMENTE no contexto de listagem?
   → feature/(list)/_components/

4. E usado SOMENTE no contexto de escrita?
   → feature/(write)/_components/

5. E usado SOMENTE em 1 sub-pagina?
   → feature/(write)/criar/_components/

6. E um primitivo puro (Button, Input, Card)?
   → src/components/ui/ (shadcn)
```

### Promocao de Componentes

```
Nivel 1: feature/(list)/_components/status-badge.tsx     (so lista)
Nivel 2: feature/_components/status-badge.tsx             (list + detail)
Nivel 3: app/ui/components/status-badge.tsx               (app inteira)

Passos para promover:
1. Mover arquivo para o nivel acima
2. Atualizar imports
3. Remover logica especifica da feature
4. Garantir props genericas
```

---

## 6. NOMENCLATURA

### Arquivos — kebab-case SEMPRE

```
REGRA: kebab-case para arquivos, PascalCase para exports

Arquivo                       Export
───────────────────────────────────────────
despesa-card.tsx              export function DespesaCard()
despesa-form.tsx              export function DespesaForm()
parcela-sheet.tsx             export function ParcelaSheet()
topbar-mobile.tsx             export function TopbarMobile()
```

### Convencoes por Tipo

```
TIPO                     PADRAO                              EXEMPLO
──────────────────────────────────────────────────────────────────────────
Componente lista         {entidade}-{modo}.tsx                despesa-table.tsx, despesa-card.tsx
Componente detalhe       {entidade}-header-{plat}.tsx         despesa-header-desktop.tsx
Skeleton                 {entidade}-{comp}-skeleton.tsx       despesa-card-skeleton.tsx
Filtros                  {entidade}-filters.tsx               pedido-filters.tsx
Form                     {entidade}-form.tsx                  despesa-form.tsx
Form de filtro           {entidade}-filters-form.tsx          despesa-filters-form.tsx
Estado vazio             {entidade}-list-empty.tsx            pedido-list-empty.tsx
Sheet/Modal              {entidade}-{acao}-sheet.tsx          parcela-sheet.tsx
Topbar mobile            topbar-mobile.tsx                    topbar-mobile.tsx
─────────────────────────────────────────────────────────────────────────
Context                  {entidade}-{contexto}-context.tsx    despesa-listar-context.tsx
Hook                     use-{entidade}-{acao}.ts             use-despesa-listar.ts
Reducer                  {entidade}-{contexto}-reducer.ts     despesa-listar-filter-reducer.ts
Helper                   search-select-{entidade}.ts          search-select-fazenda.ts
                         fetch-checkbox-{campo}.ts            fetch-checkbox-status.ts
Config                   steps-{plataforma}.ts                steps-desktop.ts
                         type-{plataforma}.ts                 type-mobile.ts
Action (Server)          {verbo}-{entidade}.ts                create-despesa.ts
─────────────────────────────────────────────────────────────────────────
```

### Sufixos por Plataforma (Mobile-First)

```
{componente}-desktop.tsx       → So desktop
{componente}-mobile.tsx        → So mobile
{componente}.tsx               → Responsivo (ambos)
```

---

## 7. STATE MANAGEMENT POR ROUTE GROUP

### Pattern: Context + Reducer + Hook

Cada route group gerencia seu proprio estado:

```
(list)/
├── _context/
│   └── despesa-listar-context.tsx    # Provider + tipos
├── _state/
│   └── despesa-listar-filter-reducer.ts  # Reducer puro
└── _hooks/
    └── use-despesa-listar.ts         # Hook que conecta tudo
```

```tsx
// _context/despesa-listar-context.tsx
interface DespesaListarState {
  filters: DespesaFilters
  pagination: Pagination
  viewMode: "card" | "table"
}

const DespesaListarContext = createContext<DespesaListarState>(...)

export function DespesaListarProvider({ children }) {
  const [state, dispatch] = useReducer(reducer, initialState)
  return (
    <DespesaListarContext.Provider value={{ state, dispatch }}>
      {children}
    </DespesaListarContext.Provider>
  )
}

// _hooks/use-despesa-listar.ts
export function useDespesaListar() {
  const { state, dispatch } = useContext(DespesaListarContext)
  // logica de fetch, paginacao, filtros
  return { despesas, isLoading, filters, setFilter, ... }
}

// page.tsx
export default function DespesaListPage() {
  return (
    <DespesaListarProvider>
      <TopbarMobile />
      <DespesaFilters />
      <DespesaList />
    </DespesaListarProvider>
  )
}
```

### Pattern Simplificado: Hook-Only

Para features simples sem estado complexo:

```
(write)/
└── _hooks/
    └── use-pedido-write.ts    # Hook gerencia form state direto
```

### Quando usar cada pattern

```
Context + Reducer + Hook    → Estado complexo, filtros, paginacao, multiplos consumidores
Hook-Only                   → Formulario simples, 1-2 consumidores
Zustand Store               → Estado global entre features (sidebar, tema, user)
```

---

## 8. PAGE.TSX — REGRAS

### page.tsx e um ORQUESTRADOR, nunca um implementador

```tsx
// RUIM: page.tsx com 200 linhas de logica
export default function DespesaListPage() {
  const [filters, setFilters] = useState(...)
  const [despesas, setDespesas] = useState(...)
  // 150 linhas de JSX...
}

// BOM: page.tsx compoe componentes
export default function DespesaListPage() {
  return (
    <DespesaListarProvider>
      <TopbarMobile />
      <div className="bg-muted/50">
        <PageHeader title="Despesas" />
        <DespesaFilters />
        <DespesaList />
      </div>
    </DespesaListarProvider>
  )
}
```

**Regras do page.tsx:**
- Max 30-40 linhas
- Wrapper de Provider(s) + composicao de componentes
- Sem useState/useEffect direto (vai pro hook)
- Sem fetch direto (vai pro hook ou server component)
- Sem JSX complexo (vai pro _components/)

---

## 9. INTERCEPTING ROUTES (Modais)

Pattern para abrir criacao como modal na lista, mas como pagina completa via URL direta:

```
feature/
├── (list)/
│   ├── page.tsx                         # Lista
│   ├── layout.tsx                       # Layout com slot @modal
│   └── @modal/
│       ├── default.tsx                  # return null
│       └── (.)criar/                    # Intercepta /feature/criar
│           └── page.tsx                 # Form dentro de Dialog
├── (write)/
│   └── criar/
│       └── page.tsx                     # Full page (URL direta)
```

```tsx
// (list)/layout.tsx
export default function ListLayout({
  children,
  modal,
}: {
  children: React.ReactNode
  modal: React.ReactNode
}) {
  return (
    <>
      {children}
      {modal}
    </>
  )
}

// (list)/@modal/default.tsx
export default function Default() {
  return null
}

// (list)/@modal/(.)criar/page.tsx
import { Dialog } from "@/components/ui/dialog"
import { DespesaForm } from "../../(write)/criar/_components/despesa-form"

export default function CriarDespesaModal() {
  return (
    <Dialog open>
      <DespesaForm />
    </Dialog>
  )
}
```

---

## 10. ANTI-PATTERNS

### Misturar intencoes no mesmo nivel

```
# RUIM: list e write misturados
feature/
├── page.tsx
├── criar/page.tsx
├── [uuid]/page.tsx
├── _components/        # 30 arquivos misturando list + write + detail
│   ├── table.tsx
│   ├── form.tsx
│   ├── header.tsx
│   └── ...

# BOM: separado por intencao
feature/
├── (list)/             # so listagem
├── (write)/            # so escrita
└── [uuid]/             # so leitura
```

### Componentes globais que sao locais

```
# RUIM: componente de 1 feature no global
src/components/shared/despesa-kpi-cards.tsx  # so /despesa/home usa

# BOM: colocado com a rota
app/.../despesa/home/_components/despesa-kpi-cards.tsx
```

### page.tsx monolitico

```
# RUIM: page.tsx com 200 linhas
# BOM: page.tsx < 40 linhas, orquestrando _components/
```

### Estado compartilhado entre route groups

```
# RUIM: Context de (list) sendo usado em (write)
# BOM: cada route group tem seu proprio estado isolado
```

### Nesting excessivo (>4 niveis de _components)

```
# RUIM
feature/(write)/criar/(creation-mode)/manual/_components/steps/_sub-steps/item.tsx

# BOM: max 1 nivel dentro de _components
feature/(write)/criar/(creation-mode)/manual/_components/step-item.tsx
```

### PascalCase em nomes de arquivo

```
# RUIM
_components/DespesaCard.tsx

# BOM: kebab-case
_components/despesa-card.tsx
```

### Logica no componente em vez de hook

```tsx
// RUIM: fetch e estado dentro do componente
function DespesaList() {
  const [despesas, setDespesas] = useState([])
  const [loading, setLoading] = useState(true)
  useEffect(() => { fetchDespesas()... }, [])
  // ...
}

// BOM: hook isolado
function DespesaList() {
  const { despesas, isLoading } = useDespesaListar()
  if (isLoading) return <DespesaTableSkeleton />
  if (!despesas.length) return <DespesaListEmpty />
  return <DespesaTable data={despesas} />
}
```

---

## 11. CHECKLIST DE ARQUITETURA

```
PATTERN (list)/(write)/[uuid]
[ ] Feature tem (list)/ com page.tsx para listagem
[ ] Feature tem (write)/ com criar/ e editar/[uuid]/
[ ] Feature tem [uuid]/ com page.tsx para detalhe
[ ] Route groups nao afetam URLs
[ ] (list) e (write) sao micro-modulos autonomos

MICRO-MODULO (cada route group)
[ ] _components/ para UI local
[ ] _context/ para providers (se estado complexo)
[ ] _hooks/ para logica de negocio
[ ] _state/ para reducers (se usar reducer)
[ ] _helpers/ para funcoes auxiliares
[ ] Todas pastas com prefixo _

NOMENCLATURA
[ ] Arquivos em kebab-case
[ ] Exports em PascalCase
[ ] Sufixo -desktop/-mobile para platform-specific
[ ] Hooks: use-{entidade}-{acao}.ts
[ ] Contexts: {entidade}-{contexto}-context.tsx
[ ] Reducers: {entidade}-{contexto}-reducer.ts

PAGE.TSX
[ ] Max 30-40 linhas
[ ] So orquestra (Provider + composicao)
[ ] Sem useState/useEffect direto
[ ] Sem JSX complexo

STATE MANAGEMENT
[ ] Cada route group gerencia seu estado
[ ] Context + Reducer para estado complexo
[ ] Hook-only para estado simples
[ ] Sem estado compartilhado entre route groups

COLOCATION
[ ] Componentes vivem no nivel mais proximo de uso
[ ] Sem componente local no global
[ ] Promocao quando necessario (local → feature → global)

ANTI-PATTERNS
[ ] Sem intencoes misturadas no mesmo nivel
[ ] Sem page.tsx monolitico (>40 linhas)
[ ] Sem PascalCase em nomes de arquivo
[ ] Sem nesting > 4 niveis
[ ] Sem logica em componente (usa hook)
[ ] Sem estado compartilhado entre route groups
```

## Output Format

Ao revisar arquitetura de projeto Next.js:

```
## Next.js Architecture Audit

### Score: X/10

### Problemas Encontrados

#### [CRITICAL] Nome do problema
- Local: path/to/file
- Categoria: PATTERN | MICRO_MODULO | NOMENCLATURA | PAGE | STATE | COLOCATION | ANTI_PATTERN
- Problema: descricao
- Correcao: o que fazer

### Recomendacoes
- Mover X para Y
- Renomear A para B
- Criar route group (Z)
```
