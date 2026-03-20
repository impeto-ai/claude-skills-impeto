#!/bin/bash
# Hook: session-setup.sh
# Evento: SessionStart | Matcher: startup
# Setup inicial de sessao — injeta contexto base
# Stdout = texto injetado no contexto do Claude

CWD=$(echo "$(cat)" | jq -r '.cwd // empty' 2>/dev/null)

# Detecta projeto pelo CLAUDE.md ou package.json
PROJECT_NAME=""
if [ -f "$CWD/package.json" ]; then
  PROJECT_NAME=$(cat "$CWD/package.json" | jq -r '.name // empty' 2>/dev/null)
elif [ -f "$CWD/CLAUDE.md" ]; then
  PROJECT_NAME=$(head -1 "$CWD/CLAUDE.md" | sed 's/^#\s*//')
fi

if [ -n "$PROJECT_NAME" ]; then
  echo "Sessao iniciada no projeto: $PROJECT_NAME"
fi

# Se tem compact snapshot anterior, avisa
SNAPSHOT="$CWD/.claude/compact-snapshots/latest.md"
if [ -f "$SNAPSHOT" ]; then
  SNAPSHOT_DATE=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$SNAPSHOT" 2>/dev/null || stat -c "%y" "$SNAPSHOT" 2>/dev/null | cut -d. -f1)
  echo "Existe snapshot de sessao anterior ($SNAPSHOT_DATE). Leia se precisar de contexto."
fi

exit 0
