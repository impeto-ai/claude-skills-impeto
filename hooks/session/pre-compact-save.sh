#!/bin/bash
# Hook: pre-compact-save.sh
# Evento: PreCompact | Matcher: "" (manual e auto)
# Salva metadado antes do compact

INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.trigger // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Cria diretorio de snapshots se nao existe
SNAPSHOT_DIR="$CWD/.claude/compact-snapshots"
mkdir -p "$SNAPSHOT_DIR" 2>/dev/null

# Salva metadado
cat > "$SNAPSHOT_DIR/meta-$TIMESTAMP.json" << META_EOF
{
  "timestamp": "$TIMESTAMP",
  "trigger": "$SOURCE",
  "cwd": "$CWD"
}
META_EOF

echo "Snapshot salvo antes do compact ($SOURCE)" >&2

exit 0
