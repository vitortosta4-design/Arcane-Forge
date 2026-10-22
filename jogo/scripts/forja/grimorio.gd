class_name Grimorio
extends RefCounted
## Grimório: toda receita já descoberta, salva no PC e mantida para sempre
## entre expedições (ADR-034). Arquivo simples em user://, sem login
## (ADR-021). Receita básica (sem receita no livro) não entra: o grimório
## guarda descobertas, não tentativas.

const CAMINHO_PADRAO := "user://grimorio.json"

var caminho := CAMINHO_PADRAO
var descobertas: Array[String] = []


static func abrir(caminho_arquivo := CAMINHO_PADRAO) -> Grimorio:
	var g := Grimorio.new()
	g.caminho = caminho_arquivo
	if FileAccess.file_exists(caminho_arquivo):
		var dados = JSON.parse_string(FileAccess.get_file_as_string(caminho_arquivo))
		if typeof(dados) == TYPE_DICTIONARY:
			for id in dados.get("descobertas", []):
				if typeof(id) == TYPE_STRING and not id in g.descobertas:
					g.descobertas.append(id)
	return g


func conhece(id: String) -> bool:
	return id in descobertas


## Registra e salva. Devolve true se a receita é nova.
func registrar(id: String) -> bool:
	if id == "" or conhece(id):
		return false
	descobertas.append(id)
	salvar()
	return true


func salvar() -> void:
	var arquivo := FileAccess.open(caminho, FileAccess.WRITE)
	if arquivo == null:
		push_error("Não deu para salvar o grimório em %s" % caminho)
		return
	arquivo.store_string(JSON.stringify({"versao": 1, "descobertas": descobertas}, "\t"))
	arquivo.close()
