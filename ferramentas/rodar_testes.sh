#!/bin/bash
# Roda a suíte de testes automáticos sem tela e sai com o código dela
# (0 = tudo passou). Uso: ferramentas/rodar_testes.sh
set -uo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$RAIZ/jogo"

saida="$(timeout 40 godot --headless --path . res://cenas/testes/suite_testes.tscn 2>&1)"
codigo=$?

echo "$saida" | grep -E "FALHOU|SCRIPT ERROR|Parse Error|TODOS OS TESTES|FALHAS:" || echo "$saida" | tail -20
if [ $codigo -eq 124 ]; then
  echo "Tempo esgotado (a suíte leva uns 6 s): quase sempre é erro de compilação acima."
fi
exit $codigo
