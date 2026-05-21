#!/bin/bash
# ImpetOS Skills — Instalador Global (essenciais)
# Uso: curl -fsSL https://raw.githubusercontent.com/impeto-ai/claude-skills-impeto/main/install.sh | bash
#
# Instala apenas skills essenciais pro time.
# Skills extras ficam no repo pra quem quiser instalar manualmente.

set -e

REPO="https://github.com/impeto-ai/claude-skills-impeto.git"
INSTALL_DIR="$HOME/.claude/impeto-skills"
CLAUDE_DIR="$HOME/.claude"

# -------------------------------------------------------
# Skills essenciais (whitelist)
# -------------------------------------------------------
ESSENTIAL_SKILLS=(
  # Meta / Construtores
  "forge"
  "agent-teams-manager"
  "skill-creator"
  "dispatching-parallel-agents"

  # Linear (gestão de projetos)
  "linear-init"
  "linear-pm"
  "linear-work"

  # Dev Workflow
  "systematic-debugging"
  "clean-code"
  "writing-plans"
  "executing-plans"
  "verification-before-completion"
  "test-driven-development"

  # Git
  "git-specialist"
  "finishing-a-development-branch"

  # Code Review
  "code-reviewer"
  "requesting-code-review"
  "receiving-code-review"

  # Next.js
  "nextjs-architect"

  # Infra
  "database-migrations"
  "security-hardening"
  "ci-cd-pipeline"
  "docker-optimizer"

  # Testes
  "testing-strategy"
  "playwright-e2e-testing"
  "qa-validator"

  # API
  "api-design"

  # Brainstorming
  "brainstorming"
  "brainstorming-dev"
)

echo ""
echo "  ImpetOS Skills Installer"
echo "  ========================"
echo ""

# -------------------------------------------------------
# 1. Verificar dependencias
# -------------------------------------------------------
if ! command -v git &>/dev/null; then
  echo "ERRO: git nao encontrado. Instale git primeiro."
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "AVISO: jq nao encontrado. Instalando..."
  if command -v brew &>/dev/null; then
    brew install jq
  elif command -v apt-get &>/dev/null; then
    sudo apt-get install -y jq
  else
    echo "ERRO: Instale jq manualmente (https://jqlang.github.io/jq/download/)"
    exit 1
  fi
fi

# -------------------------------------------------------
# 2. Criar pastas
# -------------------------------------------------------
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/backups"

# -------------------------------------------------------
# 3. Clonar ou atualizar o repo
# -------------------------------------------------------
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "[1/5] Atualizando repo..."
  cd "$INSTALL_DIR" && git pull --quiet
else
  echo "[1/5] Clonando repo..."
  git clone --quiet "$REPO" "$INSTALL_DIR"
fi

# -------------------------------------------------------
# 4. Copiar apenas skills essenciais
# -------------------------------------------------------
echo "[2/5] Instalando skills essenciais..."
SKILLS_NEW=0
SKILLS_SKIP=0

for skill_name in "${ESSENTIAL_SKILLS[@]}"; do
  source_dir="$INSTALL_DIR/skills/$skill_name"
  target="$CLAUDE_DIR/skills/$skill_name"

  if [ ! -d "$source_dir" ]; then
    echo "   AVISO: $skill_name nao encontrada no repo"
    continue
  fi

  if [ -d "$target" ] || [ -L "$target" ]; then
    SKILLS_SKIP=$((SKILLS_SKIP + 1))
  else
    cp -r "$source_dir" "$target"
    SKILLS_NEW=$((SKILLS_NEW + 1))
  fi
done

echo "   $SKILLS_NEW novas | $SKILLS_SKIP ja existiam"
echo "   (${#ESSENTIAL_SKILLS[@]} skills essenciais, $(ls -d "$INSTALL_DIR/skills"/*/ 2>/dev/null | wc -l | tr -d ' ') disponiveis no repo)"

# -------------------------------------------------------
# 5. Copiar hooks (seguranca + sessao)
# -------------------------------------------------------
echo "[3/5] Instalando hooks..."

# Base (activator + triggers)
for hook_file in "$INSTALL_DIR/hooks"/*; do
  [ -f "$hook_file" ] || continue
  hook_name=$(basename "$hook_file")
  target="$CLAUDE_DIR/hooks/$hook_name"

  if [ -f "$target" ]; then
    cp "$target" "$CLAUDE_DIR/backups/${hook_name}.bak.$(date +%Y%m%d%H%M%S)"
  fi
  cp "$hook_file" "$target"
done

# Seguranca
for hook_file in "$INSTALL_DIR/hooks/security"/*.sh; do
  [ -f "$hook_file" ] || continue
  hook_name=$(basename "$hook_file")
  target="$CLAUDE_DIR/hooks/$hook_name"
  [ -f "$target" ] || cp "$hook_file" "$target"
done

# Sessao
for hook_file in "$INSTALL_DIR/hooks/session"/*.sh; do
  [ -f "$hook_file" ] || continue
  hook_name=$(basename "$hook_file")
  target="$CLAUDE_DIR/hooks/$hook_name"
  [ -f "$target" ] || cp "$hook_file" "$target"
done

chmod +x "$CLAUDE_DIR/hooks"/*.sh 2>/dev/null
echo "   Hooks instalados (seguranca + sessao + activator)"

# -------------------------------------------------------
# 6. Configurar settings.json
# -------------------------------------------------------
echo "[4/5] Configurando settings.json..."

SETTINGS="$CLAUDE_DIR/settings.json"

HOOKS_CONFIG='{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/skill-activator.sh" }]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/block-destructive.sh" }]
      },
      {
        "matcher": "Read|Write|Edit",
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/protect-secrets.sh" }]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/enforce-readonly.sh" }]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/session-setup.sh" }]
      },
      {
        "matcher": "compact",
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/post-compact-restore.sh" }]
      }
    ],
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/pre-compact-save.sh" }]
      }
    ]
  }
}'

if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$CLAUDE_DIR/backups/settings.json.bak.$(date +%Y%m%d%H%M%S)"
  echo "$HOOKS_CONFIG" | jq -s '.[0] * .[1]' "$SETTINGS" - > "${SETTINGS}.tmp"
  mv "${SETTINGS}.tmp" "$SETTINGS"
  echo "   Hooks mergeados no settings.json existente"
else
  echo "$HOOKS_CONFIG" > "$SETTINGS"
  echo "   settings.json criado"
fi

# -------------------------------------------------------
# 5. Resumo
# -------------------------------------------------------
TOTAL_SKILLS=$(ls -d "$CLAUDE_DIR/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "[5/5] Instalacao completa!"
echo ""
echo "  Skills essenciais: ${#ESSENTIAL_SKILLS[@]}"
echo "  Skills total:      $TOTAL_SKILLS"
echo "  Hooks:             seguranca + sessao + activator"
echo ""
echo "  Categorias instaladas:"
echo "    Meta:       forge, agent-teams-manager, skill-creator"
echo "    Linear:     linear-init, linear-pm, linear-work (+ _linear-shared)"
echo "    Workflow:   debugging, clean-code, tdd, plans, verification"
echo "    Git:        git-specialist, finishing-branch"
echo "    Review:     code-reviewer, requesting, receiving"
echo "    Next.js:    nextjs-architect"
echo "    Infra:      database-migrations, security, ci-cd, docker"
echo "    Testes:     testing-strategy, playwright-e2e"
echo ""
echo "  Skills extras (instalar manualmente se precisar):"
echo "    cp ~/.claude/impeto-skills/skills/{nome} ~/.claude/skills/"
echo "    Disponiveis: golang-*, pai-*, sgi-*, remotion-*, business, etc."
echo ""
echo "  Atualizar:"
echo "    cd ~/.claude/impeto-skills && git pull && bash install.sh"
echo ""
echo "  Testar:"
echo "    'forge skill'              -> cria nova skill"
echo "    'monta um time'            -> agent teams"
echo "    'minhas tasks linear'      -> linear work"
echo ""
