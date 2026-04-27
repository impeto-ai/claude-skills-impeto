---
name: linear-init
description: Initializes Linear context for the current session. Loads API key, identifies user, shows assigned tasks, projetos, e templates ativos do workspace. Use at session start or to reload Linear context.
chain: none
---

# Linear Init - Contexto Inteligente (v2 — com templates)

Carrega o contexto do Linear para a sessao atual: usuario, tasks atribuidas, projetos ativos, **9 templates do workspace** (7 issue + 2 project) e 7 children labels do `Type/` group.

## When to Use
- Inicio de sessao para carregar contexto do Linear
- Recarregar contexto no meio da sessao
- Verificar "quais minhas tasks?"
- NOT when: criar/mover/comentar issues (use /linear-work)
- NOT when: criar projetos/milestones (use /linear-pm)

## PASSO 0: VERIFICAR API KEY (OBRIGATORIO)

**ANTES DE QUALQUER COISA**, verificar se existe a variavel `LINEAR_API_KEY`:

1. Procurar `.env` no diretorio atual do projeto
2. Se nao encontrar, procurar em `~/.claude/.env`
3. Se nao encontrar em nenhum dos dois:

```
⚠️  LINEAR_API_KEY nao encontrada!

Para usar a integracao com o Linear, voce precisa de uma API key.
Solicite sua key ao seu manager (Joao - joao@impeto.ai).

Apos receber a key:
1. Crie um arquivo .env na raiz do projeto (ou em ~/.claude/.env)
2. Adicione: LINEAR_API_KEY=lin_api_XXXXX
3. Rode /linear-init novamente

Sem a API key, nenhuma operacao do Linear funcionara.
```

**PARAR AQUI se nao encontrar a key. Nao tentar nenhuma operacao.**

---

## PASSO 1: IDENTIFICAR USUARIO (CRÍTICO — define o contexto da sessão)

**O viewer.id retornado aqui é o ID do usuário pra toda a sessão.**
Guardar e usar como `assigneeId` default em TODA criação/atribuição de issue.
Se a query falhar → API key errada → PARAR.

```graphql
{
  viewer {
    id name email
    assignedIssues(
      filter: { state: { type: { nin: ["completed", "canceled"] } } }
      first: 50
      orderBy: updatedAt
    ) {
      nodes {
        identifier title
        state { name type }
        priority
        dueDate
        project { name }
        projectMilestone { name }
        labels { nodes { name } }
        team { key }
      }
    }
  }
}
```

## PASSO 2: CARREGAR TEMPLATES + LABELS Type/ (v2 — OBRIGATORIO)

Carrega os 9 templates ativos no workspace + Type label group children. Outras skills (linear-work, linear-pm, linear-teams) consomem isso da saida.

```graphql
{
  organization {
    templates {
      nodes { id name type }
    }
  }
  typeLabels: issueLabels(filter: { parent: { name: { eq: "Type" } } }) {
    nodes { id name color }
  }
}
```

## PASSO 3: CONSULTAR PROJETOS ATIVOS

```graphql
{
  teams {
    nodes {
      key name
      projects(filter: { state: { eq: "started" } }, first: 20) {
        nodes {
          name
          progress
          projectMilestones { nodes { name } }
          members { nodes { name } }
        }
      }
    }
  }
}
```

## PASSO 4: APRESENTAR CONTEXTO

Formato de saida:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  LINEAR CONTEXT LOADED (v2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Usuario: {name} ({email})
  Teams: {lista de teams}
  Data: {hoje}

━━━ MINHAS TASKS ({count} ativas) ━━━━

  🔴 URGENT/HIGH
  {identifier} | {title} | {state} | {project} | due: {date}

  🟡 MEDIUM
  ...

  🟢 LOW/NONE
  ...

━━━ PROJETOS ATIVOS ━━━━━━━━━━━━━━━━━

  {team_key} | {project_name} | {progress}% | {milestones}

━━━ TEMPLATES (workspace) ━━━━━━━━━━

  Issue Templates (7):
    Feature   | e682d84c-1e1c-40e7-bdd6-19853c4a577f
    Bug       | 7c547bce-b64b-46ef-8e76-80ca5b234637
    Hotfix    | 8357bb00-4618-4474-9351-5a95c47d572e
    Refactor  | 85878d0f-b983-4ce7-9662-b15546c0494f
    Spike     | f9c21b5c-6a74-4b53-a4cb-94fa038e3219
    Report    | bc934845-83d0-4b7d-b613-8b64425498b7
    Knowledge | 3ca2d511-8c86-432a-b374-2daef63f15ce

  Project Templates (2):
    Software Development  | 2cfa380e-7552-4eee-b50f-a56a960054e2
    AI Development        | e4265043-9517-455c-8866-837f01404adc

  Type Label Group (7 children):
    Type/Feature, Type/Bug, Type/Hotfix, Type/Refactor,
    Type/Spike, Type/Report, Type/Knowledge

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Use /linear-work pra operar tasks
  Use /linear-pm pra criar projetos/issues complexos
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## PASSO 5: SUGERIR PROXIMA ACAO

Com base no contexto carregado:
- Se tem tasks "In Progress" paradas → "Voce tem {n} tasks em progresso. Quer atualizar alguma?"
- Se tem tasks com due date proximo → "⚠️ {identifier} vence em {n} dias"
- Se nao tem tasks "In Progress" → "Nenhuma task em andamento. Quer pegar algo do To Do?"

---

## API Reference

- Endpoint: `https://api.linear.app/graphql`
- Auth: `Authorization: {LINEAR_API_KEY}` (valor do .env)
- Metodo: POST com body JSON `{"query": "..."}`

## Teams Impeto

| Team | ID | Key |
|------|----|-----|
| Impeto AI Core | `55aebf79-3615-4c29-8612-a6d415be4bdc` | IA |
| Workflow | `23b3fdd3-3087-4c00-b650-ad3435d24252` | WFW |
| Impeto AI Partners | `c399b23d-f3dc-443a-ba92-43ffd7faad91` | IAP |

## Templates do Workspace (referencia rapida)

### Issue Templates (todos workspace, type=issue)
| Template | ID | Type/* label aplicado | Priority default |
|----------|----|----|----|
| Feature | `e682d84c-1e1c-40e7-bdd6-19853c4a577f` | Type/Feature | 3 (Medium) |
| Bug | `7c547bce-b64b-46ef-8e76-80ca5b234637` | Type/Bug | 2 (High) |
| Hotfix | `8357bb00-4618-4474-9351-5a95c47d572e` | Type/Hotfix | 1 (Urgent) |
| Refactor | `85878d0f-b983-4ce7-9662-b15546c0494f` | Type/Refactor | 4 (Low) |
| Spike | `f9c21b5c-6a74-4b53-a4cb-94fa038e3219` | Type/Spike | 3 (Medium) |
| Report | `bc934845-83d0-4b7d-b613-8b64425498b7` | Type/Report | 3 (Medium) |
| Knowledge | `3ca2d511-8c86-432a-b374-2daef63f15ce` | Type/Knowledge | 4 (Low) |

### Project Templates (workspace, type=project)
| Template | ID | Milestones |
|----------|----|----|
| Software Development | `2cfa380e-7552-4eee-b50f-a56a960054e2` | M0 Discovery → M4 Quality+Launch |
| AI Development | `e4265043-9517-455c-8866-837f01404adc` | M0 Use Case → M4 Quality+Production |

### Type/* labels (parent: Type group `8e9ee646-bb27-413d-8e21-3272714203b5`)
| Label | ID |
|-------|----|
| Type/Feature | `d046098f-3937-4a28-bf19-57082d9bff71` |
| Type/Bug | `0fab8687-157d-4d07-bddc-f68a3f1fd887` |
| Type/Hotfix | `e05992d5-f5ae-45e6-8f2f-27ab187157b3` |
| Type/Refactor | `860bbe5a-c1d5-4104-bbe2-15c899f309db` |
| Type/Spike | `dc6567c6-b5a8-4cb6-a742-1b078cc5e54f` |
| Type/Report | `1018beba-b5d4-4a96-8766-d6f18c4c3df9` |
| Type/Knowledge | `3a4669b3-4b92-4b0d-a37d-a5683c186463` |

## Common Mistakes
- Tentar operar sem API key (SEMPRE verificar primeiro)
- Consultar issues de todos os times sem filtrar por usuario (usar viewer.assignedIssues)
- Mostrar issues completed/canceled (filtrar por state type)
- (v2) Esquecer de carregar templates no PASSO 2 — outras skills dependem do output
