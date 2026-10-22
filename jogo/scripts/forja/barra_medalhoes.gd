class_name BarraMedalhoes
extends RefCounted
## Os 4 espaços de medalhão do mago (ADR-033, ADR-035). Cada medalhão tem
## sua própria recarga curta depois de usado; a mana continua valendo e é
## conferida pelo juiz (Host) na hora de conjurar, não aqui.

signal mudou

const ESPACOS := 4

var medalhoes: Array = [null, null, null, null]
var _recarga_restante: Array[float] = [0.0, 0.0, 0.0, 0.0]


func vazio(i: int) -> bool:
	return i >= 0 and i < ESPACOS and medalhoes[i] == null


func primeiro_vazio() -> int:
	for i in ESPACOS:
		if medalhoes[i] == null:
			return i
	return -1


## Põe o medalhão no espaço pedido (ou no primeiro vazio, com -1). Só em
## espaço vazio: para trocar, quebre um antes. Devolve o espaço usado ou -1.
func equipar(medalhao: Dictionary, espaco := -1) -> int:
	var i := espaco if espaco >= 0 else primeiro_vazio()
	if not vazio(i):
		return -1
	medalhoes[i] = medalhao
	_recarga_restante[i] = 0.0
	mudou.emit()
	return i


func quebrar(i: int) -> bool:
	if i < 0 or i >= ESPACOS or medalhoes[i] == null:
		return false
	medalhoes[i] = null
	_recarga_restante[i] = 0.0
	mudou.emit()
	return true


func pronto(i: int) -> bool:
	return i >= 0 and i < ESPACOS and medalhoes[i] != null and _recarga_restante[i] <= 0.0


## 0 = pronto, 1 = acabou de ser usado.
func fracao_recarga(i: int) -> float:
	if medalhoes[i] == null:
		return 0.0
	var total: float = medalhoes[i].get("recarga_s", 1.0)
	return clampf(_recarga_restante[i] / maxf(total, 0.01), 0.0, 1.0)


func iniciar_recarga(i: int) -> void:
	if medalhoes[i] != null:
		_recarga_restante[i] = float(medalhoes[i].get("recarga_s", 1.0))


func avancar(delta: float) -> void:
	for i in ESPACOS:
		_recarga_restante[i] = maxf(0.0, _recarga_restante[i] - delta)
