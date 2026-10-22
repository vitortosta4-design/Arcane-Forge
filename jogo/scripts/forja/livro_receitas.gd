class_name LivroReceitas
extends RefCounted
## O livro de receitas da Forja de Runas (ADR-032 a 035). Lê
## dados/receitas.json e responde: "com estas runas na bigorna, sai o quê?".
##
## Regras (ADR-035):
## - até 3 runas: no máximo 1 de forma e no máximo 2 de elemento;
## - pelo menos 1 elemento (forma sozinha não forja nada: a bigorna treme);
## - a ordem em que as runas entram não importa: a mesma soma dá sempre a
##   mesma magia (determinístico, sem sorteio);
## - combinação com receita dá a magia especial; sem receita dá a versão
##   básica e engraçada daquela forma.
##
## O resultado é sempre uma ficha no formato de sempre, que passa pelo
## Validador antes de virar medalhão: o arquivo de dados pode ter número
## alto, o Validador corta.

const CAMINHO_PADRAO := "res://dados/receitas.json"
const MAXIMO_RUNAS := 3
const MAXIMO_ELEMENTOS := 2

var formas := {}
var elementos := {}
var iniciais: Array = []
var _por_chave := {}
var _por_id := {}


static func carregar(caminho := CAMINHO_PADRAO) -> LivroReceitas:
	var livro := LivroReceitas.new()
	var texto := FileAccess.get_file_as_string(caminho)
	var dados = JSON.parse_string(texto)
	if typeof(dados) != TYPE_DICTIONARY:
		push_error("Livro de receitas ilegível: %s" % caminho)
		return livro
	livro.formas = dados.get("formas", {})
	livro.elementos = dados.get("elementos", {})
	livro.iniciais = dados.get("iniciais", [])
	for receita in dados.get("receitas", []):
		var chave := livro.chave(receita.get("runas", []))
		if chave == "":
			push_error("Receita com runas inválidas: %s" % receita.get("id"))
			continue
		livro._por_chave[chave] = receita
		livro._por_id[receita["id"]] = receita
	return livro


## Chave única de uma combinação, independente da ordem: "forma|elem1+elem2".
## Devolve "" se a combinação quebra as regras.
func chave(runas: Array) -> String:
	var forma := ""
	var elems: Array[String] = []
	if runas.is_empty() or runas.size() > MAXIMO_RUNAS:
		return ""
	for r in runas:
		var nome := str(r)
		if formas.has(nome):
			if forma != "":
				return ""
			forma = nome
		elif elementos.has(nome):
			elems.append(nome)
		else:
			return ""
	if elems.is_empty() or elems.size() > MAXIMO_ELEMENTOS:
		return ""
	elems.sort()
	return forma + "|" + "+".join(elems)


## Explica em poucas palavras por que a combinação não forja (texto curto,
## estilo "back seat", ADR-032). Vazio se ela é válida.
func motivo_invalida(runas: Array) -> String:
	if runas.is_empty():
		return "A bigorna está vazia."
	if runas.size() > MAXIMO_RUNAS:
		return "No máximo 3 runas."
	var n_formas := 0
	var n_elems := 0
	for r in runas:
		if formas.has(str(r)):
			n_formas += 1
		elif elementos.has(str(r)):
			n_elems += 1
		else:
			return "Runa desconhecida."
	if n_formas > 1:
		return "Só cabe uma runa de forma."
	if n_elems == 0:
		return "Falta um elemento."
	if n_elems > MAXIMO_ELEMENTOS:
		return "No máximo dois elementos."
	return ""


## Forja. Devolve um medalhão (Dictionary) ou {"ok": false, "motivo": ...}.
## Medalhão: id, nome, legenda, cor, simbolo, recarga_s, especial, runas, ficha.
func forjar(runas: Array) -> Dictionary:
	var motivo := motivo_invalida(runas)
	if motivo != "":
		return {"ok": false, "motivo": motivo}
	var k := chave(runas)
	if _por_chave.has(k):
		return _medalhao_da_receita(_por_chave[k], true)
	return _medalhao_basico(k)


func receita_por_id(id: String) -> Dictionary:
	if not _por_id.has(id):
		return {}
	return _medalhao_da_receita(_por_id[id], true)


func total_receitas() -> int:
	return _por_id.size()


func _medalhao_da_receita(receita: Dictionary, especial: bool) -> Dictionary:
	var runas: Array = receita.get("runas", [])
	var ficha := {
		"versao_sistema": 1,
		"nome": receita["nome"],
		"frase_original": "+".join(runas),
		"natureza": receita.get("natureza", "neutra"),
		"ingredientes": runas.duplicate(),
		"componentes": (receita["componentes"] as Array).duplicate(true),
		"legenda": receita.get("legenda", ""),
	}
	return {
		"ok": true,
		"id": receita["id"],
		"nome": receita["nome"],
		"legenda": receita.get("legenda", ""),
		"cor": receita.get("cor", _cor_dos_elementos(runas)),
		"simbolo": _simbolo(runas),
		"recarga_s": float(receita.get("recarga_s", 2.0)),
		"especial": especial,
		"runas": runas.duplicate(),
		"ficha": ficha,
	}


## Versão básica e engraçada: depende só da forma, e o material e o estado
## vêm do primeiro elemento em ordem alfabética (para ser sempre igual).
func _medalhao_basico(k: String) -> Dictionary:
	var partes := k.split("|")
	var forma := partes[0]
	var elems := partes[1].split("+")
	var e1: Dictionary = elementos[elems[0]]
	var material: String = e1.get("material", "pedra")
	var estado: String = e1.get("estado", "")
	var nomes := PackedStringArray()
	for e in elems:
		nomes.append(elementos[e]["nome"])
	var de := " de " + " e ".join(nomes)
	var nome := ""
	var legenda := ""
	var recarga := 3.0
	var comps: Array = []
	match forma:
		"arremesso":
			nome = "Pedregulho Desengonçado" + de
			legenda = "sai rolando torto e faz pouco estrago"
			var impacto: Array = [{"tipo": "explosao", "raio_m": 1.0, "dano": 6.0, "empurrao": 1.0}]
			if estado != "":
				impacto.append({"tipo": "estado", "nome_estado": estado, "duracao_s": 2.0})
			comps = [{"tipo": "projetil", "forma": "cubo", "material": material, "velocidade": 7.0, "ao_impactar": impacto}]
		"vida":
			nome = "Bichinho Confuso" + de
			legenda = "uma minhoquinha que tenta ajudar"
			recarga = 6.0
			comps = [{"tipo": "invocacao", "corpo": "verme", "material": material, "escala": 0.5,
				"comportamento": "perseguir_inimigo_proximo", "vida": 8.0, "duracao_s": 5.0, "dano_contato": 2.0}]
		"prende":
			nome = "Barbante Mágico" + de
			legenda = "segura por um instante, depois arrebenta"
			recarga = 4.0
			comps = [{"tipo": "projetil", "forma": "cubo", "material": material, "velocidade": 16.0,
				"ao_impactar": [{"tipo": "area", "raio_m": 1.5, "duracao_s": 2.0, "dano_por_s": 0.0, "material": material, "nome_estado": "lento"}]}]
		_:
			nome = "Mistura Instável" + de
			legenda = "chia, solta fumaça e acerta fraquinho"
			recarga = 2.0
			var impactos: Array = [{"tipo": "explosao", "raio_m": 1.2, "dano": 5.0, "empurrao": 1.0}]
			for e in elems:
				var est: String = elementos[e].get("estado", "")
				if est != "":
					impactos.append({"tipo": "estado", "nome_estado": est, "duracao_s": 2.0})
			comps = [{"tipo": "projetil", "forma": "esfera", "material": material, "velocidade": 12.0, "ao_impactar": impactos}]
	var runas: Array = []
	if forma != "":
		runas.append(forma)
	runas.append_array(Array(elems))
	var receita := {"id": "basica_" + k.replace("|", "_").replace("+", "_"), "nome": nome, "legenda": legenda,
		"recarga_s": recarga, "runas": runas, "componentes": comps}
	return _medalhao_da_receita(receita, false)


func _cor_dos_elementos(runas: Array) -> String:
	for r in runas:
		if elementos.has(str(r)):
			return elementos[str(r)].get("cor", "#ffffff")
	return "#ffffff"


func _simbolo(runas: Array) -> String:
	for r in runas:
		if formas.has(str(r)):
			return formas[str(r)].get("simbolo", "?")
	return "●"
