class_name BarraHud
extends Control
## Barra dos 4 medalhões no pé da tela, no centro (ADR-033, ADR-039), no
## estilo da referência docs/referencias/hud-referencia-01.png: medalhão
## redondo com aro dourado e cravos, miolo de pedra lapidada e a runa acesa
## na cor do elemento; espaço livre é pedra rachada apagada. O número da
## tecla fica numa plaquinha em cima. Recarga: uma sombra escura em forma de
## relógio cobre a parte que ainda falta (escolha 2b do Vitor, 23/10/2026).
## Só lê a barra do mago.

## Diâmetro do medalhão, aro incluído.
const TAMANHO := 64.0
const ESPACO := 20.0
## Distância do pé da tela até a base dos medalhões.
const MARGEM_BAIXO := 22.0
## Quanto a plaquinha da tecla sobe acima do medalhão. O aviso de interação
## do HUD fica acima disto.
const ALTURA_PLACA := 16.0
const ARO := 6.0
const PEDRA_LIVRE := Color(0.24, 0.23, 0.27, 0.92)

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


## Centro do medalhão i na tela (também usado pelo contador de runas, que
## fica à esquerda do primeiro).
static func centro_do_espaco(i: int, tela: Vector2) -> Vector2:
	var largura := BarraMedalhoes.ESPACOS * TAMANHO + (BarraMedalhoes.ESPACOS - 1) * ESPACO
	var inicio_x := (tela.x - largura) / 2.0
	return Vector2(inicio_x + i * (TAMANHO + ESPACO) + TAMANHO / 2.0, tela.y - MARGEM_BAIXO - TAMANHO / 2.0)


func _draw() -> void:
	if mago == null or mago.get("barra") == null:
		if not _avisou and _vivo_s > 1.0:
			push_warning("BarraHud: sem mago ou sem barra de medalhões configurada; a barra 1 a 4 não aparece.")
			_avisou = true
		return
	var barra: BarraMedalhoes = mago.barra
	var tela := get_viewport_rect().size
	var raio := TAMANHO / 2.0
	for i in BarraMedalhoes.ESPACOS:
		var centro := centro_do_espaco(i, tela)
		var medalhao = barra.medalhoes[i]
		var selecionado: bool = i == mago.espaco_selecionado
		if selecionado:
			# Selecionado: halo dourado em volta, sem mudar o tamanho (a barra
			# não "pula" ao trocar de tecla).
			# Halo em camadas, pulsando de leve, para não sumir no chão de terra.
			var pulso := 0.75 + 0.25 * sin(_vivo_s * 4.0)
			draw_arc(centro, raio + 7.0, 0.0, TAU, 64, Color(1.0, 0.9, 0.55, 0.22 * pulso), 9.0, true)
			draw_arc(centro, raio + 4.0, 0.0, TAU, 64, Color(1.0, 0.92, 0.6, 0.5 * pulso), 4.0, true)
			draw_arc(centro, raio + 2.0, 0.0, TAU, 64, Color(1.0, 0.98, 0.85, 0.95), 2.0, true)
		if medalhao == null:
			_espaco_livre(centro, raio - ARO)
		else:
			_medalhao(centro, raio - ARO, medalhao, barra.fracao_recarga(i))
		EstiloHud.aro(self, centro, raio, ARO, 4 if medalhao != null else 0)
		EstiloHud.placa(self, centro + Vector2(0, -raio - ALTURA_PLACA * 0.15), 18.0, str(i + 1), _fonte, 13)


func _espaco_livre(centro: Vector2, raio: float) -> void:
	EstiloHud.disco_lapidado(self, centro, raio, PEDRA_LIVRE, 8)
	# Rachaduras: o espaço parece vazio e gasto, não um botão apagado.
	var rachas := [[Vector2(-0.6, -0.5), Vector2(-0.1, -0.05), Vector2(0.15, 0.55)],
		[Vector2(-0.1, -0.05), Vector2(0.55, -0.3)], [Vector2(-0.55, 0.35), Vector2(-0.2, 0.2)]]
	for racha in rachas:
		var pts := PackedVector2Array()
		for p in racha:
			pts.append(centro + p * raio)
		draw_polyline(pts, Color(0.08, 0.07, 0.1, 0.8), 1.6, true)


func _medalhao(centro: Vector2, raio: float, medalhao: Dictionary, fracao_recarga: float) -> void:
	var cor := Color(medalhao.get("cor", "#ffffff"))
	# Pedra do miolo tingida pelo elemento, escura, para o símbolo aceso
	# saltar (mesma ideia da pedra acesa das runas 3D).
	var pedra := cor.darkened(0.5).lerp(EstiloHud.PEDRA, 0.2)
	EstiloHud.disco_lapidado(self, centro, raio, pedra, 8)
	var nome := _runa_do_simbolo(medalhao)
	if nome != "":
		EstiloHud.simbolo_runa(self, nome, centro, raio * 1.45, cor, pedra)
	else:
		# Medalhão sem runa conhecida: o símbolo de texto antigo, para não
		# sumir nada. Acontece com fichas de teste.
		EstiloHud.texto_centrado(self, _fonte, str(medalhao.get("simbolo", "●")), centro + Vector2(0, 9), 26, cor.lightened(0.4))
	if fracao_recarga > 0.0:
		draw_colored_polygon(_setor(centro, raio, fracao_recarga), Color(0.02, 0.02, 0.05, 0.68))
		var segundos := ceili(fracao_recarga * float(medalhao.get("recarga_s", 1.0)))
		EstiloHud.texto_centrado(self, _fonte, str(segundos), centro + Vector2(0, 8), 22, Color.WHITE)


## Qual runa desenhar: a de forma (ela decide o modelo da magia, ADR-032);
## se não tiver forma, o primeiro elemento.
func _runa_do_simbolo(medalhao: Dictionary) -> String:
	var runas: Array = medalhao.get("runas", [])
	var livro = mago.get("livro") if mago else null
	for r in runas:
		if livro and livro.formas.has(str(r)) and EstiloHud.tem_simbolo(str(r)):
			return str(r)
	for r in runas:
		if EstiloHud.tem_simbolo(str(r)):
			return str(r)
	return ""


## Sombra de relógio: cobre a fração que ainda falta recarregar, começando
## no topo e indo no sentido horário; a parte livre vai crescendo.
func _setor(centro: Vector2, raio: float, fracao: float) -> PackedVector2Array:
	var pontos := PackedVector2Array([centro])
	var inicio := -PI / 2.0 + TAU * (1.0 - fracao)
	var passos := maxi(3, ceili(48 * fracao))
	for k in passos + 1:
		var angulo := inicio + TAU * fracao * k / passos
		pontos.append(centro + Vector2(cos(angulo), sin(angulo)) * raio)
	return pontos
