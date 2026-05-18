# Linear Workflow State IDs

Single source of truth pros state IDs por team. Consumido por `linear-work` (mover issues) e `linear-pm` (criar issue em estado especifico).

## Resumo (IDs curtos pra grep)

| Team | Backlog | Todo | In Progress | In Review | Done | Canceled |
|------|---------|------|-------------|-----------|------|----------|
| IAP | `864e6d89` | `d9ee0a28` | `63d82e50` | `210d982d` | `782dfd8a` | `ec8f76dd` |
| WFW | `6a17e88b` | `73c302a8` | `ada57e06` | `375f55a8` | `dbb124d1` | `f5d62680` |
| IA  | `4e00167a` | `4e4c1171` | `08c23863` | `e23d1ccd` | `2fe9f7ed` | `1566587e` |

## IDs completos (usar nas mutations)

### IAP — Impeto AI Partners
| State | ID |
|-------|----|
| Backlog | `864e6d89-2074-4e30-9f94-b5eba62d81a5` |
| Todo | `d9ee0a28-e8be-498a-9d52-18641d2f0633` |
| In Progress | `63d82e50-5899-4ad4-be39-09d265a3c7e3` |
| In Review | `210d982d-f9c1-46e0-9ebb-c8a7ffc1bea8` |
| Done | `782dfd8a-f433-43a1-9690-f04d00197dae` |
| Canceled | `ec8f76dd-b3c0-4eae-977f-0799f9742fe1` |

### WFW — Workflow
| State | ID |
|-------|----|
| Backlog | `6a17e88b-2fe0-4f68-af47-8250b00152a0` |
| Todo | `73c302a8-9375-4f10-b03c-4d7e4a3b619c` |
| In Progress | `ada57e06-3cd0-4700-8865-a1d8d272b740` |
| In Review | `375f55a8-f8fd-459c-a492-8566c4b77f25` |
| Done | `dbb124d1-e26e-4397-9e73-44de04149c00` |
| Canceled | `f5d62680-5214-42b4-8869-3e30ae228233` |

### IA — Impeto AI Core
| State | ID |
|-------|----|
| Backlog | `4e00167a-06d2-4dc9-9e4d-d706c3e864b1` |
| Todo | `4e4c1171-8df3-40e2-9fed-c682f5e787ee` |
| In Progress | `08c23863-0e85-46fd-851d-48b927855509` |
| In Review | `e23d1ccd-da99-4572-887f-61e6d0a59e90` |
| Done | `2fe9f7ed-200c-40f1-804a-73725e61183d` |
| Canceled | `1566587e-db99-4718-a24f-3df272dcdb27` |

## Regras de transicao (workflow padrao Impeto)

```
Backlog → Todo → In Progress → In Review → Done
                              ↑
                         Gate humano
                         (Danilo / Joao)
```

- NUNCA pular In Review (nao mover direto pra Done)
- In Review → Done = somente humano aprova
- PR merged em main move issue pra Done automaticamente (via integracao GitHub) — agent NAO deve mover manualmente quando ha PR aberto
