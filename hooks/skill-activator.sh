#!/bin/bash
# Skill Activator v2 — Config-driven (substituiu monolito de 460+ linhas)
# Lê triggers de skill-triggers.json, faz match por regex, injeta contexto.
# Apenas skills que PRECISAM de enforcement estão aqui.
# As demais confiam no sistema nativo de description do Claude Code.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRIGGERS="$SCRIPT_DIR/skill-triggers.json"

# Ler prompt do stdin
input=$(cat)
prompt=$(echo "$input" | jq -r '.userMessage // ""')
prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

# Se não tem triggers.json, sai silencioso
if [ ! -f "$TRIGGERS" ]; then
  exit 0
fi

# Iterar skills por prioridade (já ordenado no JSON)
matched=$(echo "$prompt_lower" | python3 -c "
import sys, json, re

prompt = sys.stdin.read().strip()
if not prompt:
    sys.exit(0)

try:
    with open('$TRIGGERS') as f:
        config = json.load(f)
except:
    sys.exit(0)

# Ordenar por prioridade
skills = sorted(config.get('skills', []), key=lambda s: s.get('priority', 99))

for skill in skills:
    pattern = skill.get('pattern', '')
    if not pattern:
        continue
    try:
        if re.search(pattern, prompt, re.IGNORECASE):
            name = skill['name']
            path = skill.get('path', f'~/.claude/skills/{name}/SKILL.md')
            enforce = skill.get('enforce', '')
            chain = skill.get('chain', '')

            parts = [
                f'ACTIVATE SKILL: {name}',
                f'READ: {path}',
                f'FOLLOW: {enforce}' if enforce else '',
                f'CHAIN: After completion -> {chain}' if chain else '',
                f'OUTPUT: ⚡ SKILL_ACTIVATED: {name.upper()}'
            ]
            context = '\\n'.join(p for p in parts if p)

            result = {
                'hookSpecificOutput': {
                    'hookEventName': 'UserPromptSubmit',
                    'additionalContext': f'<skill-instruction>\\n{context}\\n</skill-instruction>'
                }
            }
            print(json.dumps(result))
            sys.exit(0)
    except re.error:
        continue

sys.exit(0)
")

if [ -n "$matched" ]; then
  echo "$matched"
fi

exit 0
