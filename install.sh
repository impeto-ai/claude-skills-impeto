#!/bin/bash
# ImpetOS Skills - Instalador Automático
# Uso: curl -fsSL https://raw.githubusercontent.com/impeto-ai/claude-skills-impeto/main/install.sh | bash

set -e

REPO="https://github.com/impeto-ai/claude-skills-impeto.git"
CLAUDE_DIR=".claude"

echo "⚡ ImpetOS Skills Installer"
echo "=========================="

# Verifica se está em um projeto com .claude
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "📁 Criando pasta .claude..."
    mkdir -p "$CLAUDE_DIR"
fi

# Baixa o repo
echo "📥 Baixando skills..."
TMP_DIR=$(mktemp -d)
git clone --depth 1 "$REPO" "$TMP_DIR" 2>/dev/null

# Copia skills e hooks
echo "📦 Instalando 45 skills..."
cp -r "$TMP_DIR/skills" "$CLAUDE_DIR/"
cp -r "$TMP_DIR/hooks" "$CLAUDE_DIR/"

# Limpa temp
rm -rf "$TMP_DIR"

# Configura settings.json
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
HOOK_CONFIG='{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [{
          "type": "command",
          "command": "bash .claude/hooks/skill-activator.sh"
        }]
      }
    ]
  }
}'

if [ -f "$SETTINGS_FILE" ]; then
    echo "⚙️  Atualizando settings.json..."
    # Verifica se já tem o hook
    if grep -q "skill-activator.sh" "$SETTINGS_FILE" 2>/dev/null; then
        echo "✓ Hook já configurado"
    else
        # Faz backup e merge
        cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"

        # Tenta merge com jq, senão sobrescreve
        if command -v jq &> /dev/null; then
            jq -s '.[0] * .[1]' "$SETTINGS_FILE" <(echo "$HOOK_CONFIG") > "$SETTINGS_FILE.tmp"
            mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        else
            # Sem jq, adiciona manualmente se for JSON simples
            echo "$HOOK_CONFIG" > "$SETTINGS_FILE"
            echo "⚠️  settings.json sobrescrito (instale jq para merge)"
        fi
    fi
else
    echo "⚙️  Criando settings.json..."
    echo "$HOOK_CONFIG" > "$SETTINGS_FILE"
fi

# Torna hook executável
chmod +x "$CLAUDE_DIR/hooks/skill-activator.sh"

echo ""
echo "✅ ImpetOS Skills instalado com sucesso!"
echo ""
echo "📊 45 skills em 6 tiers:"
echo "   TIER 1: Core Development (5)"
echo "   TIER 2: Collaboration (4)"
echo "   TIER 3: Git/DevOps (3)"
echo "   TIER 4: AI Agents (11)  ← NEW: agent-tracing-langfuse"
echo "   TIER 5: Development (11)"
echo "   TIER 6: Business (11)"
echo ""
echo "🚀 Teste agora! Digite no Claude Code:"
echo "   'tenho um bug' → systematic-debugging"
echo "   'criar proposta' → proposal-builder"
echo ""
