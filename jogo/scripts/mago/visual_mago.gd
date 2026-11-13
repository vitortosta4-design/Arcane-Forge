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
## O modelo tem ~1,4 m com o chapéu (proporção da folha, 7ª rodada: corpo e
## pernas mais longos). Aumentado por igual para os olhos ficarem perto da
## altura da câmera de primeira pessoa (1,6 m); altura total igual à de antes.
const ESCALA := 2.05
## Velocidade em que a animação Andar casa com o passo (m/s, já na escala do
## jogo). Acima ou abaixo disso ela acelera ou desacelera, para o pé não
## patinar no chão.
const VELOCIDADE_DO_PASSO := 4.8  # passada ~1,5x maior com as pernas novas (era 3,2)
const MISTURA_S := 0.15
## Durante a preparação a animação Conjurar toca acelerada: em 0,1 s ela já
## recolheu o braço (quadro 4 de 24) e está no meio do bote, que é quando a
## magia sai. Depois volta ao ritmo normal para segurar a pose e assentar.
const RITMO_PREPARO := 2.0
const COR_CRISTAL := Color(0.3, 0.62, 1.0)
## Peso no andar (auditoria de animação, item 6: "para de uma vez, sem
## assentar"). O corpo inclina para onde anda e, quando arranca ou para,
## balança numa mola até assentar; na parada ainda dá uma agachadinha.
## É só visual: a velocidade do mago continua respondendo na hora.
const INCLINACAO_ANDAR := 0.12   # radianos a VELOCIDADE_REFERENCIA (uns 7 graus)
const VELOCIDADE_REFERENCIA := 4.5
const MOLA_HZ := 2.6             # quantas balançadas por segundo
const MOLA_AMORTECIMENTO := 0.35 # 1 = para sem balançar; 0,35 = passa do ponto uma vez e assenta
const AGACHAR_NA_PARADA := 0.36  # empurrão na mola de achatar, por m/s perdido
const AGACHAR_NO_ARRANQUE := 0.12
## Teleporte (print, renascer) não pode virar um tranco: acima disso é ignorado.
const VELOCIDADE_MAXIMA_LIDA := 8.0

var _modelo: Node3D
## Inclinação atual: x = para a frente, y = para o lado direito (radianos).
var _inclinacao := Vector2.ZERO
var _vel_inclinacao := Vector2.ZERO
## Achatar: negativo = mais baixo e mais largo.
var _achatar := 0.0
var _vel_achatar := 0.0
var _posicao_anterior := Vector3.ZERO
var _tem_posicao_anterior := false
var _velocidade_anterior := 0.0
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
	_modelo = modelo
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
func animar(delta: float, velocidade_horizontal: float, no_chao: bool) -> void:
	_assentar(delta, velocidade_horizontal, no_chao)
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


## Uma mola amortecida: devolve Vector2(posição nova, velocidade nova).
## Analogia: a cabeça de um boneco de mola do painel do carro, que segue o
## carro e balança um pouco antes de parar.
static func mola(posicao: float, velocidade: float, alvo: float, delta: float) -> Vector2:
	var w := TAU * MOLA_HZ
	velocidade += (w * w * (alvo - posicao) - 2.0 * MOLA_AMORTECIMENTO * w * velocidade) * delta
	return Vector2(posicao + velocidade * delta, velocidade)


func _assentar(delta: float, velocidade_horizontal: float, no_chao: bool) -> void:
	if _modelo == null or delta <= 0.0:
		return # normal: chamado antes do _ready ou com o jogo pausado
	# Para onde o corpo está indo, medido pelo próprio deslocamento (vale para
	# andar de lado e de costas, e para o mago do parceiro no cooperativo).
	var local := Vector3.ZERO
	if _tem_posicao_anterior:
		var v := (global_position - _posicao_anterior) / delta
		if v.length() < VELOCIDADE_MAXIMA_LIDA:
			local = global_transform.basis.orthonormalized().inverse() * v
	_posicao_anterior = global_position
	_tem_posicao_anterior = true
	var alvo := Vector2(-local.z, local.x) / VELOCIDADE_REFERENCIA * INCLINACAO_ANDAR if no_chao else Vector2.ZERO
	var frente := mola(_inclinacao.x, _vel_inclinacao.x, alvo.x, delta)
	var lado := mola(_inclinacao.y, _vel_inclinacao.y, alvo.y, delta)
	_inclinacao = Vector2(frente.x, lado.x)
	_vel_inclinacao = Vector2(frente.y, lado.y)
	# Parou ou arrancou de uma vez: empurrão para baixo na mola de achatar.
	var mudanca := velocidade_horizontal - _velocidade_anterior
	_velocidade_anterior = velocidade_horizontal
	if no_chao and absf(mudanca) > 1.0:
		_vel_achatar -= absf(mudanca) * (AGACHAR_NA_PARADA if mudanca < 0.0 else AGACHAR_NO_ARRANQUE)
	var achatar := mola(_achatar, _vel_achatar, 0.0, delta)
	_achatar = clampf(achatar.x, -0.12, 0.08)
	_vel_achatar = achatar.y
	# O modelo olha para +Z dele (girado em PI): X positivo joga o topo para a
	# frente do mago; Z positivo joga o topo para a direita do mago.
	_modelo.rotation = Vector3(_inclinacao.x, PI, _inclinacao.y)
	_modelo.scale = Vector3(1.0 - _achatar * 0.5, 1.0 + _achatar, 1.0 - _achatar * 0.5) * ESCALA


## Clique: começa já a recolher o braço (antecipação), em ritmo dobrado.
func conjurar() -> void:
	_tocar_acao("Conjurar")
	if _anim and _acao == "Conjurar":
		_anim.speed_scale = RITMO_PREPARO


## A magia saiu: o resto da animação (braço esticado, volta) toca no ritmo
## normal. Se o mago levou dano no meio, a animação já é outra: não mexe.
func soltar_magia() -> void:
	if _anim and _acao == "Conjurar":
		_anim.speed_scale = 1.0


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
