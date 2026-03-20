#!/bin/bash
# Hook: enforce-readonly.sh
# Evento: PreToolUse | Matcher: Write|Edit
# Garante que agents read-only nao editam arquivos
# Adicione nomes dos seus agents read-only no array READONLY_AGENTS

INPUT=$(cat)
AGENT=$(echo "$INPUT" | jq -r '.agent_type // empty')
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

[ -z "$AGENT" ] && exit 0

READONLY_AGENTS=("researcher" "auditor" "explorer" "analyst" "db-reader" "Explore" "Plan")

for ro_agent in "${READONLY_AGENTS[@]}"; do
  if [[ "$AGENT" == "$ro_agent" ]] && [[ "$TOOL" =~ ^(Write|Edit)$ ]]; then
    echo "BLOQUEADO: agent '$AGENT' e read-only, nao pode usar $TOOL" >&2
    exit 2
  fi
done

exit 0
