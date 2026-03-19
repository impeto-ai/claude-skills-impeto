---
name: git-specialist
description: Use when working with Git operations - diffs, commits, branches, merges, rebases, conflict resolution. Activates for "git", "commit", "branch", "diff", "merge", "rebase", "conflito".
chain: none
---

# Git Specialist - Operações Git Eficientes

Skill especializada para operações Git avançadas com foco em produtividade, commits limpos e gerenciamento eficiente de branches.

## When to Use
- Ao visualizar diffs e mudanças
- Ao fazer commits estruturados
- Ao trabalhar com múltiplas branches
- Ao fazer merge ou rebase
- Ao resolver conflitos
- Ao navegar no histórico
- NOT when: operações destrutivas sem confirmação explícita

## Princípios Git

1. **Commits atômicos:** Uma mudança lógica por commit
2. **Mensagens descritivas:** Explica o "porquê", não só o "quê"
3. **Branches curtas:** Merge frequente, evita divergência
4. **Histórico limpo:** Squash quando necessário, rebase com cuidado

---

## 1. VISUALIZAÇÃO DE DIFFS

### Ver mudanças não commitadas
```bash
# Mudanças no working directory (não staged)
git diff

# Mudanças staged (prontas para commit)
git diff --staged

# Ambas (staged + unstaged)
git diff HEAD

# Resumo estatístico
git diff --stat

# Apenas nomes dos arquivos alterados
git diff --name-only

# Com status (M=modified, A=added, D=deleted)
git diff --name-status
```

### Comparar branches
```bash
# Diferença entre branches
git diff main..feature-branch

# O que feature-branch tem que main não tem
git diff main...feature-branch

# Commits que estão em feature mas não em main
git log main..feature-branch --oneline

# Arquivos diferentes entre branches
git diff main..feature-branch --name-only
```

### Diff de um arquivo específico
```bash
# Histórico de mudanças de um arquivo
git log -p -- path/to/file.tsx

# Diff entre versões de um arquivo
git diff HEAD~3 HEAD -- path/to/file.tsx

# Quem alterou cada linha (blame)
git blame path/to/file.tsx
```

---

## 2. COMMITS EFICIENTES

### Padrão de Mensagem (Conventional Commits)
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `refactor`: Refatoração (sem mudança de comportamento)
- `style`: Formatação (espaços, vírgulas, etc)
- `docs`: Documentação
- `test`: Adição/modificação de testes
- `chore`: Tarefas de build, configs, etc
- `perf`: Melhoria de performance

**Exemplos:**
```bash
git commit -m "feat(despesa): adicionar KPIs na home page"
git commit -m "fix(receita): corrigir cálculo de valor total"
git commit -m "refactor(components): extrair SearchSelect para arquivo separado"
```

### Staging Parcial (Parte de um arquivo)
```bash
# Interativo - escolhe hunks
git add -p path/to/file.tsx

# Opções no modo interativo:
# y = stage this hunk
# n = skip this hunk
# s = split into smaller hunks
# e = edit hunk manually
```

### Amend (Corrigir último commit)
```bash
# Adicionar arquivos esquecidos ao último commit
git add forgotten-file.tsx
git commit --amend --no-edit

# Alterar mensagem do último commit
git commit --amend -m "nova mensagem"

# ⚠️ NUNCA amend em commits já pushados!
```

### Desfazer commits
```bash
# Desfazer último commit, mantendo mudanças staged
git reset --soft HEAD~1

# Desfazer último commit, mantendo mudanças unstaged
git reset HEAD~1

# Desfazer último commit E descartar mudanças ⚠️
git reset --hard HEAD~1
```

---

## 3. GERENCIAMENTO DE BRANCHES

### Criar e navegar
```bash
# Criar branch e mudar para ela
git checkout -b feature/nova-funcionalidade

# Criar branch a partir de outra
git checkout -b feature/x origin/main

# Listar branches
git branch -a          # Todas (local + remote)
git branch -v          # Com último commit
git branch --merged    # Já mergeadas em HEAD
```

### Renomear branch
```bash
# Renomear branch atual
git branch -m novo-nome

# Renomear outra branch
git branch -m nome-antigo nome-novo
```

### Deletar branch
```bash
# Local (seguro - só se já foi mergeada)
git branch -d feature/antiga

# Local (forçado)
git branch -D feature/antiga

# Remota
git push origin --delete feature/antiga
```

### Atualizar branch com main
```bash
# Opção 1: Merge (preserva histórico)
git checkout feature/x
git merge main

# Opção 2: Rebase (histórico linear) ⚠️
git checkout feature/x
git rebase main

# Se conflito durante rebase:
git rebase --continue   # Após resolver
git rebase --abort      # Cancelar tudo
```

---

## 4. MERGE E REBASE

### Merge Strategies
```bash
# Merge padrão (cria merge commit se necessário)
git merge feature/x

# Merge com commit sempre (mesmo se fast-forward possível)
git merge --no-ff feature/x

# Squash (junta todos commits em um)
git merge --squash feature/x
git commit -m "feat: implementa feature X"
```

### Rebase Interativo
```bash
# Reordenar/editar últimos N commits
git rebase -i HEAD~5

# Opções no editor:
# pick   = usar commit
# reword = usar commit, mas editar mensagem
# edit   = pausar para editar commit
# squash = juntar com commit anterior
# fixup  = squash, mas descarta mensagem
# drop   = remover commit
```

### Quando usar cada um?
| Situação | Usar |
|----------|------|
| Feature branch pessoal | Rebase antes de merge |
| Branch compartilhada | Merge |
| Limpar histórico local | Rebase -i |
| Preservar contexto | Merge --no-ff |
| PR com muitos commits | Squash merge |

---

## 5. RESOLUÇÃO DE CONFLITOS

### Fluxo básico
```bash
# 1. Identificar arquivos com conflito
git status

# 2. Abrir arquivo e resolver manualmente
# Procurar por:
# <<<<<<< HEAD
# suas mudanças
# =======
# mudanças do outro branch
# >>>>>>> feature/x

# 3. Após resolver, marcar como resolvido
git add arquivo-resolvido.tsx

# 4. Continuar merge/rebase
git merge --continue
# ou
git rebase --continue
```

### Ferramentas de merge
```bash
# Usar ferramenta visual
git mergetool

# Aceitar versão nossa (HEAD)
git checkout --ours path/to/file.tsx

# Aceitar versão deles (incoming)
git checkout --theirs path/to/file.tsx
```

### Abortar operação
```bash
git merge --abort
git rebase --abort
git cherry-pick --abort
```

---

## 6. STASH (Guardar mudanças temporárias)

```bash
# Guardar mudanças (tracked files)
git stash

# Guardar com mensagem
git stash push -m "WIP: feature X"

# Guardar incluindo untracked
git stash -u

# Listar stashes
git stash list

# Aplicar último stash (mantém na lista)
git stash apply

# Aplicar e remover da lista
git stash pop

# Aplicar stash específico
git stash apply stash@{2}

# Ver diff de um stash
git stash show -p stash@{0}

# Deletar stash
git stash drop stash@{0}

# Limpar todos
git stash clear
```

---

## 7. HISTÓRICO E LOGS

### Visualizar commits
```bash
# Log resumido
git log --oneline

# Com gráfico de branches
git log --oneline --graph --all

# Últimos N commits
git log -5

# Commits de um autor
git log --author="João"

# Commits em período
git log --since="2024-01-01" --until="2024-01-31"

# Commits que tocaram um arquivo
git log -- path/to/file.tsx

# Buscar por mensagem
git log --grep="fix"

# Buscar por código alterado
git log -S "functionName"
```

### Inspecionar commit
```bash
# Ver detalhes de um commit
git show abc1234

# Ver apenas arquivos alterados
git show --stat abc1234

# Ver diff de um commit
git show abc1234 --patch
```

---

## 8. COMANDOS ÚTEIS DO DIA A DIA

### Status rápido
```bash
# Status curto
git status -s

# Branch atual
git branch --show-current

# Último commit
git log -1 --oneline
```

### Limpar working directory
```bash
# Ver o que seria removido (dry run)
git clean -n

# Remover untracked files
git clean -f

# Remover untracked files e diretórios
git clean -fd

# Descartar mudanças em arquivo específico
git checkout -- path/to/file.tsx

# Descartar todas mudanças unstaged
git checkout -- .
```

### Tags
```bash
# Criar tag
git tag v1.0.0

# Criar tag anotada (recomendado)
git tag -a v1.0.0 -m "Versão 1.0.0"

# Push tags
git push origin --tags

# Listar tags
git tag -l "v1.*"
```

### Remote
```bash
# Ver remotes
git remote -v

# Adicionar remote
git remote add upstream https://github.com/org/repo.git

# Buscar atualizações sem merge
git fetch origin

# Fetch + merge
git pull origin main

# Push forçando (cuidado!)
git push --force-with-lease  # Mais seguro que --force
```

---

## 9. WORKFLOWS COMUNS

### Feature Branch Workflow
```bash
# 1. Atualizar main
git checkout main
git pull origin main

# 2. Criar feature branch
git checkout -b feature/nova-funcionalidade

# 3. Desenvolver e commitar
git add .
git commit -m "feat: implementa X"

# 4. Manter atualizada com main
git fetch origin
git rebase origin/main

# 5. Push
git push -u origin feature/nova-funcionalidade

# 6. Criar PR no GitHub
gh pr create --title "feat: nova funcionalidade" --body "..."
```

### Hotfix Workflow
```bash
# 1. Criar branch de hotfix a partir de main
git checkout main
git pull origin main
git checkout -b hotfix/bug-critico

# 2. Fix e commit
git add .
git commit -m "fix: corrige bug crítico"

# 3. Push e merge rápido
git push -u origin hotfix/bug-critico
gh pr create --title "fix: hotfix crítico" --body "..."
```

### Sync com Fork Upstream
```bash
# 1. Adicionar upstream (uma vez)
git remote add upstream https://github.com/original/repo.git

# 2. Buscar mudanças
git fetch upstream

# 3. Merge no seu main
git checkout main
git merge upstream/main

# 4. Push para seu fork
git push origin main
```

---

## 10. ALIASES ÚTEIS

Adicionar ao `~/.gitconfig`:

```ini
[alias]
    # Status curto
    s = status -s

    # Log bonito
    lg = log --oneline --graph --all --decorate

    # Último commit
    last = log -1 HEAD --stat

    # Diff staged
    ds = diff --staged

    # Amend sem editar mensagem
    amend = commit --amend --no-edit

    # Undo último commit (soft)
    undo = reset --soft HEAD~1

    # Branches ordenadas por data
    recent = branch --sort=-committerdate --format='%(committerdate:short) %(refname:short)'

    # Stash rápido
    save = stash push -m

    # Pull com rebase
    up = pull --rebase

    # Push force seguro
    pushf = push --force-with-lease
```

---

## Common Mistakes

- Fazer `git push --force` em branch compartilhada
- Commitar arquivos sensíveis (.env, secrets)
- Commits gigantes com múltiplas mudanças
- Mensagens de commit vagas ("fix", "update", "wip")
- Não fazer fetch antes de rebase
- Esquecer de criar branch antes de começar a codar
- Usar `reset --hard` sem pensar

## Regras de Segurança

1. **NUNCA** force push em main/master
2. **NUNCA** commitar secrets/credentials
3. **SEMPRE** revisar diff antes de commit
4. **SEMPRE** usar `--force-with-lease` ao invés de `--force`
5. **SEMPRE** confirmar branch atual antes de operações destrutivas

## Examples

### Commitar apenas parte de um arquivo
```bash
git add -p src/component.tsx
# Seleciona hunks interativamente
git commit -m "feat: adiciona validação de form"
```

### Desfazer último push (branch pessoal)
```bash
git reset --hard HEAD~1
git push --force-with-lease
```

### Mover commits para outra branch
```bash
# Estava em main, deveria estar em feature
git branch feature/nova    # Cria branch no commit atual
git reset --hard HEAD~3    # Volta main 3 commits
git checkout feature/nova  # Vai para feature com os commits
```
