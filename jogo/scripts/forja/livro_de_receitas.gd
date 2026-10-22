class_name LivroDeReceitas
extends RefCounted
## A "soma" da Forja de Runas (ADR-032, ADR-035): recebe as runas que o
## jogador pôs na bigorna e devolve a magia. Receitas fixas, estilo Dragon
## City: a mesma soma dá sempre a mesma magia, e a ordem das runas não
## importa. Toda combinação válida dá alguma coisa: sem receita, sai uma
## versão básica montada aqui a partir dos dados de cada runa.
##
## As receitas ficam em res://dados/receitas.json, legível e fácil de
## ajustar sem mexer em código. A ficha resultante passa pelo Validador como
## qualquer outra magia, então nem um erro no arquivo foge dos limites.

const CAMINHO := "res://dados/receitas.json"
const MAXIMO_RUNAS := 3
const MAXIMO_ELEMENTOS := 2

static var _dados: Dictionary = {}


static func dados() -> Dictionary:
	if _dados.is_empty():
		var texto := FileAccess.get_file_as_string(CAMINHO)
		var lido = JSON.parse_string(texto)
		_dados = lido if typeof(lido) == TYPE_DICTIONARY else {"runas": {}, "receitas": []}
	return _dados


static func runa(nome: String) -> Dictionary:
	return dados()["runas"].get(nome, {})


static func todas_as_runas() -> Array:
	return dados()["runas"].keys()


## Por que a combinação não pode ser forjada ("" quando pode).
static func problema(runas: Array) -> String:
	if runas.is_empty():
		return "Coloque pelo menos uma runa."
	if runas.size() > MAXIMO_RUNAS:
		return "No máximo %d runas por forja." % MAXIMO_RUNAS
	var formas := 0
	var elementos := 0
	for nome in runas:
		var r := runa(str(nome))
		if r.is_empty():
			return "Runa desconhecida: %s." % nome
		if r["tipo"] == "forma":
			formas += 1
		else:
			elementos += 1
	if formas > 1:
		return "Só cabe uma runa de forma por forja."
	if elementos > MAXIMO_ELEMENTOS:
		return "Só cabem duas runas de elemento por forja."
	return ""


## Identidade da soma: a forma (se houver) e os elementos em ordem
## alfabética. "fogo+vida" e "vida+fogo" dão a mesma chave.
static func chave(runas: Array) -> String:
	var forma := ""
	var elementos: Array[String] = []
	for nome in runas:
		if runa(str(nome)).get("tipo") == "forma":
			forma = str(nome)
		else:
			elementos.append(str(nome))
	elementos.sort()
	var partes: Array[String] = []
	if forma != "":
		partes.append(forma)
	partes.append_array(elementos)
	return "+".join(partes)


## O resultado da forja: nome, legenda, cor do medalhão, se é receita
## especial, modelo próprio (quando houver) e a ficha da magia.
## Devolve {} se a combinação não pode ser forjada.
static func forjar(runas: Array) -> Dictionary:
	if problema(runas) != "":
		return {}
	var k := chave(runas)
	for receita in dados()["receitas"]:
		if chave(receita["runas"]) == k:
			return _resultado(k, receita["nome"], receita["legenda"], receita["ficha"], true, receita.get("modelo", ""), runas)
	return _basica(k, runas)


static func _resultado(k: String, nome: String, legenda: String, ficha: Dictionary, especial: bool, modelo: String, runas: Array) -> Dictionary:
	var f := ficha.duplicate(true)
	f["versao_sistema"] = 1
	f["nome"] = nome
	f["legenda"] = legenda
	f["ingredientes"] = k.split("+")
	if not f.has("natureza"):
		f["natureza"] = "neutra"
	return {
		"chave": k,
		"nome": nome,
		"legenda": legenda,
		"especial": especial,
		"modelo": modelo,
		"cor": _cor_principal(runas),
		"ficha": f,
	}


## Cor do medalhão: a do elemento que vem primeiro na chave (assim não
## depende da ordem em que as runas foram postas); sem elemento, a da forma.
static func _cor_principal(runas: Array) -> Color:
	var partes := chave(runas).split("+")
	for nome in partes:
		if runa(nome)["tipo"] == "elemento":
			return Color(runa(nome)["cor"])
	return Color(runa(partes[0])["cor"])


## Versão básica e engraçada para somas sem receita. A forma decide o que
## acontece (arremesso joga, vida cria, prende segura) e os elementos
## decidem a cor, o material e o estado. Elemento repetido deixa mais forte.
static func _basica(k: String, runas: Array) -> Dictionary:
	var forma := ""
	var elementos: Array[Dictionary] = []
	for nome in chave(runas).split("+"):
		var r := runa(nome)
		if r["tipo"] == "forma":
			forma = nome
		else:
			elementos.append(r)
	var principal: Dictionary = elementos[0] if not elementos.is_empty() else {"nome": "Pedra", "material": "pedra", "estado": "", "etiquetas": []}
	var repetido: bool = elementos.size() == 2 and elementos[0]["nome"] == elementos[1]["nome"]
	var forca := 1.5 if repetido else 1.0
	var estados: Array[String] = []
	for e in elementos:
		if e["estado"] != "" and not e["estado"] in estados:
			estados.append(e["estado"])
	var nomes_elementos: String = " e ".join(elementos.map(func(e): return e["nome"])) if not repetido else principal["nome"] + " em Dobro"
	if elementos.is_empty():
		nomes_elementos = "Pedra"

	var componentes: Array = []
	var nome := ""
	var legenda := ""
	match forma:
		"arremesso":
			nome = "Cubo Arremessado de %s" % nomes_elementos
			legenda = "um cubo meio torto que voa devagar e estoura"
			var impacto: Array = [{"tipo": "explosao", "raio_m": 2.5 * forca, "dano": 8 * forca, "empurrao": 3, "etiquetas": principal.get("etiquetas", [])}]
			for e in estados:
				impacto.append({"tipo": "estado", "nome_estado": e, "duracao_s": 3})
			componentes.append({"tipo": "projetil", "forma": "cubo", "material": principal["material"], "velocidade": 9, "ao_impactar": impacto})
		"vida":
			if elementos.is_empty():
				nome = "Curinha"
				legenda = "uma curinha de nada, mas ajuda"
				componentes.append({"tipo": "cura", "quantidade": 10})
			else:
				nome = "Bolha Viva de %s" % nomes_elementos
				legenda = "uma bolha que ganhou vida e sai mordendo"
				componentes.append({"tipo": "invocacao", "corpo": "bolha", "material": principal["material"], "escala": 0.8 * forca,
					"vida": 12 * forca, "dano_contato": 3 * forca, "duracao_s": 6, "comportamento": "perseguir_inimigo_proximo"})
		"prende":
			nome = "Raízes de %s" % nomes_elementos if not elementos.is_empty() else "Raízes"
			legenda = "o chão em volta segura quem pisar nele"
			# Uma área só: cada área conta no limite de 3 magias ativas.
			componentes.append({"tipo": "area", "raio_m": 3.0, "duracao_s": 4, "dano_por_s": 2 * forca if not elementos.is_empty() else 0,
				"material": principal["material"], "nome_estado": "lento"})
		_:
			# Só elementos: projétil do primeiro, com o estado dos dois.
			nome = "Bolota de %s" % nomes_elementos
			legenda = "uma bolota que mistura tudo e explode"
			var impacto: Array = [{"tipo": "explosao", "raio_m": 2.0 * forca, "dano": 10 * forca, "empurrao": 3, "etiquetas": principal.get("etiquetas", [])}]
			for e in estados:
				impacto.append({"tipo": "estado", "nome_estado": e, "duracao_s": 3})
			componentes.append({"tipo": "projetil", "forma": "esfera", "material": principal["material"], "velocidade": 16, "ao_impactar": impacto})
	return _resultado(k, nome, legenda, {"natureza": "neutra", "componentes": componentes}, false, "", runas)
