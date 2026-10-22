extends RefCounted
class_name Validador
## Confere a ficha de magia contra listas fechadas e limites (proposta
## técnica, seções 3 e 5). A IA (quando existir, Fase 2) só sugere valores;
## quem decide o que vale é sempre este validador, nunca a IA.

const MATERIAIS_VALIDOS := ["pedra", "agua", "fogo", "metal", "madeira"]
const FORMAS_VALIDAS := ["esfera", "ovo", "cubo"]
## Proposta técnica, seção 3: "estados (queimando, molhado, eletrizado, cego,
## lento)": todos existem.
const ESTADOS_VALIDOS := ["queimando", "lento", "molhado", "eletrizado", "cego", "preso"]
## Proposta técnica, seção 3, exemplo do "Pombo de Pedra": só
## "perseguir_inimigo_proximo" está implementado por enquanto.
const CORPOS_VALIDOS := ["ave", "quadrupede", "verme", "bolha"]
const COMPORTAMENTOS_VALIDOS := ["perseguir_inimigo_proximo"]
## O que pode acontecer quando um projétil bate. Projétil dentro de projétil
## o jogo não sabe executar; aceitar abriria espaço para fichas aninhadas
## centenas de vezes (achado em revisão de segurança: não quebrava, mas
## enchia o log de "Max recursion reached").
const EFEITOS_DE_IMPACTO := ["explosao", "estado", "area"]
## Teto de tamanho das listas. A mana já impede conjurar uma ficha gigante,
## mas validar 500 componentes à toa não serve para nada.
const MAXIMO_COMPONENTES := 8
const MAXIMO_EFEITOS_DE_IMPACTO := 4

const DURACAO_MAXIMA_S := 8.0
const DANO_MAXIMO := 30.0
const RAIO_EXPLOSAO_MAXIMO := 4.0
const EMPURRAO_MAXIMO := 6.0
const VELOCIDADE_MAXIMA := 25.0
const CURA_MAXIMA := 25.0
const REDUCAO_ESCUDO_MAXIMA := 0.9 # nunca 100%: escudo reduz dano, não anula
const VIDA_INVOCACAO_MAXIMA := 40.0
const ESCALA_INVOCACAO_MINIMA := 0.3
const ESCALA_INVOCACAO_MAXIMA := 2.0
const DANO_CONTATO_MAXIMO := 8.0 # menor que o da explosão: repete a cada ataque
const INTERVALO_LANCADOR_MINIMO_S := 0.8 # menos que isso vira metralhadora
const RAIO_AREA_MAXIMO := 4.0
const DANO_AREA_POR_S_MAXIMO := 8.0 # menor que a explosão: repete a cada segundo
const LARGURA_PAREDE_MAXIMA := 4.0
const ALTURA_PAREDE_MAXIMA := 3.0
const DISTANCIA_PAREDE_MAXIMA := 6.0
const DISTANCIA_TELEPORTE_MAXIMA := 8.0

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
const CUSTO_BASE_ESTADO := 4.0
const CUSTO_POR_DURACAO_ESTADO := 1.0
const CUSTO_BASE_INVOCACAO := 8.0
const CUSTO_POR_VIDA_INVOCACAO := 0.3
const CUSTO_POR_DURACAO_INVOCACAO := 1.0
const CUSTO_POR_DANO_CONTATO := 0.5
const CUSTO_BASE_AREA := 5.0
const CUSTO_POR_RAIO_AREA := 1.0
const CUSTO_POR_DURACAO_AREA := 0.5
const CUSTO_BASE_PAREDE := 5.0
const CUSTO_POR_M2_PAREDE := 1.0
const CUSTO_POR_DURACAO_PAREDE := 0.5
const CUSTO_BASE_TELEPORTE := 6.0
const CUSTO_POR_M_TELEPORTE := 1.0
const CUSTO_BASE_LANCADOR := 4.0
## O custo do lançador é uma estimativa: o custo de um disparo vezes quantos
## disparos caberiam em REFERENCIA_DISPAROS_S segundos. Ajustável jogando.
const REFERENCIA_DISPAROS_S := 3.0


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
	corrigida["componentes"] = _lista_de_dicionarios(corrigida.get("componentes")).slice(0, MAXIMO_COMPONENTES).map(_validar_componente)
	return corrigida


static func _validar_componente(componente: Dictionary) -> Dictionary:
	var c := componente.duplicate(true)
	# A IA escreve em português e pode "corrigir" o nome: "explosão",
	# "Área", "invocação". Sem normalizar, nada disso batia com as listas e
	# a magia virava "não entendi" (conferido de propósito).
	if typeof(c.get("tipo")) == TYPE_STRING:
		c["tipo"] = _normalizar(c["tipo"])
	if c.get("tipo") == "projetil":
		c["material"] = _escolher_valido(_como_texto(c.get("material")), MATERIAIS_VALIDOS, "pedra")
		c["forma"] = _escolher_valido(_como_texto(c.get("forma")), FORMAS_VALIDAS, "esfera")
		c["velocidade"] = clampf(_como_numero(c.get("velocidade"), 10.0), 1.0, VELOCIDADE_MAXIMA)
		c["ao_impactar"] = _lista_de_dicionarios(c.get("ao_impactar")) \
			.filter(func(e): return _normalizar(_como_texto(e.get("tipo"))) in EFEITOS_DE_IMPACTO) \
			.slice(0, MAXIMO_EFEITOS_DE_IMPACTO) \
			.map(_validar_componente)
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
	elif c.get("tipo") == "estado":
		c["nome_estado"] = _escolher_valido(_como_texto(c.get("nome_estado")), ESTADOS_VALIDOS, "lento")
		c["duracao_s"] = clampf(_como_numero(c.get("duracao_s"), 0.0), 0.0, DURACAO_MAXIMA_S)
	elif c.get("tipo") == "invocacao":
		c["corpo"] = _escolher_valido(_como_texto(c.get("corpo")), CORPOS_VALIDOS, "bolha")
		c["material"] = _escolher_valido(_como_texto(c.get("material")), MATERIAIS_VALIDOS, "pedra")
		c["comportamento"] = _escolher_valido(_como_texto(c.get("comportamento")), COMPORTAMENTOS_VALIDOS, "perseguir_inimigo_proximo")
		c["escala"] = clampf(_como_numero(c.get("escala"), 1.0), ESCALA_INVOCACAO_MINIMA, ESCALA_INVOCACAO_MAXIMA)
		c["vida"] = clampf(_como_numero(c.get("vida"), 10.0), 0.0, VIDA_INVOCACAO_MAXIMA)
		c["duracao_s"] = clampf(_como_numero(c.get("duracao_s"), 0.0), 0.0, DURACAO_MAXIMA_S)
		c["dano_contato"] = clampf(_como_numero(c.get("dano_contato"), 0.0), 0.0, DANO_CONTATO_MAXIMO)
	elif c.get("tipo") == "area":
		c["raio_m"] = clampf(_como_numero(c.get("raio_m"), 2.0), 0.5, RAIO_AREA_MAXIMO)
		c["duracao_s"] = clampf(_como_numero(c.get("duracao_s"), 0.0), 0.0, DURACAO_MAXIMA_S)
		c["dano_por_s"] = clampf(_como_numero(c.get("dano_por_s"), 0.0), 0.0, DANO_AREA_POR_S_MAXIMO)
		c["material"] = _escolher_valido(_como_texto(c.get("material")), MATERIAIS_VALIDOS, "pedra")
		# Estado é opcional aqui: fora da lista vira "nenhum", não um padrão.
		var estado := _normalizar(_como_texto(c.get("nome_estado")))
		c["nome_estado"] = estado if estado in ESTADOS_VALIDOS else ""
	elif c.get("tipo") == "parede":
		c["largura_m"] = clampf(_como_numero(c.get("largura_m"), 3.0), 0.5, LARGURA_PAREDE_MAXIMA)
		c["altura_m"] = clampf(_como_numero(c.get("altura_m"), 2.0), 0.5, ALTURA_PAREDE_MAXIMA)
		c["duracao_s"] = clampf(_como_numero(c.get("duracao_s"), 0.0), 0.0, DURACAO_MAXIMA_S)
		c["distancia_m"] = clampf(_como_numero(c.get("distancia_m"), 3.0), 1.0, DISTANCIA_PAREDE_MAXIMA)
		c["material"] = _escolher_valido(_como_texto(c.get("material")), MATERIAIS_VALIDOS, "pedra")
	elif c.get("tipo") == "teleporte":
		c["distancia_m"] = clampf(_como_numero(c.get("distancia_m"), 0.0), 0.0, DISTANCIA_TELEPORTE_MAXIMA)
	elif c.get("tipo") == "lancador":
		c["anexado_a"] = _como_texto(c.get("anexado_a"))
		c["intervalo_s"] = clampf(_como_numero(c.get("intervalo_s"), 1.5), INTERVALO_LANCADOR_MINIMO_S, DURACAO_MAXIMA_S)
		# Aceita o formato da proposta técnica (ao_impactar ao lado do
		# "projetil") e também dentro dele; vira sempre um projétil completo.
		var projetil := {}
		if typeof(c.get("projetil")) == TYPE_DICTIONARY:
			projetil = (c["projetil"] as Dictionary).duplicate(true)
		if not projetil.has("ao_impactar") and c.has("ao_impactar"):
			projetil["ao_impactar"] = c["ao_impactar"]
		projetil["tipo"] = "projetil"
		c["projetil"] = _validar_componente(projetil)
		c.erase("ao_impactar")
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
	var normalizado := _normalizar(valor)
	if normalizado in lista:
		return normalizado
	return padrao


const _SEM_ACENTO := {
	"á": "a", "à": "a", "â": "a", "ã": "a", "é": "e", "ê": "e", "í": "i",
	"ó": "o", "ô": "o", "õ": "o", "ú": "u", "ü": "u", "ç": "c",
}


## Minúsculas, sem acento e sem espaço nas pontas: "  Água " vira "agua".
static func _normalizar(texto: String) -> String:
	var resultado := texto.strip_edges().to_lower()
	for letra in _SEM_ACENTO:
		resultado = resultado.replace(letra, _SEM_ACENTO[letra])
	return resultado


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
	elif tipo == "estado":
		custo += CUSTO_BASE_ESTADO
		custo += componente.get("duracao_s", 0.0) * CUSTO_POR_DURACAO_ESTADO
	elif tipo == "invocacao":
		custo += CUSTO_BASE_INVOCACAO
		custo += componente.get("vida", 0.0) * CUSTO_POR_VIDA_INVOCACAO
		custo += componente.get("duracao_s", 0.0) * CUSTO_POR_DURACAO_INVOCACAO
		custo += componente.get("dano_contato", 0.0) * CUSTO_POR_DANO_CONTATO
	elif tipo == "area":
		var duracao: float = componente.get("duracao_s", 0.0)
		custo += CUSTO_BASE_AREA
		custo += componente.get("raio_m", 0.0) * CUSTO_POR_RAIO_AREA
		custo += duracao * CUSTO_POR_DURACAO_AREA
		custo += componente.get("dano_por_s", 0.0) * duracao * CUSTO_POR_DANO
		if componente.get("nome_estado", "") != "":
			custo += duracao * CUSTO_POR_DURACAO_AREA
	elif tipo == "parede":
		custo += CUSTO_BASE_PAREDE
		custo += componente.get("largura_m", 0.0) * componente.get("altura_m", 0.0) * CUSTO_POR_M2_PAREDE
		custo += componente.get("duracao_s", 0.0) * CUSTO_POR_DURACAO_PAREDE
	elif tipo == "teleporte":
		custo += CUSTO_BASE_TELEPORTE + componente.get("distancia_m", 0.0) * CUSTO_POR_M_TELEPORTE
	elif tipo == "lancador":
		var disparos: float = REFERENCIA_DISPAROS_S / componente.get("intervalo_s", 1.5)
		custo += CUSTO_BASE_LANCADOR + _custo_componente(componente.get("projetil", {})) * disparos
	return custo


## Verdadeiro se a ficha não faz nada de verdade: vazia, sem componentes, ou
## só com componentes "fantasma" (dano, duração ou quantidade zerados). Era a
## regra do "não entendi" da magia por texto; agora confere que toda receita
## de runas vira uma magia que faz alguma coisa. Valida antes de olhar os
## campos, para "componentes": null não passar despercebido.
static func sem_efeito_real(ficha: Dictionary) -> bool:
	if ficha.is_empty():
		return true
	var componentes: Array = validar_ficha(ficha).get("componentes", [])
	for componente in componentes:
		if _componente_tem_efeito_real(componente):
			return false
	return true


## Confere se um componente (ou algum efeito dentro do seu "ao_impactar")
## faz alguma coisa de verdade, independente do tipo. Generalizado para
## incluir "cura" (proposta técnica, seção 3) sem repetir a regra de
## "projétil fantasma" (dano/empurrão zerados) achada com o Vitor na
## Fase 2: um componente sem efeito real também conta como "não entendi".
static func _componente_tem_efeito_real(componente: Dictionary) -> bool:
	var tipo = componente.get("tipo")
	if tipo == "explosao" and (componente.get("dano", 0.0) > 0.0 or componente.get("empurrao", 0.0) != 0.0):
		return true
	if tipo == "cura" and componente.get("quantidade", 0.0) > 0.0:
		return true
	if tipo == "escudo" and componente.get("reducao", 0.0) > 0.0 and componente.get("duracao_s", 0.0) > 0.0:
		return true
	if tipo == "estado" and componente.get("duracao_s", 0.0) > 0.0:
		return true
	if tipo == "invocacao" and componente.get("vida", 0.0) > 0.0 and componente.get("duracao_s", 0.0) > 0.0:
		return true
	if tipo == "lancador" and _componente_tem_efeito_real(componente.get("projetil", {})):
		return true
	if tipo == "parede" and componente.get("duracao_s", 0.0) > 0.0:
		return true
	if tipo == "teleporte" and componente.get("distancia_m", 0.0) > 0.0:
		return true
	if tipo == "area" and componente.get("duracao_s", 0.0) > 0.0 and (componente.get("dano_por_s", 0.0) > 0.0 or componente.get("nome_estado", "") != ""):
		return true
	for efeito in (componente.get("ao_impactar", []) as Array):
		if _componente_tem_efeito_real(efeito):
			return true
	return false
