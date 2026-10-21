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
const CURA_MAXIMA := 25.0
const REDUCAO_ESCUDO_MAXIMA := 0.9 # nunca 100%: escudo reduz dano, não anula

const CUSTO_BASE_PROJETIL := 5.0
const CUSTO_POR_VELOCIDADE := 0.3
const CUSTO_BASE_EXPLOSAO := 5.0
const CUSTO_POR_DANO := 0.4
const CUSTO_POR_RAIO := 1.0
const CUSTO_BASE_CURA := 5.0
const CUSTO_POR_CURA := 0.5
const CUSTO_BASE_ESCUDO := 5.0
const CUSTO_POR_REDUCAO := 20.0
const CUSTO_POR_DURACAO_ESCUDO := 1.0


## Recebe uma ficha (Dictionary) e devolve uma cópia corrigida, cortando
## tudo que passar dos limites e substituindo valores fora das listas
## fechadas por um padrão seguro.
##
## A IA pode mandar qualquer coisa nos campos (um "componentes": null, um
## "dano": "muito", uma lista com lixo dentro...). Achado numa revisão de
## segurança: ler esses campos direto numa variável de tipo fixo (Array,
## float) quebra no meio e faz a função toda devolver o valor padrão do seu
## tipo de retorno sem avisar ninguém — exatamente o "passa sem ser
## entendido direito" que esta função existe para evitar. Por isso cada
## leitura abaixo confere o tipo de verdade antes de confiar nele.
static func validar_ficha(ficha: Dictionary) -> Dictionary:
	var corrigida := ficha.duplicate(true)
	corrigida["componentes"] = _lista_de_dicionarios(corrigida.get("componentes")).map(_validar_componente)
	return corrigida


static func _validar_componente(componente: Dictionary) -> Dictionary:
	var c := componente.duplicate(true)
	if c.get("tipo") == "projetil":
		c["material"] = _escolher_valido(_como_texto(c.get("material")), MATERIAIS_VALIDOS, "pedra")
		c["forma"] = _escolher_valido(_como_texto(c.get("forma")), FORMAS_VALIDAS, "esfera")
		c["velocidade"] = clampf(_como_numero(c.get("velocidade"), 10.0), 1.0, VELOCIDADE_MAXIMA)
		c["ao_impactar"] = _lista_de_dicionarios(c.get("ao_impactar")).map(_validar_componente)
	elif c.get("tipo") == "explosao":
		c["raio_m"] = clampf(_como_numero(c.get("raio_m"), 2.0), 0.5, RAIO_EXPLOSAO_MAXIMO)
		c["dano"] = clampf(_como_numero(c.get("dano"), 5.0), 0.0, DANO_MAXIMO)
		# Empurrão negativo puxa para o centro em vez de afastar (proposta
		# técnica, seção 3: "empurrar/puxar" é o mesmo componente com sinais
		# opostos, ex.: um mini buraco negro que atrai em vez de explodir).
		c["empurrao"] = clampf(_como_numero(c.get("empurrao"), 0.0), -EMPURRAO_MAXIMO, EMPURRAO_MAXIMO)
	elif c.get("tipo") == "cura":
		c["quantidade"] = clampf(_como_numero(c.get("quantidade"), 0.0), 0.0, CURA_MAXIMA)
	elif c.get("tipo") == "escudo":
		c["reducao"] = clampf(_como_numero(c.get("reducao"), 0.0), 0.0, REDUCAO_ESCUDO_MAXIMA)
		c["duracao_s"] = clampf(_como_numero(c.get("duracao_s"), 0.0), 0.0, DURACAO_MAXIMA_S)
	return c


## Só aceita de volta uma Array cujos itens sejam Dictionary; qualquer outra
## coisa (null, string, número, lista com lixo dentro) vira lista vazia.
static func _lista_de_dicionarios(valor) -> Array:
	if typeof(valor) != TYPE_ARRAY:
		return []
	var somente_dicionarios: Array = []
	for item in valor:
		if typeof(item) == TYPE_DICTIONARY:
			somente_dicionarios.append(item)
	return somente_dicionarios


## Converte com segurança para número; se não for int/float de verdade
## (string, null, lista...), usa o padrão.
static func _como_numero(valor, padrao: float) -> float:
	if typeof(valor) == TYPE_FLOAT or typeof(valor) == TYPE_INT:
		return float(valor)
	return padrao


## Converte com segurança para texto; se não for String de verdade, devolve
## vazio (o que faz _escolher_valido cair no padrão da lista fechada).
static func _como_texto(valor) -> String:
	if typeof(valor) == TYPE_STRING:
		return valor
	return ""


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
	elif tipo == "cura":
		custo += CUSTO_BASE_CURA
		custo += componente.get("quantidade", 0.0) * CUSTO_POR_CURA
	elif tipo == "escudo":
		custo += CUSTO_BASE_ESCUDO
		custo += componente.get("reducao", 0.0) * CUSTO_POR_REDUCAO
		custo += componente.get("duracao_s", 0.0) * CUSTO_POR_DURACAO_ESCUDO
	return custo
