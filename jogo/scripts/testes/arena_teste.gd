extends Node3D
## Arena de teste (clareira + caverna da forja). Só liga HUD, tela da forja e
## menu de pausa ao mago; toda a lógica de jogo vive nos próprios nós.

@onready var _mago: Node = $Mago
@onready var _hud: Node = $HUD
@onready var _caverna: Caverna = $Caverna
@onready var _forja_ui: ForjaUI = $ForjaUI
@onready var _menu_pausa: Node = $MenuPausa


func _ready() -> void:
	_hud.configurar(_mago)
	_forja_ui.configurar(_mago, _caverna.forja, _hud)
	_menu_pausa.configurar(_mago, _forja_ui)
