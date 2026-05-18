# Linear Teams (workspace Impeto)

Single source of truth pros team IDs. Usado em `issueCreate`, `projectCreate` e qualquer mutation com `teamId`.

| Team | Key | ID | Uso |
|------|-----|----|----|
| Impeto AI Core | IA | `55aebf79-3615-4c29-8612-a6d415be4bdc` | Produtos proprios + clientes Impeto |
| Workflow | WFW | `23b3fdd3-3087-4c00-b650-ad3435d24252` | Projetos Workflow (PMEs, automacao) |
| Impeto AI Partners | IAP | `c399b23d-f3dc-443a-ba92-43ffd7faad91` | Parcerias / Innovagro |

O `key` do team aparece como prefixo do `identifier` da issue (IA-123, WFW-42, IAP-7). Agent deriva o team key dinamicamente do `identifier` da issue — NUNCA hardcode.
