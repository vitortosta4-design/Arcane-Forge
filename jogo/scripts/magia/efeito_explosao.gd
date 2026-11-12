extends Node3D
## Feedback visual de uma explosão, com peso (auditoria de animação, item 4):
## 1. clarão: um miolo quase branco fica parado por um instante (a "pausa de
##    impacto", só neste efeito: o jogo não para, o que importa no cooperativo);
## 2. estouro: a bola cresce rápido no começo e freia no fim, em vez de
##    crescer em velocidade constante;
## 3. sobra: some devagar enquanto um anel corre pelo chão e lascas voam.
## Só visual: dano, empurrão e tremida de câmera são do Host.

@export var duracao_s := 0.45
## Tempo em que o miolo fica parado e claro antes de estourar.
const PAUSA_CLARAO_S := 0.05
const LASCAS := 6

@onready var _mesh: MeshInstance3D = $MeshInstance3D


## O Host chama isto logo depois de criar o efeito (em vez de usar _ready,
## para não depender da ordem entre add_child e a atribuição de valores).
func iniciar(raio_m: float, nome_material: String) -> void:
	# Duplica o material: sem isso, explosões ao mesmo tempo compartilhariam
	# o mesmo recurso e uma roubaria a cor/desaparecimento da outra.
	var material := (_mesh.get_surface_override_material(0) as StandardMaterial3D).duplicate()
	var cor := Validador.cor_para_material(nome_material)
	var clara := cor.lerp(Color.WHITE, 0.7)
	var quente := cor.lerp(Color.WHITE, 0.15)
	material.albedo_color = Color(clara.r, clara.g, clara.b, 1.0)
	material.emission = clara
	_mesh.set_surface_override_material(0, material)
	_mesh.scale = Vector3.ONE * raio_m * 0.28

	var estouro_s := duracao_s - PAUSA_CLARAO_S
	var tween := create_tween()
	tween.tween_interval(PAUSA_CLARAO_S)
	# Fim do clarão: troca de uma vez para a cor viva do material (misturar
	# devagar deixava a bola bege em vez de fogo).
	tween.tween_callback(func():
		material.albedo_color = Color(quente.r, quente.g, quente.b, 0.9)
		material.emission = cor)
	# Depois da pausa, os três andam juntos (parallel() cola no passo anterior).
	tween.tween_property(_mesh, "scale", Vector3.ONE * raio_m, estouro_s * 0.55) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(material, "albedo_color", Color(cor.r, cor.g, cor.b, 0.0), estouro_s) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

	_criar_anel(raio_m, cor, estouro_s)
	_criar_lascas(raio_m, cor, estouro_s)


## Onda de choque: um anel fino deitado que corre para fora e apaga.
func _criar_anel(raio_m: float, cor: Color, estouro_s: float) -> void:
	var anel := MeshInstance3D.new()
	anel.name = "Anel"
	var malha := TorusMesh.new()
	malha.inner_radius = 0.82
	malha.outer_radius = 1.0
	malha.rings = 16
	malha.ring_segments = 4
	anel.mesh = malha
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(cor.r, cor.g, cor.b, 0.9).lerp(Color(1, 1, 1, 0.9), 0.55)
	anel.material_override = mat
	anel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	anel.scale = Vector3(0.3, 0.2, 0.3) * raio_m
	add_child(anel)
	var t := anel.create_tween().set_parallel(true)
	t.tween_property(anel, "scale", Vector3(1.6, 0.2, 1.6) * raio_m, estouro_s) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(PAUSA_CLARAO_S * 0.5)
	t.tween_property(mat, "albedo_color:a", 0.0, estouro_s).set_ease(Tween.EASE_IN).set_delay(PAUSA_CLARAO_S * 0.5)


## Lascas low poly: cubinhos que saltam em arco e encolhem. Poucas e de vida
## curta, para não pesar com várias explosões juntas.
func _criar_lascas(raio_m: float, cor: Color, estouro_s: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = cor.lerp(Color.WHITE, 0.5)
	var malha := BoxMesh.new()
	malha.size = Vector3.ONE * 0.16 * clampf(raio_m, 0.8, 2.5)
	for i in LASCAS:
		var lasca := MeshInstance3D.new()
		lasca.mesh = malha
		lasca.material_override = mat
		lasca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(lasca)
		var angulo := TAU * (float(i) + randf() * 0.6) / LASCAS
		var lado := Vector3(cos(angulo), 0.0, sin(angulo)) * raio_m * randf_range(1.1, 1.6)
		var topo := raio_m * randf_range(0.7, 1.1)
		lasca.rotation = Vector3(randf(), randf(), randf()) * TAU
		var t := lasca.create_tween().set_parallel(true)
		# Para os lados em ritmo que freia; para cima sobe e cai (arco).
		t.tween_property(lasca, "position:x", lado.x, estouro_s).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(lasca, "position:z", lado.z, estouro_s).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(lasca, "position:y", topo, estouro_s * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(lasca, "position:y", -0.2, estouro_s * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(estouro_s * 0.45)
		t.tween_property(lasca, "scale", Vector3.ONE * 0.1, estouro_s).set_ease(Tween.EASE_IN)
