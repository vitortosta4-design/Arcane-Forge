extends Node3D
## Espalha pedras e touceiras de grama pela arena de teste, para o chão não
## ficar um retângulo verde liso (continuação do item "arena de teste low
## poly" da Fase 1, não o gerador de mapas por módulos, que é da Fase 7).
## Usa MultiMesh: centenas de decorações custam uma fração do FPS que
## custaria criar um nó por pedrinha (meta de desempenho, proposta
## técnica seção 8). Puramente visual, sem colisão.

const TAMANHO_AREA := 34.0
const QTD_ROCHAS := 40
const QTD_GRAMA := 220
const SEMENTE := 20261020 # data de criação, só para o resultado ser sempre igual

@onready var _rochas: MultiMeshInstance3D = $Rochas
@onready var _grama: MultiMeshInstance3D = $Grama


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMENTE
	_espalhar(_rochas, _criar_malha_rocha(), QTD_ROCHAS, rng, 0.25, 0.6, true)
	_espalhar(_grama, _criar_malha_grama(), QTD_GRAMA, rng, 0.7, 1.3, false)


func _espalhar(
	alvo: MultiMeshInstance3D,
	malha: Mesh,
	quantidade: int,
	rng: RandomNumberGenerator,
	escala_min: float,
	escala_max: float,
	levantar_pela_escala: bool
) -> void:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = malha
	multi.instance_count = quantidade

	for i in quantidade:
		var pos := Vector3(
			rng.randf_range(-TAMANHO_AREA / 2.0, TAMANHO_AREA / 2.0),
			0.0,
			rng.randf_range(-TAMANHO_AREA / 2.0, TAMANHO_AREA / 2.0)
		)
		var escala := rng.randf_range(escala_min, escala_max)
		if levantar_pela_escala:
			pos.y += escala * 0.3
		var rotacao := rng.randf_range(0.0, TAU)
		var transformada := Transform3D(Basis(Vector3.UP, rotacao).scaled(Vector3.ONE * escala), pos)
		multi.set_instance_transform(i, transformada)
		var sombra := rng.randf_range(0.85, 1.15)
		multi.set_instance_color(i, Color(sombra, sombra, sombra, 1.0))

	alvo.multimesh = multi


func _criar_malha_rocha() -> Mesh:
	var malha := SphereMesh.new()
	malha.radius = 0.4
	malha.height = 0.7
	malha.radial_segments = 6
	malha.rings = 3
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.47, 0.43)
	material.vertex_color_use_as_albedo = true
	malha.surface_set_material(0, material)
	return malha


func _criar_malha_grama() -> Mesh:
	var malha := BoxMesh.new()
	malha.size = Vector3(0.12, 0.45, 0.12)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.6, 0.28)
	material.vertex_color_use_as_albedo = true
	malha.surface_set_material(0, material)
	return malha
