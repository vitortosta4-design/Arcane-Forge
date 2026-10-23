class_name MaosPrimeiraPessoa
extends Node3D
## O que o jogador vê de si mesmo em primeira pessoa, como na referência:
## a mão esquerda aberta à frente (de onde a magia sai) e a direita segurando
## o cajado. Modelo: assets/modelos/mago/mago_1p.glb (mesmas luvas do mago,
## gerado por arte/personagens/mago/mago.py), já na escala e na posição da
## câmera. Parado, os dedinhos da mão aberta fazem uma ondinha lenta (pedido
## do Vitor: "dedinhos com movimento suave e fofo"); ao conjurar, a mão recolhe
## e abre em leque, com um brilho na palma.

const MODELO := preload("res://assets/modelos/mago/mago_1p.glb")
const DURACAO_BRILHO_S := 0.3

var _modelo: Node3D
var _anim: AnimationPlayer
var _palma: MeshInstance3D
var _brilho: MeshInstance3D
var _fase_passo := 0.0
var _brilho_restante := 0.0


func _ready() -> void:
	_modelo = MODELO.instantiate() as Node3D
	_modelo.name = "Modelo"
	add_child(_modelo)
	for m in _modelo.find_children("*", "GeometryInstance3D", true, false):
		(m as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_anim = _modelo.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim == null or not _anim.has_animation("Parado1P"):
		push_warning("MaosPrimeiraPessoa: mago_1p.glb sem AnimationPlayer ou sem 'Parado1P'; as mãos ficam paradas.")
	else:
		_anim.get_animation("Parado1P").loop_mode = Animation.LOOP_LINEAR
		_anim.animation_finished.connect(func(_n): _anim.play("Parado1P", 0.15))
		_anim.play("Parado1P")
	_palma = _modelo.find_child("Mao1PEPalma", true, false) as MeshInstance3D
	if _palma == null:
		push_warning("MaosPrimeiraPessoa: mago_1p.glb sem Mao1PEPalma; a magia sai da frente da câmera.")
	_brilho = MeshInstance3D.new()
	_brilho.name = "Brilho"
	var esfera := SphereMesh.new()
	esfera.radius = 0.05
	esfera.height = 0.1
	esfera.radial_segments = 8
	esfera.rings = 4
	_brilho.mesh = esfera
	_brilho.material_override = VisualMago.material_cristal()
	_brilho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_brilho.visible = false
	add_child(_brilho)


func animar(delta: float, velocidade_horizontal: float, no_chao: bool) -> void:
	var andando := clampf(velocidade_horizontal / 5.0, 0.0, 1.0) if no_chao else 0.0
	_fase_passo += delta * 9.0 * andando
	# Balanço do passo: as mãos sobem e descem de leve.
	_modelo.position = Vector3(sin(_fase_passo * 0.5) * 0.012, absf(sin(_fase_passo * 0.5)) * -0.018, 0.0) * andando
	if _brilho_restante > 0.0:
		_brilho_restante = maxf(0.0, _brilho_restante - delta)
		var t := sin(_brilho_restante / DURACAO_BRILHO_S * PI)
		_brilho.global_position = ponto_da_magia()
		_brilho.scale = Vector3.ONE * (0.4 + t * 1.2)
		_brilho.visible = _brilho_restante > 0.0


func conjurar() -> void:
	if _anim and _anim.has_animation("Conjurar1P"):
		_anim.play("Conjurar1P", 0.05)
	else:
		push_warning("MaosPrimeiraPessoa: sem a animação 'Conjurar1P'.")
	_brilho_restante = DURACAO_BRILHO_S


## Ponto um pouco à frente da palma da mão esquerda, em coordenadas do mundo.
func ponto_da_magia() -> Vector3:
	var frente := -global_transform.basis.z
	if _palma == null:
		return global_position + frente * 0.5
	# O nó da palma fica na origem do modelo (as peças foram modeladas em
	# coordenadas absolutas); o centro da caixa da malha é a palma de verdade.
	return _palma.global_transform * _palma.get_aabb().get_center() + frente * 0.15
