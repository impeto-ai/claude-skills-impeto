# Linear Templates (workspace Impeto)

Single source of truth pros 7 issue templates + 2 project templates + 7 Type/* labels.

Consumido por: `linear-init`, `linear-pm`, `linear-work`.

## Issue Templates (todos os teams herdam do workspace)

Sao OBRIGATORIOS em qualquer `issueCreate`. Escolher 1 dos 7.

| Template | ID | Type/* aplicado | Priority default | Quando usar |
|----------|----|----|----|----|
| Feature | `e682d84c-1e1c-40e7-bdd6-19853c4a577f` | Type/Feature | 3 (Medium) | Nova funcionalidade |
| Bug | `7c547bce-b64b-46ef-8e76-80ca5b234637` | Type/Bug | 2 (High) | Defeito em prod/staging |
| Hotfix | `8357bb00-4618-4474-9351-5a95c47d572e` | Type/Hotfix | 1 (Urgent) | Prod parado, fix imediato |
| Refactor | `85878d0f-b983-4ce7-9662-b15546c0494f` | Type/Refactor | 4 (Low) | Limpar codigo, renomear, extrair |
| Spike | `f9c21b5c-6a74-4b53-a4cb-94fa038e3219` | Type/Spike | 3 (Medium) | Investigacao, POC, timebox |
| Report | `bc934845-83d0-4b7d-b613-8b64425498b7` | Type/Report | 3 (Medium) | Relatorio, dashboard, analise |
| Knowledge | `3ca2d511-8c86-432a-b374-2daef63f15ce` | Type/Knowledge | 4 (Low) | Documentar, ata, transcricao |

## Project Templates

Usar em `projectCreate` (linear-pm).

| Template | ID | Use case |
|----------|----|----------|
| Software Development | `2cfa380e-7552-4eee-b50f-a56a960054e2` | Codigo tradicional (Next.js, FastAPI, Supabase, dashboards) |
| AI Development | `e4265043-9517-455c-8866-837f01404adc` | Agentes AI / LLM / Pydantic AI / multi-provider |

## Type/* Labels

Type group parent: `8e9ee646-bb27-413d-8e21-3272714203b5`

| Label | ID |
|-------|----|
| Type/Feature | `d046098f-3937-4a28-bf19-57082d9bff71` |
| Type/Bug | `0fab8687-157d-4d07-bddc-f68a3f1fd887` |
| Type/Hotfix | `e05992d5-f5ae-45e6-8f2f-27ab187157b3` |
| Type/Refactor | `860bbe5a-c1d5-4104-bbe2-15c899f309db` |
| Type/Spike | `dc6567c6-b5a8-4cb6-a742-1b078cc5e54f` |
| Type/Report | `1018beba-b5d4-4a96-8766-d6f18c4c3df9` |
| Type/Knowledge | `3a4669b3-4b92-4b0d-a37d-a5683c186463` |

## Outras labels conhecidas

| Label | ID | Uso |
|-------|----|----|
| Claude | `6dad8eed-291b-413b-9bfc-524e7aae0521` | Marcador "feito por Claude Code" |
| frontend | `27e77b77-aa4a-41ec-b8fe-bd0a9b86b58c` | Componente |
| backend | `7bcc0759-f2a7-4184-b4f7-df2256f1eeb5` | Componente |
| Frontend (cap, WFW) | `74550db2-01cb-4da8-b6d0-13d4507427d7` | Componente — duplicado por casing, cleanup pendente |
| Backend (cap, WFW) | `c430dcd3-6b98-4e84-8101-489f6362c539` | Componente — idem |
| ai | `66de6fae-5f2f-46f8-af7f-72dabefb20fc` | Componente |
| devops | `e47f1131-2f62-4ec2-ab19-5a1d93b06834` | Componente |

## Como usar nas mutations

**Criar issue com template:**
```graphql
mutation {
  issueCreate(input: {
    title: "..."
    teamId: "..."
    templateId: "<id do template aqui>"
    labelIds: ["<Type/* correspondente>"]   # OBRIGATORIO se passar labelIds — senao sobrescreve
  }) { issue { identifier url } }
}
```

ATENCAO: passar `labelIds` JUNTO com `templateId` SOBRESCREVE labels do template. Sempre incluir o `Type/*` correspondente no array.

**Criar projeto com template:**
```graphql
mutation {
  projectCreate(input: {
    name: "..."
    teamIds: ["..."]
    templateId: "<software dev OU ai dev>"
  }) { project { id name } }
}
```
