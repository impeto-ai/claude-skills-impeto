#!/bin/bash
# Hook: protect-secrets.sh
# Evento: PreToolUse | Matcher: Read|Write|Edit
# Bloqueia acesso a arquivos sensiveis

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0

PROTECTED=(
  ".env"
  ".env.local"
  ".env.production"
  ".env.staging"
  "credentials"
  "secrets"
  ".ssh/id_"
  ".aws/credentials"
  ".kube/config"
  ".pgpass"
  ".my.cnf"
  ".netrc"
  "service-account"
  ".p12"
  ".pfx"
  ".pem"
  ".key"
)

for pattern in "${PROTECTED[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "BLOQUEADO: arquivo protegido ($pattern). Edite manualmente se necessario." >&2
    exit 2
  fi
done

exit 0
