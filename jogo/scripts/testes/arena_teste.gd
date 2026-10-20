extends Node3D
## Arena de teste da Fase 1 (proposta técnica, seção 9). Só liga a HUD ao
## mago; toda a lógica de jogo vive nos próprios nós.

@onready var _mago: Node = $Mago
@onready var _hud: Node = $HUD
@onready var _caixa_conjuracao: Node = $CaixaConjuracao


func _ready() -> void:
	_hud.configurar(_mago)
	_caixa_conjuracao.configurar(_mago)
	_caixa_conjuracao.frase_confirmada.connect(_mago.conjurar_por_texto)
