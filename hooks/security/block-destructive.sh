#!/bin/bash
# Hook: block-destructive.sh
# Evento: PreToolUse | Matcher: Bash
# Bloqueia comandos destrutivos antes de executar

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

DANGEROUS=(
  "rm -rf"
  "rm -fr"
  "git push.*--force"
  "git push.*-f"
  "git reset --hard"
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE"
  "DELETE FROM.*WHERE 1"
  "DELETE FROM.*WITHOUT"
  "dd if=/dev"
  "mkfs\."
  ":(){.*};:"
  "chmod -R 777"
  "chown -R.*/"
)

for pattern in "${DANGEROUS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "BLOQUEADO: comando destrutivo detectado ($pattern). Execute manualmente se necessario." >&2
    exit 2
  fi
done

exit 0
