---
name: sgi-access-control
description: Use when implementing access control, permissions, or multi-tenant filtering in SGI. Activates for "nivel acesso", "filtrar carteira", "permissao", "mixin acesso", "controle acesso".
chain: none
---

# SGI Access Control Implementation Guide

Sistema infalivel para implementar controle de acessos multi-tenant no SGI.

## When to Use

- Criando views que listam dados filtrados por nivel de acesso
- Implementando acesso a registros individuais (get_object)
- Validando se usuario pode acessar/criar/editar dados de uma carteira/cliente
- Criando APIs REST com filtro de acesso
- Adicionando controle de acesso a modulos existentes (ofertas, pedidos, etc)

**NOT when:**
- Autenticacao basica (login/logout) - use Django auth
- Permissoes funcionais simples (pode ver tela X) - use PermissionRequiredMixin

---

## Architecture Overview

```
HIERARQUIA DE NIVEIS (peso numerico):
┌─────────────────────────────────────────────────────────┐
│  GERAL (4)      → Acesso total, sem filtro              │
│  ESTADUAL (3)   → Filtra por colaborador.estados        │
│  FILIAL (2)     → Filtra por colaborador.filiais        │
│  REGIONAL (2)   → Filtra por colaborador.regioes        │
│  CARTEIRA (1)   → Filtra por colaborador.carteiras      │
└─────────────────────────────────────────────────────────┘

MODELO ORGANIZACIONAL:
Estado ← Filial ← FilialRegiao ← Carteira ← GrupoFamiliar
                                    ↑
                              Colaborador
                           (cargo.nivel_acesso)
```

---

## Core Components

### 1. NivelAcessoPermission (Fonte da Verdade)

**Localizacao:** `sgi/base/permissions/nivel_acesso.py`

```python
from sgi.base.permissions import NivelAcessoPermission

# Verificar tipo de usuario
NivelAcessoPermission.is_colaborador(user)      # True/False
NivelAcessoPermission.is_assessorado(user)      # True/False

# Obter nivel do usuario
NivelAcessoPermission.obter_nivel_usuario(user)  # "carteira", "filial", etc.

# Verificar se tem nivel minimo
NivelAcessoPermission.usuario_tem_acesso(user, "estadual")  # True/False

# FILTRAR QUERYSET (para listagens)
NivelAcessoPermission.filtrar_queryset_por_nivel_acesso(
    user=user,
    queryset=Model.objects.all(),
    lookup_carteira="carteira"  # caminho ate Carteira no model
)

# VERIFICAR ACESSO INDIVIDUAL (para registro unico)
NivelAcessoPermission.verificar_acesso_grupo_familiar(user, grupo_familiar)
```

### 2. Mixins para Class-Based Views

**Localizacao:** `sgi/base/mixins/nivel_acesso.py`

```python
from sgi.base.mixins import (
    FiltrarQuerySetPorNivelAcessoMixin,    # Filtra listagens
    NivelAcessoRequiredMixin,               # Exige nivel minimo
    VerificarAcessoGrupoFamiliarMixin,      # Valida acesso a GF via URL
    AcessoCompletoListagemMixin,            # Permissao + Filtro
    AcessoCompletoGrupoFamiliarMixin,       # Permissao + Acesso GF
)
```

---

## Implementation Patterns

### PATTERN 1: Listagem Filtrada por Nivel

**Quando usar:** ListView, listar registros que o usuario pode ver.

```python
from django.contrib.auth.mixins import LoginRequiredMixin, PermissionRequiredMixin
from django.views.generic import ListView
from sgi.base.mixins import FiltrarQuerySetPorNivelAcessoMixin

class ListarOfertasView(
    LoginRequiredMixin,
    PermissionRequiredMixin,
    FiltrarQuerySetPorNivelAcessoMixin,  # <- ESSENCIAL
    ListView,
):
    model = Oferta
    permission_required = "ofertas.view_oferta"

    # OBRIGATORIO: Caminho ORM ate Carteira
    lookup_field_carteira = "carteira"  # Oferta.carteira (FK direta)

    def get_queryset(self):
        qs = super().get_queryset()  # Ja vem filtrado pelo mixin!
        # Adicione filtros extras aqui se necessario
        return qs.select_related("carteira", "cliente")
```

### PATTERN 2: Detalhe/Edicao de Registro Individual

**Quando usar:** DetailView, UpdateView, acesso a registro especifico.

```python
from django.shortcuts import get_object_or_404
from sgi.base.mixins import FiltrarQuerySetPorNivelAcessoMixin

class EditarOfertaView(
    LoginRequiredMixin,
    PermissionRequiredMixin,
    FiltrarQuerySetPorNivelAcessoMixin,
    UpdateView,
):
    model = Oferta
    permission_required = "ofertas.change_oferta"
    lookup_field_carteira = "carteira"

    def get_object(self, queryset=None):
        # Busca no queryset JA FILTRADO - retorna 404 se sem acesso
        qs = self.get_queryset()
        return get_object_or_404(qs, uuid=self.kwargs["oferta_uuid"])
```

### PATTERN 3: Mixin Customizado para Modulo

**Quando usar:** Criar mixin reutilizavel para um modulo (ex: ofertas).

```python
# sgi/ofertas/mixins.py
from django.db.models import QuerySet
from django.shortcuts import get_object_or_404
from sgi.base.mixins import FiltrarQuerySetPorNivelAcessoMixin
from sgi.base.permissions import NivelAcessoPermission

class OfertaAcessoMixin(FiltrarQuerySetPorNivelAcessoMixin):
    """Mixin de acesso para views de ofertas."""

    lookup_field_carteira = "carteira"

    def get_oferta_com_acesso(self, oferta_uuid) -> Oferta:
        """Busca oferta garantindo acesso. Retorna 404 se sem permissao."""
        qs = self.filtrar_por_nivel_acesso(
            Oferta.objects.select_related(
                "carteira",
                "cliente",
                "assessorado",
            )
        )
        return get_object_or_404(qs, uuid=oferta_uuid)

    def validar_acesso_cliente(self, cliente_id: int) -> bool:
        """Valida se usuario pode usar este cliente."""
        if not cliente_id:
            return False

        # Cliente tem caminho diferente ate Carteira
        qs = self.filtrar_por_nivel_acesso(
            Cliente.objects.filter(ativo=True),
            lookup_field="assessorado__grupo_familiar__carteira",
        )
        return qs.filter(id=cliente_id).exists()

    def validar_acesso_carteira(self, carteira_id: int) -> bool:
        """Valida se usuario pode usar esta carteira."""
        if not carteira_id:
            return False

        carteiras_ids = NivelAcessoPermission.obter_carteiras_usuario(
            self.request.user
        )

        if carteiras_ids is None:  # GERAL - acesso total
            return Carteira.objects.filter(id=carteira_id, ativa=True).exists()

        return int(carteira_id) in carteiras_ids

    def filtrar_por_nivel_acesso(
        self,
        queryset: QuerySet,
        lookup_field: str | None = None,
    ) -> QuerySet:
        """Filtra queryset. Aceita lookup customizado."""
        lf = lookup_field or self.lookup_field_carteira
        return NivelAcessoPermission.filtrar_queryset_por_nivel_acesso(
            user=self.request.user,
            queryset=queryset,
            lookup_carteira=lf,
        )
```

### PATTERN 4: View AJAX/API com Validacao

**Quando usar:** Endpoints que recebem IDs e precisam validar acesso.

```python
from django.http import JsonResponse
from django.views import View

class SalvarOfertaAjaxView(LoginRequiredMixin, OfertaAcessoMixin, View):

    def post(self, request):
        carteira_id = request.POST.get("carteira_id")
        cliente_id = request.POST.get("cliente_id")

        # VALIDAR ACESSO ANTES DE SALVAR
        if not self.validar_acesso_carteira(carteira_id):
            return JsonResponse(
                {"error": "Sem acesso a esta carteira"},
                status=403
            )

        if cliente_id and not self.validar_acesso_cliente(cliente_id):
            return JsonResponse(
                {"error": "Sem acesso a este cliente"},
                status=403
            )

        # Prosseguir com a criacao...
        oferta = Oferta.objects.create(
            carteira_id=carteira_id,
            cliente_id=cliente_id,
            # ...
        )

        return JsonResponse({"success": True, "uuid": str(oferta.uuid)})
```

### PATTERN 5: Filtrar Dados de Formulario (Selects)

**Quando usar:** Popular dropdowns com dados que o usuario pode ver.

```python
class OfertaDadosFormularioMixin(FiltrarQuerySetPorNivelAcessoMixin):
    """Mixin para filtrar dados de selects."""

    lookup_field_carteira = "carteira"

    def get_clientes_filtrados(self) -> QuerySet:
        """Clientes que o usuario pode selecionar."""
        return NivelAcessoPermission.filtrar_queryset_por_nivel_acesso(
            user=self.request.user,
            queryset=Cliente.objects.filter(ativo=True),
            lookup_carteira="assessorado__grupo_familiar__carteira",
        )

    def get_carteiras_filtradas(self) -> QuerySet:
        """Carteiras que o usuario pode selecionar."""
        carteiras_ids = NivelAcessoPermission.obter_carteiras_usuario(
            self.request.user
        )

        qs = Carteira.objects.filter(ativa=True)

        if carteiras_ids is None:  # GERAL
            return qs

        return qs.filter(id__in=carteiras_ids)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["clientes"] = self.get_clientes_filtrados()
        context["carteiras"] = self.get_carteiras_filtradas()
        return context
```

---

## lookup_field_carteira Reference

**CRUCIAL:** Este campo define o caminho ORM ate Carteira.

| Model | lookup_field_carteira | Explicacao |
|-------|----------------------|-------------|
| GrupoFamiliar | `"carteira"` | FK direta |
| Oferta | `"carteira"` | FK direta |
| Assessorado | `"grupo_familiar__carteira"` | Via GrupoFamiliar |
| Cliente | `"assessorado__grupo_familiar__carteira"` | Via Assessorado |
| Pedido | `"assessorado__grupo_familiar__carteira"` | Via Assessorado |
| Fazenda | `"grupo_familiar__carteira"` | Via GrupoFamiliar |
| HistoricoSafra | `"grupo_familiar__carteira"` | Via GrupoFamiliar |

**Como descobrir o caminho:**
1. Identifique o model que voce esta filtrando
2. Trace o caminho de FKs ate chegar em Carteira
3. Use `__` para separar cada FK

---

## Decision Flowchart

```
REQUISICAO CHEGA
       │
       ▼
┌──────────────────┐
│  E superuser?    │
└────────┬─────────┘
         │
    SIM  │  NAO
    ▼    │    ▼
┌────────┐   ┌──────────────────┐
│ ACESSO │   │ E colaborador?   │
│ TOTAL  │   └────────┬─────────┘
└────────┘            │
              NAO     │  SIM
              ▼       │    ▼
        ┌────────┐   ┌──────────────────┐
        │ .none()│   │ Qual nivel?      │
        │ (zero) │   └────────┬─────────┘
        └────────┘            │
                   ┌──────────┼──────────┬──────────┐
                   │          │          │          │
                GERAL    ESTADUAL   FILIAL/REG  CARTEIRA
                   │          │          │          │
                   ▼          ▼          ▼          ▼
              ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
              │Sem     │ │WHERE   │ │WHERE   │ │WHERE   │
              │filtro  │ │estado  │ │filial  │ │carteira│
              │        │ │IN (X)  │ │IN (X)  │ │IN (X)  │
              └────────┘ └────────┘ └────────┘ └────────┘
```

---

## Common Mistakes

### ERRO 1: Esquecer lookup_field_carteira

```python
# ERRADO - vai dar ImproperlyConfigured
class MinhaView(FiltrarQuerySetPorNivelAcessoMixin, ListView):
    model = Oferta
    # lookup_field_carteira = ???  <- FALTOU!

# CORRETO
class MinhaView(FiltrarQuerySetPorNivelAcessoMixin, ListView):
    model = Oferta
    lookup_field_carteira = "carteira"  # <- OBRIGATORIO
```

### ERRO 2: Lookup errado para o model

```python
# ERRADO - Cliente nao tem FK direta para carteira
lookup_field_carteira = "carteira"

# CORRETO - Cliente acessa carteira via assessorado
lookup_field_carteira = "assessorado__grupo_familiar__carteira"
```

### ERRO 3: Nao usar o queryset filtrado

```python
# ERRADO - Busca direta sem filtro de acesso
def get_object(self):
    return Oferta.objects.get(uuid=self.kwargs["uuid"])

# CORRETO - Busca no queryset filtrado
def get_object(self):
    qs = self.get_queryset()  # <- Ja filtrado pelo mixin
    return get_object_or_404(qs, uuid=self.kwargs["uuid"])
```

### ERRO 4: Validar escrita sem verificar acesso

```python
# ERRADO - Cria oferta sem validar se usuario pode usar a carteira
def post(self, request):
    Oferta.objects.create(carteira_id=request.POST["carteira_id"])

# CORRETO - Valida acesso antes de criar
def post(self, request):
    if not self.validar_acesso_carteira(request.POST["carteira_id"]):
        return HttpResponseForbidden()
    Oferta.objects.create(carteira_id=request.POST["carteira_id"])
```

### ERRO 5: Reimplementar logica de filtro

```python
# ERRADO - Reimplementando logica manualmente
def get_queryset(self):
    user = self.request.user
    if user.colaborador.cargo.nivel_acesso == "carteira":
        return Oferta.objects.filter(carteira__in=user.colaborador.carteiras.all())
    # ... mais codigo duplicado

# CORRETO - Usar o sistema centralizado
def get_queryset(self):
    return self.filtrar_por_nivel_acesso(Oferta.objects.all())
```

---

## Checklist de Implementacao

```markdown
## Nova View com Controle de Acesso

### Setup
- [ ] Herdar de `FiltrarQuerySetPorNivelAcessoMixin`
- [ ] Definir `lookup_field_carteira` com caminho correto
- [ ] Adicionar `LoginRequiredMixin` (primeiro na lista)
- [ ] Adicionar `PermissionRequiredMixin` com permissao apropriada

### Listagem
- [ ] `get_queryset()` chama `super()` (mixin filtra automaticamente)
- [ ] Select/Prefetch relacionamentos necessarios

### Detalhe/Edicao
- [ ] `get_object()` usa `get_object_or_404(self.get_queryset(), ...)`
- [ ] Nunca buscar direto no Model.objects sem filtro

### Formularios
- [ ] Dropdowns populados com dados filtrados
- [ ] Usar `get_clientes_filtrados()`, `get_carteiras_filtradas()`

### Escrita (Create/Update)
- [ ] Validar `carteira_id` antes de salvar
- [ ] Validar `cliente_id` se aplicavel
- [ ] Usar `validar_acesso_carteira()` e `validar_acesso_cliente()`

### Testes
- [ ] Testar com usuario CARTEIRA (deve ver apenas suas carteiras)
- [ ] Testar com usuario GERAL (deve ver tudo)
- [ ] Testar acesso a registro de outra carteira (deve dar 404)
```

---

## Reference: View Modelo (Copie e Adapte)

```python
"""
View completa com controle de acesso SGI.
Copie e adapte para seu caso de uso.
"""
from django.contrib.auth.mixins import LoginRequiredMixin, PermissionRequiredMixin
from django.shortcuts import get_object_or_404
from django.views.generic import ListView, DetailView, CreateView, UpdateView

from sgi.base.mixins import FiltrarQuerySetPorNivelAcessoMixin
from sgi.base.permissions import NivelAcessoPermission


class MeuModeloListView(
    LoginRequiredMixin,
    PermissionRequiredMixin,
    FiltrarQuerySetPorNivelAcessoMixin,
    ListView,
):
    """Listagem filtrada por nivel de acesso."""

    model = MeuModelo
    template_name = "app/listar.html"
    permission_required = "app.view_meumodelo"
    lookup_field_carteira = "carteira"  # AJUSTE para seu model
    paginate_by = 20

    def get_queryset(self):
        qs = super().get_queryset()  # Ja vem filtrado!
        return qs.select_related("carteira", "outros_relacionamentos")


class MeuModeloDetailView(
    LoginRequiredMixin,
    PermissionRequiredMixin,
    FiltrarQuerySetPorNivelAcessoMixin,
    DetailView,
):
    """Detalhe com verificacao de acesso."""

    model = MeuModelo
    template_name = "app/detalhe.html"
    permission_required = "app.view_meumodelo"
    lookup_field_carteira = "carteira"

    def get_object(self, queryset=None):
        qs = self.get_queryset()
        return get_object_or_404(qs, uuid=self.kwargs["uuid"])


class MeuModeloCreateView(
    LoginRequiredMixin,
    PermissionRequiredMixin,
    FiltrarQuerySetPorNivelAcessoMixin,
    CreateView,
):
    """Criacao com validacao de acesso."""

    model = MeuModelo
    template_name = "app/form.html"
    permission_required = "app.add_meumodelo"
    lookup_field_carteira = "carteira"
    fields = ["campo1", "campo2", "carteira"]

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        # Popula dropdown com carteiras permitidas
        carteiras_ids = NivelAcessoPermission.obter_carteiras_usuario(
            self.request.user
        )
        if carteiras_ids is None:
            context["carteiras"] = Carteira.objects.filter(ativa=True)
        else:
            context["carteiras"] = Carteira.objects.filter(
                id__in=carteiras_ids, ativa=True
            )
        return context

    def form_valid(self, form):
        # Valida se pode usar a carteira selecionada
        carteira_id = form.cleaned_data.get("carteira")
        carteiras_ids = NivelAcessoPermission.obter_carteiras_usuario(
            self.request.user
        )

        if carteiras_ids is not None and carteira_id.id not in carteiras_ids:
            form.add_error("carteira", "Voce nao tem acesso a esta carteira")
            return self.form_invalid(form)

        return super().form_valid(form)
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────┐
│                    SGI ACCESS CONTROL                           │
├─────────────────────────────────────────────────────────────────┤
│ IMPORT:                                                         │
│   from sgi.base.permissions import NivelAcessoPermission        │
│   from sgi.base.mixins import FiltrarQuerySetPorNivelAcessoMixin│
├─────────────────────────────────────────────────────────────────┤
│ LISTAGEM:                                                       │
│   1. Herdar FiltrarQuerySetPorNivelAcessoMixin                 │
│   2. Definir lookup_field_carteira = "caminho__ate__carteira"  │
│   3. get_queryset() -> super().get_queryset()                  │
├─────────────────────────────────────────────────────────────────┤
│ DETALHE:                                                        │
│   get_object_or_404(self.get_queryset(), uuid=...)             │
├─────────────────────────────────────────────────────────────────┤
│ VALIDAR ESCRITA:                                                │
│   NivelAcessoPermission.obter_carteiras_usuario(user)          │
│   -> None = GERAL (pode tudo)                                  │
│   -> [ids] = lista de carteiras permitidas                     │
├─────────────────────────────────────────────────────────────────┤
│ NIVEIS: GERAL(4) > ESTADUAL(3) > FILIAL/REG(2) > CARTEIRA(1)  │
└─────────────────────────────────────────────────────────────────┘
```
