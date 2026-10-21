#!/bin/bash
# Confere a sintaxe da função do Supabase (supabase/functions/interpretar-magia)
# sem precisar do Deno: o Node lê o arquivo inteiro e só para quando chega na
# parte que existe apenas no Supabase. Rodar antes de cada deploy.
set -uo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
TEMP="$(mktemp --suffix=.mts)"
sed 's#^import .*##' "$RAIZ/supabase/functions/interpretar-magia/index.ts" > "$TEMP"
saida="$(node --experimental-strip-types "$TEMP" 2>&1)"
rm -f "$TEMP"
if echo "$saida" | grep -q "ReferenceError: Deno is not defined"; then
  echo "Sintaxe ok."
  exit 0
fi
echo "$saida" | grep -vE "ExperimentalWarning|--trace-warnings" | head -10
exit 1
