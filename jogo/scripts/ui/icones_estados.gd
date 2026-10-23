class_name IconesEstados
extends Control
## Estados do mago (molhado, queimando...) como ícones redondos logo abaixo
## das barras de vida e mana, como na referência
## (docs/referencias/hud-referencia-01.png). Em primeira pessoa o jogador não
## vê o próprio corpo colorido, então é aqui que ele sabe (ADR-017: feedback
## claro). O HUD só entrega a lista; este nó só desenha.

const RAIO := 16.0
const ESPACO := 38.0
const NOMES := {
	"eletrizado": "Eletrizado",
	"queimando": "Queimando",
	"cego": "Cego",
	"molhado": "Molhado",
	"lento": "Lento",
	"preso": "Preso",
}
const CORES := {
	"eletrizado": Color(1.0, 0.88, 0.25),
	"queimando": Color(1.0, 0.48, 0.1),
	"cego": Color(0.62, 0.38, 0.95),
	"molhado": Color(0.3, 0.65, 1.0),
	"lento": Color(0.45, 0.95, 1.0),
	"preso": Color(0.95, 0.7, 0.3),
}
## Estados que usam o mesmo símbolo de runa da folha do Vitor.
const RUNA_DO_ESTADO := {"queimando": "fogo", "molhado": "agua", "preso": "prende"}

## Nomes internos dos estados ativos, na ordem do controlador.
var nomes: Array = []
var _fonte: Font = null


func _ready() -> void:
	_fonte = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func mostrar(lista: Array) -> void:
	nomes = lista.duplicate()
	visible = not nomes.is_empty()
	queue_redraw()


## Nome legível de cada estado (para testes e para quem quiser ler).
func nomes_legiveis() -> Array:
	return nomes.map(func(n): return NOMES.get(n, n))


func _draw() -> void:
	for i in nomes.size():
		var nome: String = nomes[i]
		var centro := Vector2(RAIO + 2.0 + i * ESPACO, RAIO + 2.0)
		var cor: Color = CORES.get(nome, Color.WHITE)
		draw_circle(centro + Vector2(0, 2), RAIO + 1.5, EstiloHud.SOMBRA)
		draw_circle(centro, RAIO + 1.5, EstiloHud.OURO_ESCURO)
		draw_circle(centro, RAIO, EstiloHud.PEDRA_ESCURA)
		draw_arc(centro, RAIO + 0.5, 0.0, TAU, 32, Color(cor, 0.6), 1.5, true)
		if RUNA_DO_ESTADO.has(nome) and EstiloHud.tem_simbolo(RUNA_DO_ESTADO[nome]):
			EstiloHud.simbolo_runa(self, RUNA_DO_ESTADO[nome], centro, RAIO * 1.35, cor, EstiloHud.PEDRA_ESCURA)
		else:
			_icone(nome, centro, cor)


func _icone(nome: String, c: Vector2, cor: Color) -> void:
	var r := RAIO * 0.62
	match nome:
		"eletrizado":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0.2, -1) * r, c + Vector2(-0.45, 0.1) * r,
				c + Vector2(0.0, 0.1) * r, c + Vector2(-0.2, 1) * r, c + Vector2(0.5, -0.15) * r, c + Vector2(0.05, -0.15) * r]), cor)
		"cego":
			var olho := PackedVector2Array()
			for k in 16:
				var a := TAU * k / 16.0
				olho.append(c + Vector2(cos(a), sin(a) * 0.5) * r)
			draw_colored_polygon(olho, cor)
			draw_circle(c, r * 0.32, EstiloHud.PEDRA_ESCURA)
			draw_line(c + Vector2(-0.9, -0.9) * r, c + Vector2(0.9, 0.9) * r, Color.WHITE, 2.0, true)
		"lento":
			# Espiral de caracol.
			var pts := PackedVector2Array()
			for k in 30:
				var t := k / 29.0
				var a := t * TAU * 1.6
				pts.append(c + Vector2(cos(a), sin(a)) * r * (0.15 + 0.85 * t))
			draw_polyline(pts, cor, 2.2, true)
		_:
			EstiloHud.texto_centrado(self, _fonte, str(NOMES.get(nome, nome)).left(1), c + Vector2(0, 5), 14, cor)
