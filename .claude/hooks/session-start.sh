#!/bin/bash
# Prepara uma sessão do Claude Code na nuvem para rodar o jogo e os testes:
# instala o Godot 4.7.2 (binário oficial, licença MIT, aprovado pelo Vitor
# em 21/10/2026) e reimporta o projeto, que é o que monta o cache de classes
# (class_name) que os scripts precisam para compilar.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

VERSAO="4.7.2"
PASTA="/opt/godot/${VERSAO}"
BINARIO="${PASTA}/Godot_v${VERSAO}-stable_linux.x86_64"
URL="https://github.com/godotengine/godot/releases/download/${VERSAO}-stable/Godot_v${VERSAO}-stable_linux.x86_64.zip"

if [ ! -x "$BINARIO" ]; then
  mkdir -p "$PASTA"
  ZIP="$(mktemp --suffix=.zip)"
  curl -sSL --retry 4 --retry-delay 2 -o "$ZIP" "$URL"
  unzip -q -o "$ZIP" -d "$PASTA"
  rm -f "$ZIP"
  chmod +x "$BINARIO"
fi

ln -sf "$BINARIO" /usr/local/bin/godot

# Vulkan por software (Mesa lavapipe, licença MIT, aprovado pelo Vitor em
# 13/11/2026): deixa tirar prints no renderizador de verdade (Forward+) com
# ferramentas/tirar_print_forward.sh. Sem ele, luz e cor só aparecem em
# Compatibility, que engana (a caverna da forja estourou em branco por isso).
if [ ! -f /usr/share/vulkan/icd.d/lvp_icd.json ]; then
  (apt-get update -qq && apt-get install -y -qq mesa-vulkan-drivers) > /dev/null 2>&1 \
    || echo "Aviso: não consegui instalar mesa-vulkan-drivers; tirar_print_forward.sh não vai funcionar."
fi

# Reimporta o projeto (sem tela). Sem isso, a primeira execução falha com
# "Identifier not declared" para Validador, Executor etc.
cd "$CLAUDE_PROJECT_DIR/jogo"
timeout 180 godot --headless --editor --quit --path . > /dev/null 2>&1 || true

echo "Godot $(godot --version) pronto."
