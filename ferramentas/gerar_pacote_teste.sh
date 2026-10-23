#!/bin/bash
# Gera o .zip de teste para Windows (jogo exportado + atalhos + roteiro + prompt
# para o Claude de quem testa). Precisa dos modelos de exportação do Godot
# 4.7.2 em ~/.local/share/godot/export_templates/4.7.2.stable/ (aprovado pelo
# Vitor em 23/10/2026; baixar de github.com/godotengine/godot/releases).
# Uso: ferramentas/gerar_pacote_teste.sh [NOME]   (padrão: ArcaneForge_teste_Matheus)
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
NOME="${1:-ArcaneForge_teste_Matheus}"
SAIDA="$RAIZ/build/$NOME"
rm -rf "$SAIDA" "$SAIDA.zip"
mkdir -p "$SAIDA"
cd "$RAIZ/jogo"
godot --headless --export-release "Windows Desktop" "$SAIDA/ArcaneForge.exe" > /dev/null 2>&1
[ -f "$SAIDA/ArcaneForge.pck" ] || { echo "Exportação falhou (faltam os modelos de exportação?)"; exit 1; }
cp "$RAIZ"/ferramentas/pacote_teste/* "$SAIDA/"
cd "$RAIZ/build" && zip -qr "$NOME.zip" "$NOME"
echo "Pacote: $RAIZ/build/$NOME.zip"
