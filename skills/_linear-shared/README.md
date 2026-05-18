# `_linear-shared/` — Referencia compartilhada das skills Linear

Esta pasta NAO e uma skill. E o **single source of truth** de IDs (templates, states, labels, teams) consumido por:

- `linear-init` — carrega contexto e lista templates
- `linear-pm` — cria projetos/milestones/issues (precisa template IDs + Type/* IDs)
- `linear-work` — operacao diaria (mover estados precisa state IDs)

**Regra:** se um ID muda no Linear, atualiza SO aqui. As skills referenciam via `Read(_linear-shared/<arquivo>.md)`.

## Arquivos

- [`templates.md`](templates.md) — issue templates (7) + project templates (2) + Type/* label IDs
- [`state-ids.md`](state-ids.md) — workflow state IDs por team (Backlog/Todo/In Progress/In Review/Done/Canceled)
- [`teams.md`](teams.md) — team IDs + keys + uso

## Atualizar IDs

Rodar via Linear API:
```graphql
# Templates
{ templates { nodes { id name type } } }

# States por team
{ workflowStates { nodes { id name type team { key } } } }

# Labels Type/*
{ issueLabels(filter: {parent: {name: {eq: "Type"}}}) { nodes { id name } } }
```

Cole os outputs nos arquivos correspondentes.
