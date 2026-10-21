extends Node
class_name ControladorEstados
## Estados de magia (proposta técnica, seção 3: queimando, molhado,
## eletrizado, lento) para qualquer ser que receba dano: mago, inimigos e
## criaturas invocadas usam este mesmo nó, em vez de cada um ter sua cópia.
## O "dono" (nó pai) só precisa de receber_dano().
##
## Interações por etiqueta (proposta técnica, seção 3, "Interações por
## etiquetas"):
## - molhado apaga quem está queimando, e quem está molhado não pega fogo;
## - eletricidade em quem está molhado dá dano dobrado e se espalha num raio.
##
## Sinal visual (ADR-017 pede feedback claro): uma camada de cor por cima do
## corpo inteiro do dono (material_overlay), barata e legível de longe, no
## estilo de cor lisa do ADR-007. Só uma cor por vez, pela prioridade abaixo.

signal estados_mudaram(nomes: Array)

const MULTIPLICADOR_LENTO := 0.5
const DANO_QUEIMANDO_POR_TICK := 3.0
const INTERVALO_QUEIMANDO_S := 1.0
const DANO_ELETRICO := 6.0
const MULTIPLICADOR_ELETRICO_MOLHADO := 2.0
const RAIO_ELETRICO_MOLHADO := 2.5
const DURACAO_PISCADA_CHOQUE_S := 0.35

## Ordem de prioridade da cor: o choque é rápido e mais importante de ver.
const CORES := {
	"eletrizado": Color(1.0, 0.95, 0.2, 0.8),
	"queimando": Color(1.0, 0.35, 0.0, 0.65),
	"molhado": Color(0.1, 0.4, 1.0, 0.6),
	"lento": Color(0.55, 0.9, 1.0, 0.5),
}

var _lento_restante_s := 0.0
var _molhado_restante_s := 0.0
var _ticks_queimando_restantes := 0
var _tempo_ate_proximo_tick := 0.0
var _piscada_choque_s := 0.0
var _tempo := 0.0
var _estados_anteriores: Array = []
var _material_camada: StandardMaterial3D = null


func aplicar(nome_estado: String, duracao_s: float) -> void:
	if duracao_s <= 0.0:
		return
	match nome_estado:
		"lento":
			_lento_restante_s = maxf(_lento_restante_s, duracao_s)
		"molhado":
			_molhado_restante_s = maxf(_molhado_restante_s, duracao_s)
			_ticks_queimando_restantes = 0
		"queimando":
			if esta_molhado():
				return
			_iniciar_queimando(duracao_s)
		"eletrizado":
			_piscada_choque_s = DURACAO_PISCADA_CHOQUE_S
			_dar_choque()
	_atualizar_visual()


func multiplicador_velocidade() -> float:
	return MULTIPLICADOR_LENTO if _lento_restante_s > 0.0 else 1.0


func esta_molhado() -> bool:
	return _molhado_restante_s > 0.0


func esta_queimando() -> bool:
	return _ticks_queimando_restantes > 0


## Estados ativos agora, na ordem de prioridade da cor.
func ativos() -> Array:
	var lista: Array = []
	if _piscada_choque_s > 0.0:
		lista.append("eletrizado")
	if esta_queimando():
		lista.append("queimando")
	if esta_molhado():
		lista.append("molhado")
	if _lento_restante_s > 0.0:
		lista.append("lento")
	return lista


func _physics_process(delta: float) -> void:
	_tempo += delta
	_lento_restante_s = maxf(0.0, _lento_restante_s - delta)
	_molhado_restante_s = maxf(0.0, _molhado_restante_s - delta)
	_piscada_choque_s = maxf(0.0, _piscada_choque_s - delta)
	if _ticks_queimando_restantes > 0:
		_tempo_ate_proximo_tick -= delta
		if _tempo_ate_proximo_tick <= 0.0:
			_tick_queimando()
	_atualizar_visual()


## Um tick de dano já na hora e os outros a cada segundo, para parecer fogo
## queimando aos poucos. Reaplicar estende a duração, não soma um segundo
## incêndio com dano em dobro.
func _iniciar_queimando(duracao_s: float) -> void:
	var novos_ticks := int(ceili(duracao_s / INTERVALO_QUEIMANDO_S))
	var ja_estava_queimando := _ticks_queimando_restantes > 0
	_ticks_queimando_restantes = maxi(_ticks_queimando_restantes, novos_ticks)
	if not ja_estava_queimando:
		_tick_queimando()


func _tick_queimando() -> void:
	_ticks_queimando_restantes -= 1
	_tempo_ate_proximo_tick = INTERVALO_QUEIMANDO_S
	_dono_recebe_dano(DANO_QUEIMANDO_POR_TICK)


func _dar_choque() -> void:
	if not esta_molhado():
		_dono_recebe_dano(DANO_ELETRICO)
		return
	var dono := get_parent() as Node3D
	_dono_recebe_dano(DANO_ELETRICO * MULTIPLICADOR_ELETRICO_MOLHADO)
	if dono:
		Host.espalhar_eletricidade(dono.global_position, RAIO_ELETRICO_MOLHADO, DANO_ELETRICO, [dono])


func _dono_recebe_dano(dano: float) -> void:
	var dono := get_parent() as Node3D
	if dono and dono.has_method("receber_dano"):
		Host.aplicar_dano(dono, dano, dono.global_position, 0.0)


func _atualizar_visual() -> void:
	var atuais := ativos()
	if atuais != _estados_anteriores:
		_estados_anteriores = atuais
		estados_mudaram.emit(atuais)
		_trocar_camada(atuais)
	if _material_camada and not atuais.is_empty() and atuais[0] in ["queimando", "eletrizado"]:
		# Fogo pulsa devagar, choque pisca rápido: dá vida sem partículas.
		var velocidade := 30.0 if atuais[0] == "eletrizado" else 8.0
		var base: Color = CORES[atuais[0]]
		_material_camada.albedo_color.a = base.a * (0.8 + 0.2 * sin(_tempo * velocidade))


func _trocar_camada(atuais: Array) -> void:
	var dono := get_parent()
	if dono == null:
		return
	if atuais.is_empty():
		_material_camada = null
	else:
		var cor: Color = CORES[atuais[0]]
		_material_camada = StandardMaterial3D.new()
		_material_camada.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material_camada.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material_camada.albedo_color = cor
		_material_camada.emission_enabled = true
		_material_camada.emission = Color(cor.r, cor.g, cor.b)
	for malha in dono.find_children("*", "MeshInstance3D", true, false):
		(malha as MeshInstance3D).material_overlay = _material_camada


## Para testes e para o HUD: a cor que está por cima do corpo agora.
func camada_atual() -> StandardMaterial3D:
	return _material_camada
