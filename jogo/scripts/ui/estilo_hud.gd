class_name EstiloHud
extends RefCounted
## Estilo do HUD pela referência aprovada pelo Vitor
## (docs/referencias/hud-referencia-01.png, ADR-039): molduras de pedra
## escura com aro dourado, gemas, barras com ponta cortada e as runas
## desenhadas com os mesmos traços da folha do Vitor usados nas runas 3D.
## Só tem cores e funções de desenho; quem decide o que mostrar são as peças
## do HUD (painel, barra, minimapa, estados).

const OURO := Color(0.86, 0.64, 0.28)
const OURO_CLARO := Color(1.0, 0.86, 0.5)
const OURO_ESCURO := Color(0.45, 0.29, 0.1)
const BRONZE := Color(0.22, 0.13, 0.05)
const PEDRA := Color(0.2, 0.19, 0.24)
const PEDRA_CLARA := Color(0.33, 0.31, 0.37)
const PEDRA_ESCURA := Color(0.09, 0.085, 0.11)
const SOMBRA := Color(0, 0, 0, 0.45)
const VIDA := Color(0.9, 0.16, 0.14)
const VIDA_CLARA := Color(1.0, 0.45, 0.38)
const MANA := Color(0.16, 0.5, 1.0)
const MANA_CLARA := Color(0.5, 0.8, 1.0)

const CAMINHO_SIMBOLOS := "res://dados/simbolos_runas.json"
static var _simbolos: Dictionary = {}
static var _carregou := false


## Aro dourado com cara de metal, como nas molduras da referência: borda de
## bronze escuro por fora, faixa de ouro em degradê (clara em cima, escura
## embaixo) e um chanfro fino por dentro com a luz invertida, que dá o
## volume. "espessura" é a largura do ouro.
static func aro(ci: CanvasItem, centro: Vector2, raio: float, espessura: float, cravos := 0) -> void:
	# Só anéis (nada cheio): o aro é desenhado por cima do miolo.
	ci.draw_arc(centro + Vector2(0, 2.5), raio, 0.0, TAU, 64, SOMBRA, 3.0, true)
	ci.draw_arc(centro, raio - espessura / 2.0, 0.0, TAU, 64, BRONZE, espessura + 3.0, true)
	var segmentos := 40
	for k in segmentos:
		var a0 := TAU * k / segmentos
		var a1 := TAU * (k + 1) / segmentos + 0.01
		var luz := _luz((a0 + a1) / 2.0)
		# Faixa principal: escura embaixo, viva no meio, quase branca em cima.
		var tom := OURO_ESCURO.lerp(OURO, clampf(luz * 1.6, 0.0, 1.0)).lerp(OURO_CLARO, clampf(luz * 1.6 - 0.8, 0.0, 1.0))
		ci.draw_arc(centro, raio - espessura * 0.45, a0, a1, 3, tom, espessura * 0.7, true)
		# Chanfro de dentro: luz ao contrário (o lado de baixo pega a luz).
		var chanfro := OURO_ESCURO.lerp(OURO_CLARO, 1.0 - luz)
		ci.draw_arc(centro, raio - espessura * 0.88, a0, a1, 3, chanfro, maxf(1.2, espessura * 0.22), true)
	# Fio de brilho no alto do aro.
	ci.draw_arc(centro, raio - espessura * 0.25, PI * 1.2, PI * 1.8, 24, Color(1, 0.97, 0.85, 0.8), maxf(1.0, espessura * 0.16), true)
	ci.draw_arc(centro, raio - espessura, 0.0, TAU, 64, PEDRA_ESCURA, 1.5, true)
	# Cravos nos pontos cardeais (os "pregos" das molduras da referência).
	for i in cravos:
		var a := -PI / 2.0 + TAU * i / cravos
		var p := centro + Vector2(cos(a), sin(a)) * (raio - espessura / 2.0)
		losango(ci, p, espessura * 0.95, OURO_CLARO, BRONZE)


## Quanta luz recebe um ponto do aro no ângulo a (luz vem de cima).
static func _luz(a: float) -> float:
	return clampf(-sin(a) * 0.5 + 0.5, 0.0, 1.0)


static func losango(ci: CanvasItem, centro: Vector2, meio: float, cor: Color, contorno: Color) -> void:
	var pts := PackedVector2Array([centro + Vector2(0, -meio), centro + Vector2(meio * 0.75, 0),
		centro + Vector2(0, meio), centro + Vector2(-meio * 0.75, 0)])
	ci.draw_colored_polygon(pts, cor)
	var fechado := pts.duplicate()
	fechado.append(pts[0])
	ci.draw_polyline(fechado, contorno, 1.2, true)


## Disco de pedra lapidada (miolo de medalhão, minimapa, espaço vazio):
## facetas em volta, mais claras em cima e mais escuras embaixo.
static func disco_lapidado(ci: CanvasItem, centro: Vector2, raio: float, cor: Color, facetas := 8) -> void:
	ci.draw_circle(centro, raio, cor.darkened(0.35))
	var interno := raio * 0.72
	for i in facetas:
		var a0 := TAU * i / facetas - PI / 2.0 - PI / facetas
		var a1 := a0 + TAU / facetas
		var meio := (a0 + a1) / 2.0
		# Faceta virada para cima recebe luz (sin negativo é para cima na tela).
		var luz := clampf(-sin(meio) * 0.5 + 0.5, 0.0, 1.0)
		var tom := cor.darkened(0.3).lerp(cor.lightened(0.25), luz)
		ci.draw_colored_polygon(PackedVector2Array([
			centro + Vector2(cos(a0), sin(a0)) * raio, centro + Vector2(cos(a1), sin(a1)) * raio,
			centro + Vector2(cos(a1), sin(a1)) * interno, centro + Vector2(cos(a0), sin(a0)) * interno]), tom)
	var mesa := PackedVector2Array()
	for i in facetas:
		var a := TAU * i / facetas - PI / 2.0 - PI / facetas
		mesa.append(centro + Vector2(cos(a), sin(a)) * interno)
	ci.draw_colored_polygon(mesa, cor)


## Barra de vida ou mana com a ponta cortada em diagonal, moldura de metal
## (bronze por fora, ouro em degradê de cima para baixo) e um friso de luz
## em cima, como na referência. "alfa" deixa a barra sumir aos poucos (vida
## dos inimigos).
static func barra(ci: CanvasItem, pos: Vector2, tamanho: Vector2, fracao: float, cor: Color, cor_clara: Color, alfa := 1.0, moldura_fina := false) -> void:
	var c := tamanho.y * 0.55 # quanto a ponta "corta"
	var m := 2.0 if moldura_fina else 3.0
	var a := func(col: Color) -> Color: return Color(col, col.a * alfa)
	ci.draw_colored_polygon(_paralelogramo(pos - Vector2(m, m - 2.0), tamanho + Vector2(m * 2 + 2, m * 2), c + 2), a.call(SOMBRA))
	var moldura := _paralelogramo(pos - Vector2(m, m), tamanho + Vector2(m * 2 + 2, m * 2), c + 2)
	ci.draw_colored_polygon(moldura, a.call(BRONZE))
	# Ouro em degradê: vértices de cima claros, de baixo escuros.
	var ouro := _paralelogramo(pos - Vector2(m - 1, m - 1), tamanho + Vector2(m * 2, m * 2 - 2), c + 1.5)
	ci.draw_polygon(ouro, PackedColorArray([a.call(OURO_CLARO), a.call(OURO_CLARO), a.call(OURO_ESCURO), a.call(OURO_ESCURO)]))
	ci.draw_colored_polygon(_paralelogramo(pos - Vector2(0.5, 0.5), tamanho + Vector2(1, 1), c + 0.5), a.call(PEDRA_ESCURA))
	ci.draw_colored_polygon(_paralelogramo(pos, tamanho, c), a.call(Color(0.12, 0.1, 0.14)))
	var f := clampf(fracao, 0.0, 1.0)
	if f > 0.0:
		var cheio := _paralelogramo(pos, Vector2(maxf(tamanho.x * f, c * 1.2), tamanho.y), c)
		ci.draw_polygon(cheio, PackedColorArray([a.call(cor.lightened(0.1)), a.call(cor.lightened(0.1)), a.call(cor.darkened(0.25)), a.call(cor.darkened(0.25))]))
		var friso := _paralelogramo(pos + Vector2(c * 0.1, 1.5), Vector2(maxf(tamanho.x * f - c * 0.3, c), tamanho.y * 0.3), c * 0.3)
		ci.draw_colored_polygon(friso, a.call(Color(cor_clara, 0.75)))
		# Fio de brilho de esmalte bem no topo (o "vidro" da referência).
		var brilho := _paralelogramo(pos + Vector2(c * 0.15, 1.0), Vector2(maxf(tamanho.x * f - c * 0.6, c * 0.5), maxf(1.5, tamanho.y * 0.12)), c * 0.1)
		ci.draw_colored_polygon(brilho, a.call(Color(1, 1, 1, 0.65)))


## Retângulo com o lado direito inclinado (a ponta da barra da referência).
static func _paralelogramo(pos: Vector2, tamanho: Vector2, corte: float) -> PackedVector2Array:
	return PackedVector2Array([pos, pos + Vector2(tamanho.x, 0), pos + Vector2(tamanho.x - corte, tamanho.y), pos + Vector2(0, tamanho.y)])


## Plaquinha escura com aro dourado e um texto no meio (número da tecla, N
## do minimapa, quantidade de runas).
static func placa(ci: CanvasItem, centro: Vector2, lado: float, texto: String, fonte: Font, tamanho_fonte: int) -> void:
	var r := Rect2(centro - Vector2(lado, lado) / 2.0, Vector2(lado, lado))
	ci.draw_rect(r.grow(2.0), BRONZE)
	var g := r.grow(1.0)
	ci.draw_polygon(PackedVector2Array([g.position, Vector2(g.end.x, g.position.y), g.end, Vector2(g.position.x, g.end.y)]),
		PackedColorArray([OURO_CLARO, OURO_CLARO, OURO_ESCURO, OURO_ESCURO]))
	ci.draw_rect(r, PEDRA_ESCURA)
	texto_centrado(ci, fonte, texto, centro + Vector2(0, tamanho_fonte * 0.36), tamanho_fonte, Color.WHITE)


static func texto_centrado(ci: CanvasItem, fonte: Font, texto: String, base: Vector2, tamanho: int, cor: Color) -> void:
	var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
	# Contorno grosso e escuro: número legível sobre medalhão, céu ou grama.
	ci.draw_string_outline(fonte, base - Vector2(largura / 2.0, 0), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, maxi(5, tamanho / 3), Color(0.05, 0.03, 0.06, 0.95))
	ci.draw_string(fonte, base - Vector2(largura / 2.0, 0), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor)


## Desenha a runa "nome" (fogo, agua, vida, feroz, prende, arremesso...)
## com os traços da folha do Vitor: halo na cor, traço na cor e miolo claro,
## como o símbolo aceso das runas 3D. "altura" é o tamanho na tela.
## Furos do traço são pintados com "cor_fundo" (o que está atrás do símbolo).
static func simbolo_runa(ci: CanvasItem, nome: String, centro: Vector2, altura: float, cor: Color, cor_fundo: Color, intensidade := 1.0) -> void:
	var dados := _simbolo(nome)
	if dados.is_empty():
		return
	var escala := altura / 0.46 # os traços medem ~0,46 de altura
	var halo := Color(cor.lightened(0.2), 0.22 * intensidade)
	for peca in dados.get("pecas", []):
		var pts := _pontos(peca, centro, escala)
		if peca.get("buraco", false):
			continue
		_preencher(ci, _engordar(pts, centro, 1.0 + 4.0 / maxf(altura, 1.0) * 2.0), halo)
	for peca in dados.get("pecas", []):
		var pts := _pontos(peca, centro, escala)
		_preencher(ci, pts, cor_fundo if peca.get("buraco", false) else cor.lerp(cor.lightened(0.35), 0.4))
	for peca in dados.get("miolos", []):
		_preencher(ci, _pontos(peca, centro, escala), Color(1.0, 0.97, 0.85).lerp(cor.lightened(0.6), 0.35) * Color(1, 1, 1, intensidade))


static func tem_simbolo(nome: String) -> bool:
	return not _simbolo(nome).is_empty()


static func _simbolo(nome: String) -> Dictionary:
	if not _carregou:
		_carregou = true
		var texto := FileAccess.get_file_as_string(CAMINHO_SIMBOLOS)
		var lido = JSON.parse_string(texto) if texto != "" else null
		if lido is Dictionary:
			_simbolos = lido
		else:
			push_error("EstiloHud: não consegui ler %s; as runas do HUD ficam sem símbolo." % CAMINHO_SIMBOLOS)
	if not _simbolos.has(nome):
		return {}
	return _simbolos[nome]


## Os traços têm y para cima (como no Blender); na tela y é para baixo.
static func _pontos(peca: Dictionary, centro: Vector2, escala: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in peca.get("pts", []):
		pts.append(centro + Vector2(float(p[0]), -float(p[1])) * escala)
	return pts


static func _engordar(pts: PackedVector2Array, centro: Vector2, fator: float) -> PackedVector2Array:
	var saida := Geometry2D.offset_polygon(pts, 2.5 * fator)
	return saida[0] if not saida.is_empty() else pts


## Traço côncavo: o Godot triangula sozinho; se o traço tiver um nó que a
## triangulação não resolve, quebra em pedaços convexos antes.
static func _preencher(ci: CanvasItem, pts: PackedVector2Array, cor: Color) -> void:
	if pts.size() < 3:
		return
	if Geometry2D.triangulate_polygon(pts).is_empty():
		for parte in Geometry2D.decompose_polygon_in_convex(pts):
			if parte.size() >= 3:
				ci.draw_colored_polygon(parte, cor)
		return
	ci.draw_colored_polygon(pts, cor)
