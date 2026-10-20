extends RefCounted
class_name Validador
## Confere a ficha de magia contra listas fechadas e limites (proposta
## técnica, seções 3 e 5). A IA (quando existir, Fase 2) só sugere valores;
## quem decide o que vale é sempre este validador, nunca a IA.

const MATERIAIS_VALIDOS := ["pedra", "agua", "fogo", "metal", "madeira"]
const FORMAS_VALIDAS := ["esfera", "ovo", "cubo"]

const DURACAO_MAXIMA_S := 8.0
const DANO_MAXIMO := 30.0
const RAIO_EXPLOSAO_MAXIMO := 4.0
const EMPURRAO_MAXIMO := 6.0
const VELOCIDADE_MAXIMA := 25.0


## Recebe uma ficha (Dictionary) e devolve uma cópia corrigida, cortando
## tudo que passar dos limites e substituindo valores fora das listas
## fechadas por um padrão seguro.
static func validar_ficha(ficha: Dictionary) -> Dictionary:
	var corrigida := ficha.duplicate(true)
	var componentes: Array = corrigida.get("componentes", [])
	for i in componentes.size():
		componentes[i] = _validar_componente(componentes[i])
	corrigida["componentes"] = componentes
	return corrigida


static func _validar_componente(componente: Dictionary) -> Dictionary:
	var c := componente.duplicate(true)
	if c.get("tipo") == "projetil":
		c["material"] = _escolher_valido(c.get("material", ""), MATERIAIS_VALIDOS, "pedra")
		c["forma"] = _escolher_valido(c.get("forma", ""), FORMAS_VALIDAS, "esfera")
		c["velocidade"] = clampf(c.get("velocidade", 10.0), 1.0, VELOCIDADE_MAXIMA)
		var impactos: Array = c.get("ao_impactar", [])
		for i in impactos.size():
			impactos[i] = _validar_componente(impactos[i])
		c["ao_impactar"] = impactos
	elif c.get("tipo") == "explosao":
		c["raio_m"] = clampf(c.get("raio_m", 2.0), 0.5, RAIO_EXPLOSAO_MAXIMO)
		c["dano"] = clampf(c.get("dano", 5.0), 0.0, DANO_MAXIMO)
		c["empurrao"] = clampf(c.get("empurrao", 0.0), 0.0, EMPURRAO_MAXIMO)
	return c


static func _escolher_valido(valor: String, lista: Array, padrao: String) -> String:
	if valor in lista:
		return valor
	return padrao
