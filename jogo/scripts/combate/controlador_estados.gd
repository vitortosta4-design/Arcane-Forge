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

const MULTIPLICADOR_LENTO := 0.5
const DANO_QUEIMANDO_POR_TICK := 3.0
const INTERVALO_QUEIMANDO_S := 1.0
const DANO_ELETRICO := 6.0
const MULTIPLICADOR_ELETRICO_MOLHADO := 2.0
const RAIO_ELETRICO_MOLHADO := 2.5

var _lento_restante_s := 0.0
var _molhado_restante_s := 0.0
var _ticks_queimando_restantes := 0
var _tempo_ate_proximo_tick := 0.0


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
			_dar_choque()


func multiplicador_velocidade() -> float:
	return MULTIPLICADOR_LENTO if _lento_restante_s > 0.0 else 1.0


func esta_molhado() -> bool:
	return _molhado_restante_s > 0.0


func esta_queimando() -> bool:
	return _ticks_queimando_restantes > 0


func _physics_process(delta: float) -> void:
	_lento_restante_s = maxf(0.0, _lento_restante_s - delta)
	_molhado_restante_s = maxf(0.0, _molhado_restante_s - delta)
	if _ticks_queimando_restantes > 0:
		_tempo_ate_proximo_tick -= delta
		if _tempo_ate_proximo_tick <= 0.0:
			_tick_queimando()


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
