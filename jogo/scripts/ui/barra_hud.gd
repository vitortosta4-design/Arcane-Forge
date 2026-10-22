class_name BarraHud
extends Control
## Barra de medalhões no pé da tela, no centro (ADR-033, posição da
## ADR-039), no lugar dos ícones da referência. Só lê a barra do mago.
## Visual 100% provisório de propósito: círculos lisos na cor do elemento,
## cinza quando vazio; o estilo vem de uma referência que o Vitor vai aprovar. Provisório até a Fase 5 (medalhão definitivo):
## cada medalhão é um disco na cor do elemento com o símbolo da forma, o
## número da tecla e uma "sombra de relógio" enquanto recarrega.

const TAMANHO := 64.0
const ESPACO := 14.0

## Distância do pé da tela até a base dos medalhões (o número da tecla fica
## embaixo deles). O aviso de interação do HUD fica logo acima disto.
const MARGEM_BAIXO := 36.0
const COR_LIVRE := Color(0.2, 0.2, 0.22, 0.85)
const COR_PLACA := Color(0.15, 0.15, 0.17, 0.8)

var mago: Node = null
var _fonte: Font = null
var _avisou := false
## O HUD nasce e só depois o mago é ligado (no mesmo quadro ou no seguinte);
## só é problema se continuar sem mago depois de um tempinho.
var _vivo_s := 0.0


func _ready() -> void:
	_fonte = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_vivo_s += delta
	queue_redraw()


func _draw() -> void:
	if mago == null or mago.get("barra") == null:
		if not _avisou and _vivo_s > 1.0:
			push_warning("BarraHud: sem mago ou sem barra de medalhões configurada; a barra 1 a 4 não aparece.")
			_avisou = true
		return
	var barra: BarraMedalhoes = mago.barra
	var largura := BarraMedalhoes.ESPACOS * TAMANHO + (BarraMedalhoes.ESPACOS - 1) * ESPACO
	var tela := get_viewport_rect().size
	var inicio := Vector2((tela.x - largura) / 2.0, tela.y - TAMANHO - MARGEM_BAIXO)
	for i in BarraMedalhoes.ESPACOS:
		var centro := inicio + Vector2(i * (TAMANHO + ESPACO) + TAMANHO / 2.0, TAMANHO / 2.0)
		var raio := TAMANHO / 2.0
		var selecionado: bool = i == mago.espaco_selecionado
		# Selecionado: só um contorno branco liso, para ler qual está na mão.
		if selecionado:
			draw_arc(centro, raio + 4.0, 0.0, TAU, 48, Color.WHITE, 3.0)
		var medalhao = barra.medalhoes[i]
		if medalhao == null:
			# Espaço livre: cinza translúcido, mais claro que o fundo do jogo.
			draw_circle(centro, raio, COR_LIVRE)
			draw_arc(centro, raio, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 1.5)
		else:
			var cor := Color(medalhao.get("cor", "#ffffff"))
			var fracao := barra.fracao_recarga(i)
			if fracao <= 0.0:
				draw_circle(centro, raio, cor)
				_texto_centrado(medalhao.get("simbolo", "●"), centro + Vector2(0, 9), 28, Color.WHITE)
			else:
				# Recarga: o medalhão fica apagado (ainda dá para ver qual é), a
				# parte já recarregada volta a ter cor, como um relógio
				# enchendo, e os segundos que faltam ficam grandes no meio.
				draw_circle(centro, raio, cor.darkened(0.6))
				if fracao < 1.0:
					draw_colored_polygon(_setor(centro, raio, 1.0 - fracao), cor)
				_texto_centrado(medalhao.get("simbolo", "●"), centro + Vector2(0, 9), 28, Color(1, 1, 1, 0.35))
				var segundos := ceili(fracao * float(medalhao.get("recarga_s", 1.0)))
				_texto_centrado(str(segundos), centro + Vector2(0, 11), 30, Color.WHITE)
		# Número da tecla logo abaixo.
		draw_rect(Rect2(centro + Vector2(-11, raio + 7.0), Vector2(22, 20)), COR_PLACA)
		_texto_centrado(str(i + 1), centro + Vector2(0, raio + 22.0), 14, Color.WHITE)


## Fatia de pizza a partir do topo, no sentido horário, cobrindo a fração dada.
func _setor(centro: Vector2, raio: float, fracao: float) -> PackedVector2Array:
	var pontos := PackedVector2Array([centro])
	var passos := maxi(3, ceili(40 * fracao))
	for k in passos + 1:
		var angulo := -PI / 2.0 + TAU * fracao * k / passos
		pontos.append(centro + Vector2(cos(angulo), sin(angulo)) * raio)
	return pontos


func _texto_centrado(texto: String, base: Vector2, tamanho: int, cor: Color) -> void:
	var largura := _fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
	draw_string_outline(_fonte, base - Vector2(largura / 2.0, 0), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, 4, Color(0, 0, 0, 0.7))
	draw_string(_fonte, base - Vector2(largura / 2.0, 0), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor)
