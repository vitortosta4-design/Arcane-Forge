extends StaticBody3D
## Parede de magia (proposta técnica, seção 3, "parede/construção"): um
## bloco sólido por alguns segundos. Fica no layer de colisão 1 (cenário),
## então segura projéteis, inimigos e o próprio mago, sem nenhum código a
## mais. O Executor ajusta tamanho e duração antes de colocá-la no mundo.

const ESPESSURA_M := 0.4
const DURACAO_SUMIR_S := 0.4

var largura_m := 3.0
var altura_m := 2.0
var duracao_s := 5.0
var material_nome := "pedra"
var dono: Node = null

var _tempo_vivo := 0.0
var _material: StandardMaterial3D

@onready var _forma: CollisionShape3D = $CollisionShape3D
@onready var _malha: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	var tamanho := Vector3(largura_m, altura_m, ESPESSURA_M)
	var caixa := BoxShape3D.new()
	caixa.size = tamanho
	_forma.shape = caixa
	var malha := BoxMesh.new()
	malha.size = tamanho
	_malha.mesh = malha
	# Centro meio corpo acima do chão: a base da parede encosta no chão.
	_forma.position.y = altura_m / 2.0
	_malha.position.y = altura_m / 2.0
	_material = StandardMaterial3D.new()
	_material.albedo_color = Validador.cor_para_material(material_nome)
	_malha.material_override = _material


func _physics_process(delta: float) -> void:
	_tempo_vivo += delta
	var restante := duracao_s - _tempo_vivo
	if restante <= 0.0:
		queue_free()
	elif restante < DURACAO_SUMIR_S:
		# Transparência só no fim: ligada o tempo todo, a parede deixaria de
		# fazer sombra e seria desenhada como objeto transparente à toa.
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.albedo_color.a = restante / DURACAO_SUMIR_S
