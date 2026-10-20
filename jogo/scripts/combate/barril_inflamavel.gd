extends StaticBody3D
## Barril com a etiqueta "inflamavel". Pega fogo quando uma explosão com a
## etiqueta "fogo" acontece perto (primeira interação por etiquetas da
## proposta técnica, seção 3) e, depois de queimar um pouco, explode também.

@export var tempo_ate_explodir_s := 1.5
@export var dano_da_explosao := 20.0
@export var raio_da_explosao := 2.5
@export var empurrao_da_explosao := 4.0

var _queimando := false

@onready var _mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	add_to_group("inflamavel")


func pegar_fogo() -> void:
	if _queimando:
		return
	_queimando = true
	if _mesh and _mesh.get_surface_override_material(0):
		_mesh.get_surface_override_material(0).albedo_color = Color(1, 0.3, 0.05)
		_mesh.get_surface_override_material(0).emission_enabled = true
		_mesh.get_surface_override_material(0).emission = Color(1, 0.25, 0)
	var timer := get_tree().create_timer(tempo_ate_explodir_s)
	timer.timeout.connect(_explodir)


func _explodir() -> void:
	Host.criar_explosao(global_position, raio_da_explosao, dano_da_explosao, empurrao_da_explosao, ["fogo"], [self])
	queue_free()
