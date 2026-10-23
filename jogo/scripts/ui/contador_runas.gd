class_name ContadorRunas
extends Control
## Runas na mochila, à esquerda da barra de medalhões, como na referência
## (docs/referencias/hud-referencia-01.png): uma pedra de runa com o símbolo
## da última runa pega aceso e o total no canto de baixo. Quais runas são
## aparece na tela da bigorna. Só lê o mago.

const LADO := 44.0
const DISTANCIA_DA_BARRA := 30.0

var mago: Node = null
var _fonte: Font = null


func _ready() -> void:
	_fonte = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# Sem mago o PainelMago e a barra já avisam; aqui só não desenha.
	if mago == null:
		return
	var tela := get_viewport_rect().size
	var primeiro := BarraHud.centro_do_espaco(0, tela)
	var centro := primeiro - Vector2(BarraHud.TAMANHO / 2.0 + DISTANCIA_DA_BARRA + LADO / 2.0, 0)
	var runas: Array = mago.runas
	var nome := str(runas[-1]) if not runas.is_empty() else ""
	var cor: Color = RunaColetavel.CORES.get(nome, Color(0.45, 0.6, 1.0))
	_pedra(centro, cor, nome, not runas.is_empty())
	EstiloHud.texto_centrado(self, _fonte, str(runas.size()), centro + Vector2(LADO * 0.42, LADO * 0.52), 20, Color.WHITE)
	# Separador fino entre o contador e a barra, como na referência.
	var x_sep := primeiro.x - BarraHud.TAMANHO / 2.0 - DISTANCIA_DA_BARRA / 2.0
	draw_line(Vector2(x_sep, centro.y - 26), Vector2(x_sep, centro.y + 26), Color(1, 1, 1, 0.35), 1.5)


## Pedra de runa lascada (contorno torto, como as runas 3D) com o símbolo da
## última runa pega aceso; sem runas, pedra apagada e sem símbolo.
func _pedra(centro: Vector2, cor: Color, nome: String, acesa: bool) -> void:
	var contorno := PackedVector2Array()
	var cantos := [Vector2(-0.42, -0.5), Vector2(0.05, -0.6), Vector2(0.46, -0.42), Vector2(0.5, 0.05),
		Vector2(0.4, 0.5), Vector2(-0.1, 0.56), Vector2(-0.5, 0.4), Vector2(-0.55, -0.1)]
	for c in cantos:
		contorno.append(centro + c * LADO)
	var sombra := contorno.duplicate()
	for i in sombra.size():
		sombra[i] += Vector2(0, 3)
	draw_colored_polygon(sombra, EstiloHud.SOMBRA)
	var pedra := cor.darkened(0.65).lerp(EstiloHud.PEDRA, 0.4) if acesa else EstiloHud.PEDRA
	draw_colored_polygon(contorno, pedra.lightened(0.18))
	var miolo := PackedVector2Array()
	for c in cantos:
		miolo.append(centro + c * LADO * 0.82 + Vector2(0, 1.5))
	draw_colored_polygon(miolo, pedra)
	var fechado := contorno.duplicate()
	fechado.append(contorno[0])
	draw_polyline(fechado, EstiloHud.PEDRA_ESCURA, 1.5, true)
	if acesa and EstiloHud.tem_simbolo(nome):
		EstiloHud.simbolo_runa(self, nome, centro + Vector2(0, 1), LADO * 0.62, cor, pedra)
