---
name: receita-dev
description: Use when developing the Receitas (revenue/income) feature in agrino-web. Activates for "receita", "receitas", "revenue", "income", "financiamento", "pagamento produto".
chain: code-review-agrino
---

# Receita Dev - Desenvolvimento da Feature de Receitas

Skill especializada para desenvolvimento da feature de Receitas no agrino-web. Esta feature será **recriada do zero**, ignorando completamente a implementação existente.

## CONTEXTO CRITICO

A feature de receitas existente foi implementada incorretamente. Estamos reconstruindo seguindo:
1. **Padrões de /pedido** como referência GOLD
2. **Mobile First** como princípio absoluto
3. **Reaproveitamento hardcore** de componentes existentes
4. **Web + Mobile** - funcionar perfeitamente em ambos

## When to Use
- Ao desenvolver qualquer funcionalidade de receitas
- Ao criar telas de listagem, criação, edição de receitas
- Ao implementar filtros de receitas
- Ao trabalhar com KPIs de receitas
- Ao implementar financiamentos ou pagamentos em produto
- NOT when: trabalhando em outras features que não sejam receitas

## API Endpoints (MCP SGI)

### Endpoints de Receita (CRUD)

```
GET    /api/receita/receitas/           # Listar receitas
POST   /api/receita/receitas/           # Criar receita
GET    /api/receita/receitas/{uuid}/    # Obter receita
PUT    /api/receita/receitas/{uuid}/    # Atualizar receita
PATCH  /api/receita/receitas/{uuid}/    # Atualizar parcialmente
DELETE /api/receita/receitas/{uuid}/    # Deletar receita
GET    /api/receita/receitas/kpis/      # KPIs agregados
```

### Endpoints Auxiliares (Somente Leitura)

```
GET /api/receita/categorias-receita/    # Categorias
GET /api/receita/tipos-receita/         # Tipos de receita
GET /api/receita/fontes-cotacao/        # Fontes de cotação
GET /api/receita/tags/                  # Tags (CRUD disponível)
GET /api/receita/financiamentos/        # Financiamentos
GET /api/receita/pagamentos-produto/    # Pagamentos em produto
```

### Filtros Disponíveis (GET /api/receita/receitas/)

```typescript
type ReceitaQueryParams = {
  search?: string;
  page?: number;
  page_size?: number;
  status?: "a_receber" | "recebida" | "cancelada";
  origem?: "contrato" | "Financiamento" | "operacao_financeira" | "outros";
  safra__uuid?: string;
  tipo_receita__uuid?: string;
  categoria_receita__uuid?: string;
  assessorado__grupo_familiar__uuid?: string;
  tags?: string[];                    // AND filter
  tags_or?: string[];                 // OR filter
  data_vencimento__gte?: string;
  data_vencimento__lte?: string;
  data_recebimento__gte?: string;
  data_recebimento__lte?: string;
  ordering?: string;
};
```

### KPIs Endpoint (GET /api/receita/receitas/kpis/)

Aceita os mesmos filtros da listagem. Retorna métricas agregadas.

## Tipos TypeScript (Já existentes em lib/http_clients/sgi/types/receita.ts)

```typescript
// Status possíveis
type ReceitaStatus = "a_receber" | "recebida" | "cancelada";

// Origens possíveis
type ReceitaOrigem = "contrato" | "Financiamento" | "operacao_financeira" | "outros";

// Tipo principal para leitura
type ReceitaRead = {
  uuid: string;
  assessorado: AssessoradoRead;
  fazenda: FazendaRead;
  safra?: SafraRead | null;
  tipo_receita: TipoReceitaRead;
  categoria_receita?: CategoriaReceitaRead | null;
  pagador?: PagadorRead | null;
  moeda: MoedaRead;
  tags?: TagRead[];
  valor: string | number;
  taxa_cambio?: string | number | null;
  valor_brl?: string | number | null;
  data_vencimento: string | null;
  data_recebimento?: string | null;
  status: ApiEnumField<ReceitaStatus>;
  origem: ApiEnumField<ReceitaOrigem>;
  descricao?: string | null;
  observacoes?: string | null;
  financiamento?: FinanciamentoRead | null;
  pagamento_produto?: PagamentoProdutoRead | null;
};

// Tipo para criação
type ReceitaCreate = {
  assessorado: string;      // UUID
  fazenda: string;          // UUID
  safra?: string;           // UUID
  tipo_receita: string;     // UUID
  categoria_receita?: string;
  pagador?: string;
  moeda: string;            // UUID
  tags?: string[];          // Lista de UUIDs
  valor: number;
  taxa_cambio?: number;
  valor_brl?: number;
  data_vencimento: string;  // DD-MM-YYYY
  data_recebimento?: string | null;
  status: ReceitaStatus;
  origem: ReceitaOrigem;
  descricao?: string;
  observacoes?: string;
  financiamento?: FinanciamentoCreate;
  pagamento_produto?: PagamentoProdutoCreate;
};
```

## Estrutura de Pastas OBRIGATÓRIA (Baseada em /pedido)

```
app/(pages)/(authenticated)/receita/
├── (list)/                           # Route group para listagem
│   ├── page.tsx                      # Entry point da lista
│   ├── components/
│   │   ├── receita_cards.tsx         # Cards mobile (ActionListWithProgress)
│   │   ├── receita_table.tsx         # Table desktop
│   │   ├── receita_table_skeleton.tsx
│   │   ├── receita_list.tsx          # Switcher mobile/desktop
│   │   ├── receita_list_empty.tsx
│   │   ├── receita_filters.tsx       # Filtros responsivos
│   │   ├── receita_filters_form.tsx
│   │   ├── topbar_mobile.tsx
│   │   └── kpi_section.tsx           # KPIs no topo
│   ├── context/
│   │   └── receita_listar_context.tsx
│   ├── hooks/
│   │   └── use_receita_listar.ts
│   ├── state/
│   │   └── receita_listar_filter_reducer.ts
│   └── helpers/
│       └── search_select_*.ts
│
├── (write)/                          # Route group para criação/edição
│   ├── criar/
│   │   └── page.tsx
│   ├── editar/
│   │   └── [uuid]/
│   │       └── page.tsx
│   ├── components/
│   │   ├── receita_form.tsx
│   │   ├── financiamento_section.tsx
│   │   ├── pagamento_produto_section.tsx
│   │   ├── tags_selector.tsx
│   │   └── topbar_mobile.tsx
│   └── hooks/
│       └── use_receita_write.ts
│
└── [uuid]/                           # Detalhe da receita
    ├── page.tsx
    ├── components/
    │   ├── receita_header_desktop.tsx
    │   ├── receita_header_mobile.tsx
    │   ├── receita_detail_card.tsx
    │   ├── financiamento_card.tsx
    │   ├── pagamento_produto_card.tsx
    │   └── topbar_mobile.tsx
    └── hooks/
        └── use_receita_detail.ts
```

## Padrões OBRIGATÓRIOS de /pedido

### 1. Context + Reducer Pattern

```typescript
// state/receita_listar_filter_reducer.ts
export interface ReceitaListarState {
  loading: boolean;
  error: string | null;
  filters: ReceitaQueryParams;
  receitas: ReceitaRead[];
}

export type ReceitaListarAction =
  | { type: "START_LOADING" }
  | { type: "SUCCESS_LOADING"; payload: { data: ReceitaRead[]; append: boolean; totalCount: number } }
  | { type: "ERROR_LOADING"; payload: string }
  | { type: "SELECTED_FILTER"; payload: { key: keyof ReceitaQueryParams; value?: any } }
  | { type: "CLEAN_FILTERS"; payload: Partial<ReceitaQueryParams> };
```

### 2. Hook com Mobile/Desktop Strategy

```typescript
// hooks/use_receita_listar.ts
export function useReceitaListar() {
  const { isMobile } = useDevice();

  // Mobile: infinite scroll
  const infiniteScroll = useInfiniteScrollForReducer({
    fetchFn: fetchReceitas,
    enabled: isMobile,
    // ...
  });

  // Desktop: pagination
  const pagination = usePaginateForReducer({
    fetchFn: fetchReceitas,
    enabled: !isMobile,
    // ...
  });

  return { state, dispatch, infiniteScroll, pagination, ... };
}
```

### 3. List Component Responsivo

```typescript
// components/receita_list.tsx
export default function ReceitaList() {
  const { state, pagination } = useReceitaListarContext();
  const { isMobile } = useDevice();

  if (!state.loading && state.receitas.length === 0) return null;

  if (isMobile) {
    return <ReceitaCards />;
  }

  return <ReceitaTable ... />;
}
```

### 4. Cards Mobile com ActionListWithProgress

```typescript
// components/receita_cards.tsx
import ActionListWithProgress from "@/app/ui/components/action_list_with_progress";
import LoadingInfiniteList from "@/app/ui/components/loading_infinite_list";

export default function ReceitaCards() {
  const { state, infiniteScroll } = useReceitaListarContext();

  const receitaItems = useMemo(() => {
    return state.receitas.map(receita => ({
      key: receita.uuid,
      title: receita.tipo_receita.nome,
      subtitle: formatValueByCoin(receita.valor.toString(), receita.moeda),
      icon: getStatusIcon(receita.status.valor),
      // ...
    }));
  }, [state.receitas]);

  return (
    <div className="space-y-3">
      <ActionListWithProgress items={receitaItems} ... />
      <LoadingInfiniteList hasMore={infiniteScroll.hasMore} ... />
    </div>
  );
}
```

## Componentes Compartilhados OBRIGATÓRIOS

**SEMPRE usar antes de criar novos:**

```
app/ui/components/
├── action_list_with_progress.tsx    # Lista mobile com progresso
├── loading_infinite_list.tsx        # Loading para infinite scroll
├── kpi-card.tsx                     # Cards de KPI
├── sheet.tsx                        # Bottom sheets para filtros mobile
├── search-select.tsx                # Selects com busca
├── date-picker.tsx                  # Date picker responsivo
├── checkbox_group.tsx               # Grupos de checkbox
├── table.tsx                        # Table base
├── pagination.tsx                   # Paginação desktop
├── page_header.tsx                  # Header de página desktop
├── confirm_delete_dialog.tsx        # Confirmação de exclusão
├── badge.tsx                        # Badges para status/tags
└── minimizable_filters_card.tsx     # Card de filtros minimizável
```

## Hooks Compartilhados OBRIGATÓRIOS

```
app/ui/hooks/
├── use_infinite_scroll_for_reducer.ts   # Infinite scroll com reducer
├── use_paginate_for_reducer.ts          # Paginação com reducer
├── use_toast.ts                         # Notificações
├── use_debounce.ts                      # Debounce para search
└── use_has_mounted.ts                   # Hydration safety
```

## Contexts Globais (usar para filtros)

```typescript
import { useFiltroGlobal } from "@/app/ui/contexts/filtro_global_context";
import { useDevice } from "@/app/ui/contexts/device_context";

const { selectedGrupoFamiliar, selectedSafra } = useFiltroGlobal();
const { isMobile } = useDevice();
```

## Regras de Qualidade (CLAUDE.md)

1. **Máximo 200 linhas** por arquivo
2. **NUNCA** componentes inline
3. **SEMPRE** verificar se já existe em app/ui/
4. **ZERO `as any`**
5. **useMemo** no value do Provider
6. **useCallback** para callbacks
7. **snake_case** para arquivos
8. Remover código não utilizado

## Checklist de Desenvolvimento

```
[ ] 1. Consultar MCP SGI para entender endpoints
[ ] 2. Verificar componentes existentes em app/ui/components
[ ] 3. Verificar hooks existentes em app/ui/hooks
[ ] 4. Criar estrutura de pastas seguindo /pedido
[ ] 5. Implementar mobile first (cards antes de table)
[ ] 6. Testar responsividade (isMobile toggle)
[ ] 7. Usar reducer pattern para estado complexo
[ ] 8. Integrar com filtro global (safra, grupo familiar)
[ ] 9. Implementar KPIs no topo da listagem
[ ] 10. Validar funcionamento web E mobile
```

## Consultas MCP Recomendadas

```
# Para entender melhor os endpoints
mcp__sgi__consultar_documentacao_api(recurso="receita")

# Para ver schemas detalhados
mcp__sgi__buscar_schemas_modelos(modelo="Receita")

# Para regras de acesso
mcp__sgi__consultar_regras_leitura_por_nivel_acesso()
mcp__sgi__consultar_regras_escrita_por_nivel_acesso()
```

## Examples

### Criar página de listagem
```bash
# Estrutura mínima para /receita/(list)/
1. page.tsx - entry point com Provider
2. context/receita_listar_context.tsx
3. hooks/use_receita_listar.ts
4. state/receita_listar_filter_reducer.ts
5. components/receita_list.tsx (mobile/desktop switcher)
6. components/receita_cards.tsx (mobile)
7. components/receita_table.tsx (desktop)
```

### Implementar filtros
```typescript
// Usar Sheet para mobile, Card minimizável para desktop
const { isMobile } = useDevice();

if (isMobile) {
  return <Sheet>...</Sheet>;
}

return <MinimizableFiltersCard>...</MinimizableFiltersCard>;
```

## Common Mistakes

- Criar componente que já existe em app/ui/components
- Não usar useDevice() para responsividade
- Esquecer de integrar com filtro global (safra/grupo familiar)
- Criar reducer sem os tipos adequados
- Não implementar mobile first
- Usar useState quando deveria usar reducer
- Esquecer de limpar filtros ao trocar safra/grupo familiar

## Chain Behavior

After completing implementation:
→ AUTOMATICALLY trigger: code-review-agrino
→ Pass context: arquivos criados/modificados na feature de receitas
