class_name BarraHud
extends Control
## Barra de medalhões no pé da tela (ADR-033) e contador de runas, no lugar
## dos ícones da referência. Provisório até a Fase 5 (medalhão definitivo):
## cada medalhão é um disco na cor do elemento com o símbolo da forma, o
## número da tecla e uma "sombra de relógio" enquanto recarrega.

const TAMANHO := 64.0
const ESPACO := 14.0

var mago: Node = null
var _fonte: Font = null


func _ready() -> void:
	_fonte = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if mago == null:
		return
	var barra: BarraMedalhoes = mago.barra
	var largura := BarraMedalhoes.ESPACOS * TAMANHO + (BarraMedalhoes.ESPACOS - 1) * ESPACO
	var tela := get_viewport_rect().size
	var inicio := Vector2((tela.x - largura) / 2.0, tela.y - TAMANHO - 26.0)
	for i in BarraMedalhoes.ESPACOS:
		var centro := inicio + Vector2(i * (TAMANHO + ESPACO) + TAMANHO / 2.0, TAMANHO / 2.0)
		var raio := TAMANHO / 2.0
		# Moldura de pedra escura, com destaque no espaço selecionado.
		var selecionado: bool = i == mago.espaco_selecionado
		draw_circle(centro, raio + 4.0, Color(1.0, 0.85, 0.4) if selecionado else Color(0.12, 0.1, 0.14, 0.85))
		var medalhao = barra.medalhoes[i]
		if medalhao == null:
			draw_circle(centro, raio, Color(0.2, 0.18, 0.22, 0.7))
		else:
			var cor := Color(medalhao.get("cor", "#ffffff"))
			draw_circle(centro, raio, cor.darkened(0.35))
			draw_circle(centro, raio * 0.78, cor)
			_texto_centrado(medalhao.get("simbolo", "●"), centro + Vector2(0, 9), 28, Color(1, 1, 1, 0.95))
			var fracao := barra.fracao_recarga(i)
			if fracao > 0.0:
				draw_arc(centro, raio * 0.5, -PI / 2.0, -PI / 2.0 + TAU * fracao, 24, Color(0, 0, 0, 0.6), raio)
		_texto_centrado(str(i + 1), centro + Vector2(0, raio + 18.0), 14, Color(1, 1, 1, 0.85))

	# Runas na mochila, no canto, abaixo de vida e mana.
	var contagem := {}
	for r in mago.runas:
		contagem[r] = contagem.get(r, 0) + 1
	var y := 110.0
	draw_string(_fonte, Vector2(16, y), "Runas: %d" % mago.runas.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	for nome in contagem:
		y += 20.0
		var cor: Color = RunaColetavel.CORES.get(nome, Color.WHITE)
		draw_circle(Vector2(24, y - 5), 6.0, cor)
		var rotulo: String = nome
		if mago.livro:
			rotulo = mago.livro.formas.get(nome, mago.livro.elementos.get(nome, {})).get("nome", nome)
		draw_string(_fonte, Vector2(36, y), "%s x%d" % [rotulo, contagem[nome]], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)


func _texto_centrado(texto: String, base: Vector2, tamanho: int, cor: Color) -> void:
	var largura := _fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
	draw_string(_fonte, base - Vector2(largura / 2.0, 0), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor)
