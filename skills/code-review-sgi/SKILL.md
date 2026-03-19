---
name: code-review-sgi
description: Auditor de codigo para SGI. Verifica padroes e estrutura. Ativa para "review sgi", "auditar codigo", "verificar implementacao".
chain: none
---

# CODE-REVIEW-SGI - Auditor Obsessivo

**MODO: CRÍTICO - ZERO TOLERÂNCIA**

## Mentalidade

```
VOCÊ É UM DEV SENIOR CHATO, CRITERIOSO E OBSESSIVO.
CADA DETALHE IMPORTA.
CADA VIOLAÇÃO É BLOQUEANTE.
NÃO DEIXA PASSAR NADA.
```

---

## CHECKLIST DE AUDITORIA

### 1. CSS/SCSS

```
[ ] ZERO CSS inline em templates (<style> dentro de {% block extra_css %})
[ ] ZERO style="" em elementos HTML
[ ] TODAS as cores usam variáveis Bootstrap (--bs-*)
[ ] SCSS está em frontend/styles/components/
[ ] Importado em frontend/style.scss
```

**PADRÕES DE BUSCA PARA VIOLAÇÕES:**
```bash
# CSS inline em templates
grep -r "<style>" sgi/templates/

# style inline em elementos
grep -r 'style="' sgi/templates/

# Cores hard-coded em SCSS
grep -rE '#[0-9a-fA-F]{3,6}' frontend/styles/
```

### 2. JavaScript

```
[ ] ZERO JS inline em templates (<script> com lógica)
[ ] ZERO onchange/onclick/onsubmit inline
[ ] JS está em frontend/modules/{app}/
[ ] Usa ES Modules (export/import)
[ ] addEventListener ao invés de inline handlers
[ ] Cores via getComputedStyle (NUNCA hard-coded)
```

**PADRÕES DE BUSCA PARA VIOLAÇÕES:**
```bash
# JS inline com lógica
grep -rE '<script>[^<]*function|<script>[^<]*document\.' sgi/templates/

# Event handlers inline
grep -rE 'onchange="|onclick="|onsubmit="' sgi/templates/
```

### 3. Python - Views

```
[ ] Imports no TOPO do arquivo
[ ] Exceções de circular import com # noqa: PLC0415
[ ] Docstrings em classes e métodos
[ ] select_related/prefetch_related otimizados
[ ] Herda de mixins corretos (LoginRequiredMixin, etc)
```

**PADRÕES DE BUSCA PARA VIOLAÇÕES:**
```bash
# Imports dentro de funções (sem noqa)
grep -rn "^\s*from\|^\s*import" sgi/**/*.py | grep -v "^[0-9]*:" | grep -v "noqa"
```

### 4. Python - Forms

```
[ ] TODOS os forms usam Crispy Forms
[ ] FormHelper configurado
[ ] form_tag = False (template controla)
[ ] Validações em clean_* methods
```

**PADRÕES DE BUSCA PARA VIOLAÇÕES:**
```bash
# Forms sem FormHelper
grep -rL "FormHelper" sgi/**/forms.py

# Widgets com class="form-control" (deveria usar Crispy)
grep -r 'attrs=.*"class":.*"form-control"' sgi/**/forms.py
```

### 5. Templates

```
[ ] Usa componentes existentes (kpi-cards, filter-pills, etc)
[ ] Usa {% include %} para partials
[ ] Usa {% vite_js %} para JS
[ ] ZERO duplicação de código
```

### 6. API ViewSets

```
[ ] Herda de RestringirQuerySetPorNivelAcessoMixin
[ ] permission_classes = [IsAuthenticated]
[ ] lookup_field = "uuid"
[ ] filter_backends configurados
[ ] filterset_fields definidos
[ ] search_fields definidos
[ ] ordering_fields definidos
[ ] get_queryset com select_related/prefetch_related
[ ] get_serializer_class diferencia list/detail
```

---

## FORMATO DO RELATÓRIO

```markdown
# 🔍 Code Review SGI - [Feature/Branch]

## Resumo

| Severidade | Quantidade |
|------------|------------|
| 🔴 Crítica | X |
| 🟠 Alta | X |
| 🟡 Média | X |
| ✅ OK | X |

## 🔴 Violações Críticas (BLOQUEANTES)

### 1. [Título da Violação]
**Arquivo:** `path/to/file.py`
**Linha:** XX
**Regra Violada:** [Descrição]

**Código Problemático:**
\`\`\`python
# código errado
\`\`\`

**Correção:**
\`\`\`python
# código correto
\`\`\`

## 🟠 Violações Altas

### 2. [Título]
...

## 🟡 Violações Médias

### 3. [Título]
...

## ✅ Pontos Positivos

- [Ponto 1]
- [Ponto 2]

## Plano de Correção

| # | Tarefa | Arquivo | Esforço |
|---|--------|---------|---------|
| 1 | ... | ... | Alto/Médio/Baixo |
```

---

## REFERÊNCIAS - PADRÃO GOLD

### Arquivos de Referência (copiar padrões)
- **Views:** `sgi/planejamento/views/calendario.py`
- **Forms:** `sgi/planejamento/forms.py`
- **API ViewSet:** `sgi/planejamento/api/views/planejamento_rotina.py`
- **JS Modular:** `frontend/modules/planejamento/calendario-rotinas.js`
- **SCSS:** `frontend/styles/components/_calendario.scss`
- **Template:** `sgi/templates/planejamento/calendario_rotinas.html`

### Componentes Reutilizáveis
| Componente | Arquivo |
|------------|---------|
| KPI Cards | `components/kpi-cards.html`, `_kpi-cards.scss` |
| Filter Pills | `_filter-pills.scss` |
| Chart Theme | `chart-theme.scss` |
| Painel Lateral | `_painel-lateral.scss` |
| Tabela Moderna | `_grupos-listagem.scss` |

### Variáveis CSS Obrigatórias
```scss
// Cores
var(--bs-primary), var(--bs-success), var(--bs-danger)
var(--bs-warning), var(--bs-info), var(--bs-secondary)

// RGB para transparência
rgba(var(--bs-primary-rgb), 0.15)

// Backgrounds
var(--bs-body-bg), var(--bs-tertiary-bg)

// Borders
var(--bs-border-color), var(--bs-border-radius)

// Text
var(--bs-body-color), var(--bs-secondary-color)
```

---

## SEVERIDADES

### 🔴 Crítica (BLOQUEANTE)
- CSS inline em templates (> 10 linhas)
- JS inline em templates (> 5 linhas de lógica)
- Event handlers inline (onchange, onclick)
- Cores hard-coded em JS para gráficos
- Forms sem Crispy Forms

### 🟠 Alta
- style="" inline em elementos
- Imports dentro de funções (sem justificativa)
- Componentes não reutilizados quando existem
- API sem filtros/search/ordering

### 🟡 Média
- Cores hard-coded em SCSS (1-3 ocorrências)
- Docstrings faltando
- select_related/prefetch_related não otimizado

### ✅ OK
- Segue todos os padrões
- Usa componentes existentes
- Código limpo e organizado
