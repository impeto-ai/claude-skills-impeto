---
name: sgi-dev
description: Skill para desenvolvimento no SGI. Ativa para trabalho em assessorado, fundiario, planejamento, ofertas, configuracao. EXTREMAMENTE CRITERIOSO.
chain: code-review-sgi
---

# SGI-DEV - Desenvolvimento Production-Ready

**GOLD STANDARD: `/planejamento`** - Use como referência absoluta para qualquer implementação.

## Mentalidade

```
VOCÊ É UM DEV SENIOR OBSESSIVO COM QUALIDADE.
CADA VIOLAÇÃO DOS PADRÕES É INACEITÁVEL.
ZERO TOLERÂNCIA PARA:
- CSS/JS inline em templates
- onchange/onclick inline
- Cores hard-coded
- Imports dentro de funções
- Forms sem Crispy Forms
- Componentes não reutilizados
```

---

## CHECKLIST OBRIGATÓRIO PRÉ-CÓDIGO

Antes de escrever qualquer código, verifique:

```
[ ] Li o arquivo/componente existente completamente
[ ] Identifiquei componentes reutilizáveis existentes
[ ] Conheço o padrão GOLD do /planejamento
[ ] Sei onde colocar CSS (frontend/styles/components/)
[ ] Sei onde colocar JS (frontend/modules/{app}/)
[ ] Vou usar Crispy Forms se for formulário
[ ] Vou usar variáveis CSS Bootstrap (--bs-*)
```

---

## VIOLAÇÕES CRÍTICAS - BLOQUEANTES

### 1. CSS Inline em Templates - PROIBIDO

**ERRADO:**
```html
{% block extra_css %}
  <style>
    .minha-classe { padding: 1rem; }
  </style>
{% endblock %}
```

**CORRETO:**
```scss
// frontend/styles/components/_{app}-{feature}.scss
.minha-classe { padding: 1rem; }
```

```scss
// frontend/style.scss
@import 'components/_{app}-{feature}';
```

### 2. JavaScript Inline em Templates - PROIBIDO

**ERRADO:**
```html
{% block extra_js %}
  <script>
    document.addEventListener('DOMContentLoaded', function() {
      // lógica aqui
    });
  </script>
{% endblock %}
```

**CORRETO:**
```javascript
// frontend/modules/{app}/{feature}.js
export const Feature = {
  init(options = {}) {
    // lógica aqui
  }
};

window.Feature = Feature;
```

```html
{% block extra_js %}
  {% vite_js '{feature}.js' %}
  <script>
    document.addEventListener('DOMContentLoaded', function() {
      Feature.init({ /* apenas config */ });
    });
  </script>
{% endblock %}
```

### 3. Event Handlers Inline - PROIBIDO

**ERRADO:**
```html
<select onchange="this.form.submit()">
```

**CORRETO:**
```html
<select class="filtros-inline__select" name="filtro">
```

```javascript
// Em arquivo JS separado
document.querySelectorAll('.filtros-inline__select').forEach(select => {
  select.addEventListener('change', function() {
    this.form.submit();
  });
});
```

### 4. Cores Hard-coded - PROIBIDO

**ERRADO:**
```scss
.card { background: #fff; border-color: #e9ecef; }
```

```javascript
const colors = ['#0d6efd', '#198754', '#dc3545'];
```

**CORRETO:**
```scss
.card {
  background: var(--bs-body-bg);
  border-color: var(--bs-border-color);
}
```

```javascript
function getCoresBootstrap() {
  const root = document.documentElement;
  const style = getComputedStyle(root);
  return [
    style.getPropertyValue('--bs-primary').trim(),
    style.getPropertyValue('--bs-success').trim(),
    style.getPropertyValue('--bs-danger').trim(),
  ];
}
```

### 5. Imports Dentro de Funções - PROIBIDO (exceto circular imports)

**ERRADO:**
```python
def aplicar_filtros(self, qs):
    from datetime import datetime  # ❌ VIOLAÇÃO
    from datetime import timedelta  # ❌ VIOLAÇÃO
```

**CORRETO:**
```python
# No topo do arquivo
from datetime import datetime
from datetime import timedelta

def aplicar_filtros(self, qs):
    # usar datetime e timedelta
```

**EXCEÇÃO ACEITA (com comentário):**
```python
def get_grupo_filter(self):
    from sgi.assessorado.models import GrupoFamiliar  # noqa: PLC0415 - circular import
```

### 6. Forms Sem Crispy Forms - PROIBIDO

**ERRADO:**
```python
class MeuForm(forms.ModelForm):
    class Meta:
        model = MeuModel
        fields = ["nome"]
        widgets = {
            "nome": forms.TextInput(attrs={"class": "form-control"}),
        }
```

**CORRETO:**
```python
from crispy_forms.helper import FormHelper

class MeuForm(forms.ModelForm):
    class Meta:
        model = MeuModel
        fields = ["nome"]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.helper = FormHelper()
        self.helper.form_method = "post"
        self.helper.form_tag = False
```

### 7. style Inline em Elementos - PROIBIDO

**ERRADO:**
```html
<span style="display: none;"></span>
<div style="left: 12px; top: 50%;">
```

**CORRETO:**
```html
<span class="d-none"></span>
<div class="search-icon">
```

---

## COMPONENTES REUTILIZÁVEIS OBRIGATÓRIOS

### Antes de criar qualquer componente, verifique:

| Necessidade | Componente Existente | Arquivo |
|-------------|---------------------|---------|
| Cards de métricas/KPIs | `{% include 'components/kpi-cards.html' %}` | `_kpi-cards.scss` |
| Filtros por status | `.filter-pills` | `_filter-pills.scss` |
| Cores para gráficos | `chart-theme.scss` | `chart-theme.scss` |
| Sidesheets/offcanvas | `.painel-lateral` | `_painel-lateral.scss` |
| Listagens | `.grupos-listagem` | `_grupos-listagem.scss` |
| Cards base | `.sgi-onboarding-card--static` | `_cards.scss` |
| Tabelas | `{% include 'tabela_moderna.html' %}` | `_grupos-listagem.scss` |

### Uso correto de KPI Cards:

```python
# Na view
context['kpis'] = [
    {
        'titulo': 'Total',
        'valor': 150,
        'icone': 'fas fa-file-contract',
        'cor': 'primary',
    },
]
```

```html
{% include 'components/kpi-cards.html' with kpis=kpis %}
```

---

## ESTRUTURA DE ARQUIVOS PADRÃO

### Views (padrão /planejamento)

```
sgi/{app}/
├── views/
│   ├── __init__.py          # Exports públicos
│   ├── {feature}.py         # Uma view por arquivo
│   └── {feature}_api.py     # API separada se necessário
├── api/
│   ├── views/
│   │   └── {model}.py       # ViewSet por model
│   └── serializers/
│       └── {model}_read.py  # Serializer por model
├── forms.py                  # Todos forms com Crispy
└── templates/{app}/
    └── {feature}.html        # SEM CSS/JS inline
```

### Frontend (padrão /planejamento)

```
frontend/
├── modules/{app}/
│   └── {feature}.js          # JS modular ES6
└── styles/components/
    └── _{feature}.scss       # SCSS componentizado
```

---

## PADRÃO GOLD: Referência /planejamento

### View (calendario.py)
- Herda de mixins corretos (`LoginRequiredMixin`, `FiltrarQuerySetPorNivelAcessoMixin`)
- Métodos bem separados (`get_queryset`, `get_year_month`, `get_context_data`)
- Imports no topo (exceto circular imports com `# noqa: PLC0415`)
- Docstrings em todas as classes e métodos
- select_related/prefetch_related otimizados

### Template (calendario_rotinas.html)
- ZERO CSS inline
- ZERO JS inline (apenas inicialização)
- Usa `{% vite_js 'feature.js' %}`
- Usa componentes existentes (`.filter-pills`, `.sgi-onboarding-card--static`)
- Usa variáveis CSS do Bootstrap

### JavaScript (calendario-rotinas.js)
- ES Module com exports
- Seções bem organizadas (CONFIG, DOM, MODAL, API, etc)
- Event listeners via addEventListener (NUNCA inline)
- Usa variáveis CSS para cores
- `'use strict';` no início

### SCSS (_calendario.scss)
- Usa variáveis Bootstrap (`var(--bs-*)`)
- Segue convenção BEM
- Responsivo mobile-first
- ZERO cores hard-coded

### Forms (forms.py)
- TODOS usam Crispy Forms
- `FormHelper` com `form_tag = False`
- Validações em `clean_*` methods

---

## API ViewSet Padrão

```python
"""ViewSet para {Model}."""

from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters
from rest_framework.permissions import IsAuthenticated
from rest_framework.viewsets import ReadOnlyModelViewSet

from sgi.api.mixins import RestringirQuerySetPorNivelAcessoMixin


class {Model}ViewSet(
    RestringirQuerySetPorNivelAcessoMixin,
    ReadOnlyModelViewSet,
):
    """
    ViewSet ReadOnly para {Model}.

    Endpoints:
    - GET /api/{app}/{models}/          - Listar
    - GET /api/{app}/{models}/{uuid}/   - Detalhar
    """

    # ==================== OBRIGATORIOS ====================
    permission_classes = [IsAuthenticated]
    lookup_field = "uuid"
    lookup_path_grupo_familiar = "..."
    permitir_leitura_grupo_familiar_vazio = False

    # ==================== FILTROS ====================
    filter_backends = [
        DjangoFilterBackend,
        filters.SearchFilter,
        filters.OrderingFilter,
    ]
    filterset_fields = {...}
    search_fields = [...]
    ordering_fields = [...]
    ordering = ["-created_at"]

    # ==================== QUERYSET ====================
    def get_queryset(self):
        return {Model}.objects.select_related(...).prefetch_related(...)

    # ==================== SERIALIZERS ====================
    def get_serializer_class(self):
        if self.action == "list":
            return {Model}ReadSerializer
        return {Model}DetailSerializer
```

---

## VARIÁVEIS CSS DISPONÍVEIS

### Bootstrap (USAR SEMPRE)
```scss
// Cores
var(--bs-primary)
var(--bs-success)
var(--bs-danger)
var(--bs-warning)
var(--bs-info)
var(--bs-secondary)

// RGB para transparência
rgba(var(--bs-primary-rgb), 0.15)

// Backgrounds
var(--bs-body-bg)
var(--bs-tertiary-bg)

// Borders
var(--bs-border-color)
var(--bs-border-radius)

// Text
var(--bs-body-color)
var(--bs-secondary-color)
```

### SGI Custom
```scss
var(--my-card-bg)
var(--my-text-primary)
var(--my-border-color-subtle)
var(--my-icon-color)
```

---

## BEFORE CODING - Perguntas Obrigatórias

1. **Existe componente reutilizável para isso?**
   - Verificar `frontend/styles/components/`
   - Verificar `templates/components/`

2. **Onde vai o CSS?**
   - `frontend/styles/components/_{app}-{feature}.scss`
   - NUNCA no template

3. **Onde vai o JS?**
   - `frontend/modules/{app}/{feature}.js`
   - NUNCA no template (exceto inicialização mínima)

4. **O form usa Crispy Forms?**
   - Se não, refatorar para usar

5. **As cores são variáveis CSS?**
   - Hard-coded = BLOQUEANTE

6. **Os imports estão no topo?**
   - Dentro de função = BLOQUEANTE (exceto circular imports)

---

## AFTER CODING - Checklist de Review

```
[ ] ZERO CSS inline em templates
[ ] ZERO JS inline em templates (exceto init)
[ ] ZERO onchange/onclick inline
[ ] ZERO cores hard-coded
[ ] ZERO imports dentro de funções (exceto circular)
[ ] Forms usam Crispy Forms
[ ] Componentes existentes foram reutilizados
[ ] SCSS usa variáveis Bootstrap
[ ] JS é ES Module com addEventListener
[ ] View tem docstrings
[ ] API tem filtros, search, ordering
[ ] select_related/prefetch_related otimizados
```

---

## CHAIN: code-review-sgi

Após completar desenvolvimento:
→ AUTOMATICAMENTE aciona: `code-review-sgi`
→ Passa contexto: arquivos modificados, feature implementada
→ Review valida TODOS os critérios acima
