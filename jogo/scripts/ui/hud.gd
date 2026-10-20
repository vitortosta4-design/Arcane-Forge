extends CanvasLayer
## HUD simples: vida, mana, legenda da última magia e contador de FPS
## (critérios de aceitação da Fase 1).

@onready var _label_vida: Label = $Vida
@onready var _label_mana: Label = $Mana
@onready var _label_legenda: Label = $Legenda
@onready var _label_fps: Label = $FPS

var _tempo_legenda_s := 0.0


func _ready() -> void:
	_label_legenda.text = ""


func configurar(mago: Node) -> void:
	mago.vida_mudou.connect(_ao_vida_mudar)
	mago.mana_mudou.connect(_ao_mana_mudar)
	mago.conjurou.connect(_ao_conjurar)
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


func _ao_conjurar(legenda: String) -> void:
	_label_legenda.text = legenda
	_tempo_legenda_s = 2.5
