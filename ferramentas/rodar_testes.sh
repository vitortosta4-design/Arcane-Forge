#!/bin/bash
# Roda a suíte de testes automáticos sem tela e sai com o código dela
# (0 = tudo passou). Uso: ferramentas/rodar_testes.sh
set -uo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$RAIZ/jogo"

saida="$(timeout 150 godot --headless --path . res://cenas/testes/suite_testes.tscn 2>&1)"
codigo=$?

echo "$saida" | grep -E "FALHOU|SCRIPT ERROR|Parse Error|TODOS OS TESTES|FALHAS:" || echo "$saida" | tail -20
exit $codigo
