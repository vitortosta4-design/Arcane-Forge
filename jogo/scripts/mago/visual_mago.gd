class_name VisualMago
extends Node3D
## Corpo do mago visto em terceira pessoa (e pelo parceiro no cooperativo).
## Modelo modelado pela folha do Vitor (docs/referencias/mago_folha_vitor.png):
## assets/modelos/mago/mago.glb, gerado por arte/personagens/mago/mago.py.
## Tem esqueleto e as animações Parado, Andar, Conjurar, ErguerCajado e Dano;
## cada dedo da luva tem dois ossos (no Parado, os dedos da mão livre fazem
## uma ondinha lenta).
## Este nó só escolhe qual animação toca e em que velocidade; não muda regra
## de jogo nenhuma.

const MODELO := preload("res://assets/modelos/mago/mago.glb")
## O modelo tem ~1 m com o chapéu (escala da folha). Aumentado por igual para
## os olhos ficarem perto da altura da câmera de primeira pessoa (1,6 m).
const ESCALA := 2.4
## Velocidade em que a animação Andar casa com o passo (m/s, já na escala do
## jogo). Acima ou abaixo disso ela acelera ou desacelera, para o pé não
## patinar no chão.
const VELOCIDADE_DO_PASSO := 3.2
const MISTURA_S := 0.15
const COR_CRISTAL := Color(0.3, 0.62, 1.0)

var _anim: AnimationPlayer
var _cristal: Node3D
var _acao := ""


func _ready() -> void:
	var modelo := MODELO.instantiate() as Node3D
	modelo.name = "Modelo"
	# O Blender desenhou o mago olhando para -Y, que no Godot vira +Z; o mago
	# do jogo anda para -Z.
	modelo.rotation.y = PI
	modelo.scale = Vector3.ONE * ESCALA
	add_child(modelo)
	_anim = modelo.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim == null:
		push_warning("VisualMago: mago.glb sem AnimationPlayer; o mago fica parado em pose.")
	else:
		for nome in ["Parado", "Andar"]:
			if _anim.has_animation(nome):
				_anim.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
			else:
				push_warning("VisualMago: mago.glb sem a animação '%s'." % nome)
		_anim.animation_finished.connect(func(_n): _acao = "")
		_anim.play("Parado")
	_cristal = modelo.find_child("CajadoCristal", true, false) as Node3D
	if _cristal == null:
		push_warning("VisualMago: mago.glb sem o nó CajadoCristal; a magia sai do meio do mago.")


## Chamado pelo mago a cada quadro de física.
func animar(_delta: float, velocidade_horizontal: float, no_chao: bool) -> void:
	if _anim == null or _acao != "":
		return
	if no_chao and velocidade_horizontal > 0.3:
		if _anim.current_animation != "Andar":
			_anim.play("Andar", MISTURA_S)
		_anim.speed_scale = clampf(velocidade_horizontal / VELOCIDADE_DO_PASSO, 0.5, 1.8)
	else:
		if _anim.current_animation != "Parado":
			_anim.play("Parado", MISTURA_S)
		_anim.speed_scale = 1.0


func conjurar() -> void:
	_tocar_acao("Conjurar")


## O mago levou dano: tranco para trás e as mãos abrem de susto.
func reagir_dano() -> void:
	_tocar_acao("Dano")


func _tocar_acao(nome: String) -> void:
	if _anim == null or not _anim.has_animation(nome):
		push_warning("VisualMago: sem a animação '%s'." % nome)
		return
	_acao = nome
	_anim.speed_scale = 1.0
	# Começa quase sem mistura: a resposta ao clique tem que aparecer já.
	_anim.play(nome, 0.05)


## Ponto um pouco à frente do cristal do cajado, em coordenadas do mundo.
func ponto_da_magia() -> Vector3:
	var base := _cristal.global_position if _cristal else global_position + Vector3.UP * 1.2
	return base + -global_transform.basis.z * 0.3


static func material_cristal() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	# Sem sombra (igual à chama da tocha): a luz ambiente azulada da cena
	# somada à emissão lavava o cristal para um branco-ciano em vez do azul
	# vivo pretendido (achado em 21/10/2026 comparando com a referência).
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = COR_CRISTAL
	mat.emission_enabled = true
	mat.emission = COR_CRISTAL
	mat.emission_energy_multiplier = 1.6
	return mat
