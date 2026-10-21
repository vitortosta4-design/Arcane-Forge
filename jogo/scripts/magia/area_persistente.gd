extends Node3D
## Área persistente (proposta técnica, seção 3): uma zona no chão que dura
## alguns segundos e, a cada segundo, afeta quem estiver dentro (dano e/ou
## um estado). Quem decide o dano é sempre o Host (o juiz, ADR-004); esta
## cena só marca o lugar, o tempo e mostra o disco colorido.

const INTERVALO_TICK_S := 1.0
## O estado dura um pouco mais que o tick: fica ativo enquanto o alvo está
## dentro da área e acaba logo depois que ele sai.
const DURACAO_ESTADO_NA_AREA_S := 1.5
const DURACAO_SUMIR_S := 0.5
## Opaca o bastante para a cor não virar marrom sobre a grama verde
## (achado no primeiro print: lava meio transparente parecia terra).
const OPACIDADE := 0.8

var raio_m := 2.0
var duracao_s := 4.0
var dano_por_s := 0.0
var nome_estado := ""
var material_nome := "pedra"
var dono: Node = null
var excluir: Array = []

var _tempo_vivo := 0.0
var _ate_tick := 0.0
var _material: StandardMaterial3D

@onready var _disco: MeshInstance3D = $Disco


func _ready() -> void:
	add_to_group("area_persistente")
	_disco.scale = Vector3(raio_m, 1.0, raio_m)
	var cor := Validador.cor_para_material(material_nome)
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = Color(cor.r, cor.g, cor.b, OPACIDADE)
	_material.emission_enabled = true
	_material.emission = cor
	_disco.material_override = _material
	# Sem tick aqui: o _ready() roda antes do Executor posicionar a área,
	# e o primeiro tick acertaria o ponto (0,0,0). _ate_tick começa em zero,
	# então o primeiro quadro de física já faz o tick no lugar certo.


func _physics_process(delta: float) -> void:
	_tempo_vivo += delta
	if _tempo_vivo >= duracao_s:
		queue_free()
		return
	var restante := duracao_s - _tempo_vivo
	if restante < DURACAO_SUMIR_S:
		_material.albedo_color.a = OPACIDADE * restante / DURACAO_SUMIR_S
	_ate_tick -= delta
	if _ate_tick <= 0.0:
		_tick()


func _tick() -> void:
	_ate_tick = INTERVALO_TICK_S
	Host.aplicar_area(
		global_position, raio_m, dano_por_s * INTERVALO_TICK_S,
		nome_estado, DURACAO_ESTADO_NA_AREA_S, material_nome, excluir
	)
