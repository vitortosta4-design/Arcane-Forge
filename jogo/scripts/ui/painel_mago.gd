class_name PainelMago
extends Control
## Canto superior esquerdo do HUD (ADR-039): retrato do mago com vida e mana
## ao lado e, logo abaixo, as runas carregadas. Só LÊ o mago; nunca mexe em
## vida, mana ou runas.
## Visual 100% provisório de propósito (pedido do Vitor, 22/10/2026): formas
## lisas em cinza e nas cores dos elementos, sem moldura nem ornamento. O
## estilo vem depois, de uma referência que o Vitor ainda vai aprovar. Aqui só
## importam posição, tamanho e legibilidade.

const COR_RETRATO := Color(0.3, 0.22, 0.58) # roxo do manto, placeholder
const COR_FUNDO := Color(0.15, 0.15, 0.17, 0.75)
const COR_VAZIO := Color(0.32, 0.32, 0.35, 0.9)
const COR_VIDA := Color(0.85, 0.22, 0.22)
const COR_MANA := Color(0.24, 0.5, 0.95)
const RAIO_RETRATO := 34.0
const CENTRO_RETRATO := Vector2(38, 38)
const BARRA_X := 84.0
const BARRA_LARGURA := 220.0
const ALTURA_RUNAS := 82.0

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
	if mago == null:
		if not _avisou and _vivo_s > 1.0:
			push_warning("PainelMago: nenhum mago configurado; retrato, vida, mana e runas não aparecem.")
			_avisou = true
		return
	draw_circle(CENTRO_RETRATO, RAIO_RETRATO, COR_RETRATO)
	_barra(Vector2(BARRA_X, 14), 22.0, float(mago.vida_atual), float(mago.vida_maxima), COR_VIDA)
	_barra(Vector2(BARRA_X, 44), 16.0, float(mago.mana_atual), float(mago.mana_maxima), COR_MANA)
	_runas()


func _barra(pos: Vector2, altura: float, atual: float, maxima: float, cor: Color) -> void:
	var fracao := clampf(atual / maxima, 0.0, 1.0) if maxima > 0.0 else 0.0
	draw_rect(Rect2(pos, Vector2(BARRA_LARGURA, altura)), COR_VAZIO)
	draw_rect(Rect2(pos, Vector2(BARRA_LARGURA * fracao, altura)), cor)
	var texto := "%d/%d" % [roundi(atual), roundi(maxima)]
	var tamanho := 13 if altura < 20.0 else 15
	var largura := _fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
	_texto(pos + Vector2((BARRA_LARGURA - largura) / 2.0, altura / 2.0 + tamanho * 0.36), texto, tamanho)


## Runas na mochila, logo abaixo das barras, sempre numa linha só: uma
## etiqueta por tipo, com bolinha na cor da runa e a quantidade. Se não
## couber com os nomes, fica só bolinha e número (o crítico reprovou a quebra
## de linha, que invadia o lugar dos estados).
func _runas() -> void:
	var contagem := {}
	for r in mago.runas:
		contagem[r] = contagem.get(r, 0) + 1
	var textos := {}
	var largura_total := 0.0
	for nome in contagem:
		var rotulo: String = nome
		if mago.livro:
			rotulo = mago.livro.formas.get(nome, mago.livro.elementos.get(nome, {})).get("nome", nome)
		textos[nome] = "%s x%d" % [rotulo, contagem[nome]] if contagem[nome] > 1 else rotulo
		largura_total += _fonte.get_string_size(textos[nome], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 34.0
	var x := _etiqueta(BARRA_X, ALTURA_RUNAS, "Runas: %d" % mago.runas.size(), Color(0, 0, 0, 0)) + 4.0
	var compacto := x + largura_total > size.x
	for nome in contagem:
		var texto: String = str(contagem[nome]) if compacto else textos[nome]
		x = _etiqueta(x, ALTURA_RUNAS, texto, RunaColetavel.CORES.get(nome, Color.WHITE)) + 4.0


## Etiqueta lisa (com bolinha de cor, se tiver); devolve onde ela termina.
func _etiqueta(x: float, y: float, texto: String, cor: Color) -> float:
	var com_cor := cor.a > 0.0
	var largura := _fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + (30.0 if com_cor else 14.0)
	draw_rect(Rect2(Vector2(x, y), Vector2(largura, 22)), COR_FUNDO)
	if com_cor:
		draw_circle(Vector2(x + 11, y + 11), 6.0, cor)
	_texto(Vector2(x + (21.0 if com_cor else 7.0), y + 16), texto, 14)
	return x + largura


func _texto(base: Vector2, texto: String, tamanho: int) -> void:
	draw_string_outline(_fonte, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, 4, Color(0, 0, 0, 0.7))
	draw_string(_fonte, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, Color.WHITE)
