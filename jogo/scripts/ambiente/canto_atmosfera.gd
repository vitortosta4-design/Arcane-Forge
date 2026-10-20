extends Node3D
## Tocha do canto de atmosfera (ADR-025/030): luz quente que tremula, barato
## (só uma OmniLight3D e duas senoides somadas, sem partículas).

@onready var _luz: OmniLight3D = $Tocha/Luz
@onready var _chama: MeshInstance3D = $Tocha/Chama

var _tempo := 0.0


func _process(delta: float) -> void:
	_tempo += delta
	var tremular := sin(_tempo * 9.0) * 0.15 + sin(_tempo * 23.0) * 0.08
	_luz.light_energy = 1.3 + tremular
	_chama.scale = Vector3.ONE * (1.0 + tremular * 0.3)
