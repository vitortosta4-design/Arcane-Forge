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

const CUSTO_BASE_PROJETIL := 5.0
const CUSTO_POR_VELOCIDADE := 0.3
const CUSTO_BASE_EXPLOSAO := 5.0
const CUSTO_POR_DANO := 0.4
const CUSTO_POR_RAIO := 1.0


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


## Cor low poly aproximada de cada material (ADR-007), usada pelo projétil
## e pela explosão para o jogador conseguir ver a diferença entre uma magia
## de água, pedra, metal, madeira ou fogo (achado testando com o Vitor:
## antes tudo tinha a cor fixa de fogo, não importa o material da ficha).
static func cor_para_material(material: String) -> Color:
	match material:
		"agua":
			return Color(0.25, 0.55, 0.95)
		"pedra":
			return Color(0.55, 0.5, 0.45)
		"metal":
			return Color(0.75, 0.78, 0.82)
		"madeira":
			return Color(0.5, 0.35, 0.15)
		_:
			return Color(1, 0.45, 0.05) # fogo, e qualquer coisa fora da lista


static func _escolher_valido(valor: String, lista: Array, padrao: String) -> String:
	if valor in lista:
		return valor
	return padrao


## O custo de mana é sempre calculado pelo jogo a partir dos componentes já
## validados, nunca lido de um número que a IA (ou a ficha escrita à mão)
## tenha sugerido (proposta técnica, seção 3).
static func calcular_custo_mana(ficha_validada: Dictionary) -> float:
	var total := 0.0
	for componente in ficha_validada.get("componentes", []):
		total += _custo_componente(componente)
	return total


static func _custo_componente(componente: Dictionary) -> float:
	var tipo = componente.get("tipo")
	var custo := 0.0
	if tipo == "projetil":
		custo += CUSTO_BASE_PROJETIL + componente.get("velocidade", 10.0) * CUSTO_POR_VELOCIDADE
		for efeito in componente.get("ao_impactar", []):
			custo += _custo_componente(efeito)
	elif tipo == "explosao":
		custo += CUSTO_BASE_EXPLOSAO
		custo += componente.get("dano", 0.0) * CUSTO_POR_DANO
		custo += componente.get("raio_m", 0.0) * CUSTO_POR_RAIO
	return custo
