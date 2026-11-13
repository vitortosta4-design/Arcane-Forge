#!/bin/bash
# Print do jogo no renderizador DE VERDADE (Forward+, o mesmo do PC do Vitor),
# sem placa de vídeo: usa o Vulkan por software do Mesa (lavapipe).
#
# Por que existe: o tirar_print.sh renderiza em Compatibility, que acende no
# máximo 8 luzes por malha e não tem brilho (glow). Luz e cor calibradas por
# ele estouraram em branco no jogo de verdade (caverna da forja, 13/11/2026).
# Tudo que for luz, cor, brilho ou névoa se confere por AQUI.
#
# Precisa do pacote mesa-vulkan-drivers (Mesa, licença MIT), só na máquina da
# nuvem: apt-get update && apt-get install -y mesa-vulkan-drivers
# Leva uns 40 s por print. O FPS daqui não vale nada.
#
# Uso: ferramentas/tirar_print_forward.sh SAIDA.png [mesmas opções do tirar_print.sh]
set -uo pipefail

if [ $# -lt 1 ]; then
  sed -n '2,15p' "$0"
  exit 1
fi
ICD=/usr/share/vulkan/icd.d/lvp_icd.json
if [ ! -f "$ICD" ]; then
  echo "Falta o Vulkan por software (lavapipe). Instale: apt-get update && apt-get install -y mesa-vulkan-drivers"
  exit 1
fi

SAIDA="$(realpath -m "$1")"
shift
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
if ! pgrep -x Xvfb > /dev/null; then
  Xvfb :99 -screen 0 1280x720x24 > /dev/null 2>&1 &
  sleep 2
fi
cd "$RAIZ/jogo"
DISPLAY=:99 VK_ICD_FILENAMES="$ICD" timeout 300 godot --rendering-driver vulkan --rendering-method forward_plus --path . \
  --script res://scripts/ferramentas/tirar_print.gd -- --saida "$SAIDA" "$@" > /tmp/tirar_print_forward.log 2>&1
codigo=$?
grep -E "SCRIPT ERROR|SHADER ERROR|Parse Error|PRINT SALVO" /tmp/tirar_print_forward.log
if [ ! -f "$SAIDA" ]; then
  echo "Print não foi gerado. Log completo em /tmp/tirar_print_forward.log"
  exit 1
fi
exit $codigo
