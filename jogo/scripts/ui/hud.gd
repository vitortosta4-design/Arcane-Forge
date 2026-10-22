extends CanvasLayer
## HUD simples: vida, mana, legenda da última magia e contador de FPS
## (critérios de aceitação da Fase 1).

@onready var _label_vida: Label = $Vida
@onready var _label_mana: Label = $Mana
@onready var _label_legenda: Label = $Legenda
@onready var _label_fps: Label = $FPS
@onready var _label_estados: Label = $Estados
@onready var _cegueira: ColorRect = $Cegueira
@onready var _clarao: ColorRect = $Clarao
@onready var _label_runas: RichTextLabel = $Runas
@onready var _label_interacao: Label = $Interacao

const NOMES_ESTADOS := {
	"eletrizado": "Eletrizado!",
	"queimando": "Queimando",
	"cego": "Cego",
	"molhado": "Molhado",
	"lento": "Lento",
}

var _tempo_legenda_s := 0.0
var _qtd_runas := 0


func _ready() -> void:
	_label_legenda.text = ""


func configurar(mago: Node) -> void:
	mago.vida_mudou.connect(_ao_vida_mudar)
	mago.mana_mudou.connect(_ao_mana_mudar)
	mago.conjurou.connect(_ao_conjurar)
	mago.estados.estados_mudaram.connect(_ao_estados_mudarem)
	mago.teleportou.connect(_ao_teleportar)
	mago.runas_mudaram.connect(_ao_runas_mudarem)
	mago.interacao_mudou.connect(_ao_interacao_mudar)
	_ao_runas_mudarem(mago.runas)
	_ao_vida_mudar(mago.vida_atual, mago.vida_maxima)
	_ao_mana_mudar(mago.mana_atual, mago.mana_maxima)


func _process(delta: float) -> void:
	_label_fps.text = "FPS: %d" % Engine.get_frames_per_second()
	if _tempo_legenda_s > 0.0:
		_tempo_legenda_s -= delta
		if _tempo_legenda_s <= 0.0:
			_label_legenda.text = ""


func _ao_vida_mudar(atual: float, maxima: float) -> void:
	_label_vida.text = "Vida: %d/%d" % [roundi(atual), roundi(maxima)]


func _ao_mana_mudar(atual: float, maxima: float) -> void:
	_label_mana.text = "Mana: %d/%d" % [roundi(atual), roundi(maxima)]


## Em primeira pessoa o jogador não vê o próprio corpo colorido, então os
## estados do mago também aparecem em texto (ADR-017: feedback claro).
func _ao_estados_mudarem(nomes: Array) -> void:
	_label_estados.text = "  ".join(PackedStringArray(nomes.map(func(n): return NOMES_ESTADOS.get(n, n))))
	# Cego de verdade: quase não se vê nada, mas o texto do HUD continua
	# legível por cima, para o jogador entender o que aconteceu.
	_cegueira.visible = "cego" in nomes


func _ao_teleportar() -> void:
	_clarao.color.a = 0.7
	create_tween().tween_property(_clarao, "color:a", 0.0, 0.3)


func _ao_conjurar(legenda: String) -> void:
	_label_legenda.text = legenda
	_tempo_legenda_s = 2.5


## Contador de runas (Fase 2): quantas o mago carrega e quais, cada uma na
## cor do seu brilho. Ao pegar uma nova, avisa na legenda.
func _ao_runas_mudarem(runas: Array) -> void:
	var nomes: Array = []
	for nome in runas:
		var r := LivroDeReceitas.runa(nome)
		nomes.append("[color=%s]%s[/color]" % [r.get("cor", "#ffffff"), r.get("nome", nome)])
	_label_runas.text = "Runas (%d): %s" % [runas.size(), " · ".join(nomes)] if not runas.is_empty() else "Runas: nenhuma"
	if runas.size() > _qtd_runas:
		var nova: Dictionary = LivroDeReceitas.runa(runas[-1])
		_ao_conjurar("Você pegou a runa %s!" % nova.get("nome", runas[-1]))
	_qtd_runas = runas.size()


func _ao_interacao_mudar(texto: String) -> void:
	_label_interacao.text = "[E] %s" % texto if texto != "" else ""
