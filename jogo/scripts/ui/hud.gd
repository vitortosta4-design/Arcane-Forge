extends CanvasLayer
## HUD no layout oficial da ADR-039, seguindo a referência
## (docs/referencias/arte-conceito-01.png), com visual provisório:
## - canto superior esquerdo: retrato do mago, vida e mana; abaixo, runas e
##   estados ativos (PainelMago + Estados);
## - centro: mira;
## - embaixo no centro: barra dos 4 medalhões, com tecla e recarga;
## - logo acima da barra: aviso de interação (ex.: "E: usar a bigorna");
## - canto inferior direito: espaço reservado do minimapa.
## O HUD só LÊ o mago e a barra: nunca altera vida, mana, runas ou medalhões.
## Visual 100% provisório de propósito (formas lisas em cinza e nas cores dos
## elementos); o estilo vem de uma referência que o Vitor ainda vai aprovar.

const NOMES_ESTADOS := {
	"eletrizado": "Eletrizado!",
	"queimando": "Queimando",
	"cego": "Cego",
	"molhado": "Molhado",
	"lento": "Lento",
	"preso": "Preso",
}
## Nós que o layout precisa; faltar algum é erro de cena, avisado no _ready.
const NOS_OBRIGATORIOS := ["Cegueira", "Clarao", "Mira", "PainelMago", "Estados", "FPS", "BarraMedalhoes", "Aviso", "Legenda", "Minimapa"]

var _tempo_legenda_s := 0.0
var _label_legenda: Label
var _label_fps: Label
var _label_estados: Label
var _cegueira: ColorRect
var _clarao: ColorRect
var _aviso: Label
var _painel: PainelMago
var _barra: BarraHud


func _ready() -> void:
	for nome in NOS_OBRIGATORIOS:
		if get_node_or_null(nome) == null:
			push_warning("HUD: falta o nó '%s' em cenas/hud.tscn; essa parte da tela não aparece." % nome)
	_label_legenda = get_node_or_null("Legenda")
	_label_fps = get_node_or_null("FPS")
	_label_estados = get_node_or_null("Estados")
	_cegueira = get_node_or_null("Cegueira")
	_clarao = get_node_or_null("Clarao")
	_aviso = get_node_or_null("Aviso")
	_painel = get_node_or_null("PainelMago")
	_barra = get_node_or_null("BarraMedalhoes")
	if _label_legenda:
		_label_legenda.text = ""


func configurar(mago: Node) -> void:
	if mago == null:
		push_warning("HUD.configurar: recebeu mago nulo; o HUD fica vazio.")
		return
	for sinal in ["conjurou", "teleportou"]:
		if not mago.has_signal(sinal):
			push_warning("HUD: o mago não tem o sinal '%s'; essa parte do HUD não reage." % sinal)
	if mago.has_signal("conjurou"):
		mago.conjurou.connect(_ao_conjurar)
	if mago.has_signal("teleportou"):
		mago.teleportou.connect(_ao_teleportar)
	if mago.get("estados") != null:
		mago.estados.estados_mudaram.connect(_ao_estados_mudarem)
	else:
		push_warning("HUD: o mago não tem controlador de estados; os estados não aparecem.")
	if _painel:
		_painel.mago = mago
	if _barra:
		_barra.mago = mago


## F3 liga e desliga o contador de FPS (ligável, critério da Fase 1;
## escondido por padrão para não poluir a tela).
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3 and _label_fps:
		_label_fps.visible = not _label_fps.visible


func _process(delta: float) -> void:
	if _label_fps and _label_fps.visible:
		_label_fps.text = "FPS: %d" % Engine.get_frames_per_second()
	if _tempo_legenda_s > 0.0:
		_tempo_legenda_s -= delta
		if _tempo_legenda_s <= 0.0 and _label_legenda:
			_label_legenda.text = ""
			_label_legenda.visible = false


## Em primeira pessoa o jogador não vê o próprio corpo colorido, então os
## estados do mago também aparecem em texto (ADR-017: feedback claro).
func _ao_estados_mudarem(nomes: Array) -> void:
	if _label_estados:
		_label_estados.text = "Estados: " + "  ".join(PackedStringArray(nomes.map(func(n): return NOMES_ESTADOS.get(n, n))))
		_label_estados.visible = not nomes.is_empty()
	# Cego de verdade: quase não se vê nada, mas o texto do HUD continua
	# legível por cima, para o jogador entender o que aconteceu.
	if _cegueira:
		_cegueira.visible = "cego" in nomes


func _ao_teleportar() -> void:
	if _clarao:
		_clarao.color.a = 0.7
		create_tween().tween_property(_clarao, "color:a", 0.0, 0.3)


func _ao_conjurar(legenda: String) -> void:
	if _label_legenda:
		_label_legenda.text = legenda
		_label_legenda.visible = legenda != ""
		_tempo_legenda_s = 2.5


## Aviso de interação logo acima da barra (ex.: "E: usar a bigorna").
## Vazio esconde.
func mostrar_aviso(texto: String) -> void:
	if _aviso == null:
		push_warning("HUD.mostrar_aviso: sem o nó Aviso; texto perdido: '%s'." % texto)
		return
	_aviso.text = texto
	_aviso.visible = texto != ""
