---
name: linear-init
description: Initializes Linear context for the current session. Loads API key, identifies user, shows assigned tasks and project panorama. Use at session start or to reload Linear context.
chain: none
---

# Linear Init - Contexto Inteligente

Carrega o contexto do Linear para a sessao atual. Identifica o usuario, mostra tasks atribuidas e panorama dos projetos.

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

## PASSO 1: IDENTIFICAR USUARIO

Usar a API key encontrada para consultar o viewer:

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

## PASSO 2: CONSULTAR PROJETOS ATIVOS

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

## PASSO 3: APRESENTAR CONTEXTO

Formato de saida:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  LINEAR CONTEXT LOADED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Usuario: {name} ({email})
  Teams: {lista de teams}
  Data: {hoje}

━━━ MINHAS TASKS ({count} ativas) ━━━━

  🔴 URGENT/HIGH
  {identifier} | {title} | {state} | {project} | due: {date}

  🟡 MEDIUM
  {identifier} | {title} | {state} | {project} | due: {date}

  🟢 LOW/NONE
  {identifier} | {title} | {state} | {project} | due: {date}

━━━ PROJETOS ATIVOS ━━━━━━━━━━━━━━━━━

  {team_key} | {project_name} | {progress}% | {milestones}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Use /linear-work para operar nas tasks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## PASSO 4: SUGERIR PROXIMA ACAO

Com base no contexto carregado, sugerir:
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
| Impeto AI Partners | `c399b23d-f3dc-443a-ba92-43ffd7faad91` | IAP |
| Workflow | `23b3fdd3-3087-4c00-b650-ad3435d24252` | WFW |
| Impeto AI Core | `55aebf79-3615-4c29-8612-a6d415be4bdc` | IA |

## Common Mistakes
- Tentar operar sem API key (SEMPRE verificar primeiro)
- Consultar issues de todos os times sem filtrar por usuario (usar viewer.assignedIssues)
- Mostrar issues completed/canceled (filtrar por state type)
