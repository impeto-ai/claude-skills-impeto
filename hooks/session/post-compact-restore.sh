#!/bin/bash
# Hook: post-compact-restore.sh
# Evento: SessionStart | Matcher: compact
# Reinjeta contexto critico apos compact
# Stdout = texto injetado no contexto do Claude

CWD=$(echo "$(cat)" | jq -r '.cwd // empty' 2>/dev/null)
SNAPSHOT="$CWD/.claude/compact-snapshots/latest.md"

cat << 'CONTEXT'
=== POS-COMPACT: CONTEXTO REINJETADO ===
1. RELEIA o CLAUDE.md do projeto antes de continuar
2. NAO assuma o estado dos arquivos — releia antes de editar
3. Verifique TaskList para tarefas pendentes
4. Pergunte: "Onde paramos?" antes de agir
CONTEXT

# Se existe snapshot salvo, injeta tambem
if [ -f "$SNAPSHOT" ]; then
  echo ""
  echo "=== SNAPSHOT DA SESSAO ANTERIOR ==="
  cat "$SNAPSHOT"
fi

exit 0
