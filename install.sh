#!/bin/bash
# ImpetOS Skills — Instalador Global
# Uso: curl -fsSL https://raw.githubusercontent.com/impeto-ai/claude-skills-impeto/main/install.sh | bash
#
# O que faz:
#   1. Clona o repo em ~/.claude/impeto-skills/
#   2. Copia skills, agents e hooks pra ~/.claude/ (sem sobrescrever)
#   3. Configura o hook do skill-activator no settings.json
#
# Pra atualizar: ~/.claude/impeto-skills/install.sh --update

set -e

REPO="https://github.com/impeto-ai/claude-skills-impeto.git"
INSTALL_DIR="$HOME/.claude/impeto-skills"
CLAUDE_DIR="$HOME/.claude"

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
# 2. Criar pastas se nao existem
# -------------------------------------------------------
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/agents"
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
# 4. Copiar skills (sem sobrescrever existentes)
# -------------------------------------------------------
echo "[2/5] Instalando skills..."
SKILLS_NEW=0
SKILLS_SKIP=0

for skill_dir in "$INSTALL_DIR/skills"/*/; do
  skill_name=$(basename "$skill_dir")
  target="$CLAUDE_DIR/skills/$skill_name"

  if [ -d "$target" ] || [ -L "$target" ]; then
    SKILLS_SKIP=$((SKILLS_SKIP + 1))
  else
    cp -r "$skill_dir" "$target"
    SKILLS_NEW=$((SKILLS_NEW + 1))
  fi
done

echo "   $SKILLS_NEW novas | $SKILLS_SKIP ja existiam"

# -------------------------------------------------------
# 5. Copiar agents (sem sobrescrever existentes)
# -------------------------------------------------------
echo "[3/5] Instalando agents..."
AGENTS_NEW=0

if [ -d "$INSTALL_DIR/agents" ]; then
  for agent_file in "$INSTALL_DIR/agents"/*.md; do
    [ -f "$agent_file" ] || continue
    agent_name=$(basename "$agent_file")
    target="$CLAUDE_DIR/agents/$agent_name"

    if [ -f "$target" ]; then
      echo "   SKIP: $agent_name (ja existe)"
    else
      cp "$agent_file" "$target"
      AGENTS_NEW=$((AGENTS_NEW + 1))
      echo "   + $agent_name"
    fi
  done
fi

echo "   $AGENTS_NEW agents instalados"

# -------------------------------------------------------
# 6. Copiar hooks (com backup se existir)
# -------------------------------------------------------
echo "[4/7] Instalando hooks base..."

for hook_file in "$INSTALL_DIR/hooks"/*; do
  [ -f "$hook_file" ] || continue
  hook_name=$(basename "$hook_file")
  target="$CLAUDE_DIR/hooks/$hook_name"

  if [ -f "$target" ]; then
    cp "$target" "$CLAUDE_DIR/backups/${hook_name}.bak.$(date +%Y%m%d%H%M%S)"
    echo "   ~ $hook_name (backup + atualizado)"
  else
    echo "   + $hook_name"
  fi

  cp "$hook_file" "$target"
done

# -------------------------------------------------------
# 7. Copiar hooks de seguranca
# -------------------------------------------------------
echo "[5/7] Instalando hooks de seguranca..."

for hook_file in "$INSTALL_DIR/hooks/security"/*.sh; do
  [ -f "$hook_file" ] || continue
  hook_name=$(basename "$hook_file")
  target="$CLAUDE_DIR/hooks/$hook_name"

  if [ -f "$target" ]; then
    echo "   SKIP: $hook_name (ja existe)"
  else
    cp "$hook_file" "$target"
    echo "   + $hook_name"
  fi
done

# -------------------------------------------------------
# 8. Copiar hooks de sessao
# -------------------------------------------------------
echo "[6/7] Instalando hooks de sessao..."

for hook_file in "$INSTALL_DIR/hooks/session"/*.sh; do
  [ -f "$hook_file" ] || continue
  hook_name=$(basename "$hook_file")
  target="$CLAUDE_DIR/hooks/$hook_name"

  if [ -f "$target" ]; then
    echo "   SKIP: $hook_name (ja existe)"
  else
    cp "$hook_file" "$target"
    echo "   + $hook_name"
  fi
done

chmod +x "$CLAUDE_DIR/hooks"/*.sh 2>/dev/null

# -------------------------------------------------------
# 9. Configurar settings.json com TODOS os hooks
# -------------------------------------------------------
echo "[7/7] Configurando settings.json..."

SETTINGS="$CLAUDE_DIR/settings.json"

# Configuracao completa de hooks
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
  # Backup
  cp "$SETTINGS" "$CLAUDE_DIR/backups/settings.json.bak.$(date +%Y%m%d%H%M%S)"

  # Merge hooks no settings existente
  echo "$HOOKS_CONFIG" | jq -s '.[0] * .[1]' "$SETTINGS" - > "${SETTINGS}.tmp"
  mv "${SETTINGS}.tmp" "$SETTINGS"
  echo "   Hooks mergeados no settings.json existente"
else
  echo "$HOOKS_CONFIG" > "$SETTINGS"
  echo "   settings.json criado com hooks completos"
fi

# -------------------------------------------------------
# Done
# -------------------------------------------------------
TOTAL_SKILLS=$(ls -d "$CLAUDE_DIR/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')
TOTAL_AGENTS=$(ls "$CLAUDE_DIR/agents"/*.md 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "  Instalacao completa!"
echo ""
echo "  Skills:    $TOTAL_SKILLS"
echo "  Agents:    $TOTAL_AGENTS"
echo "  Hooks:"
echo "    Seguranca: block-destructive, protect-secrets, enforce-readonly"
echo "    Sessao:    session-setup, post-compact-restore, pre-compact-save"
echo "    Skills:    skill-activator + skill-triggers.json"
echo ""
echo "  Para atualizar:"
echo "    cd ~/.claude/impeto-skills && git pull && bash install.sh"
echo ""
echo "  Teste agora no Claude Code:"
echo "    'forge skill'    -> cria nova skill"
echo "    'monta um time'  -> agent teams manager"
echo ""
