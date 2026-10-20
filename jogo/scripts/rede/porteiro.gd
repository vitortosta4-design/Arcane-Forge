extends Node
## O "porteiro" do lado do jogo (ADR-003, proposta técnica seção 4): fala
## com a Edge Function no Supabase pela internet. Guarda só a URL e a chave
## pública (anon/publishable), que é segura para ficar no jogo; a chave da
## IA de verdade mora inteiramente dentro do Supabase e nunca passa por
## aqui (ADR-003).

const URL_FUNCAO := "https://avasfvsditrkwyrdglfu.supabase.co/functions/v1/interpretar-magia"
const CHAVE_ANONIMA := "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2YXNmdnNkaXRya3d5cmRnbGZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI1MjIxOTIsImV4cCI6MjEwODA5ODE5Mn0.q0PO4ozkwiQ6oBa--29K43w_dt9pGqzVv0etnwQ1b8Q"
const TEMPO_LIMITE_S := 8.0

## Até a Fase 5 ligar o multiplayer de verdade, cada jogo local conta como
## a própria "sala" para o limite de 20 conjurações por minuto (proposta
## técnica, seção 5).
var sala_id := "local-%d" % Time.get_unix_time_from_system()

## Desligar isso simula "a IA está fora do ar" sem precisar de internet: cai
## direto no modo offline do Interpretador local (ADR-002). Os testes
## automáticos desligam para não gastar cota nem depender de rede.
var ativo := true


## Pede ao porteiro para interpretar uma frase. Devolve a ficha (Dictionary)
## em caso de sucesso, ou um Dictionary vazio se a IA estiver fora do ar, o
## limite foi atingido, ou a rede falhou. Quem chama decide o que fazer
## quando vem vazio (ex.: cair para o modo offline, ADR-002).
func interpretar(frase: String) -> Dictionary:
	if not ativo:
		return {}

	var requisicao := HTTPRequest.new()
	requisicao.timeout = TEMPO_LIMITE_S
	add_child(requisicao)

	var corpo := JSON.stringify({"frase": frase, "sala_id": sala_id})
	var cabecalhos := PackedStringArray([
		"Authorization: Bearer %s" % CHAVE_ANONIMA,
		"Content-Type: application/json",
	])

	var erro := requisicao.request(URL_FUNCAO, cabecalhos, HTTPClient.METHOD_POST, corpo)
	if erro != OK:
		requisicao.queue_free()
		return {}

	var resultado: Array = await requisicao.request_completed
	requisicao.queue_free()

	var codigo_resultado: int = resultado[0]
	var codigo_http: int = resultado[1]
	var corpo_resposta: PackedByteArray = resultado[3]

	if codigo_resultado != HTTPRequest.RESULT_SUCCESS or codigo_http != 200:
		return {}

	var json := JSON.new()
	if json.parse(corpo_resposta.get_string_from_utf8()) != OK:
		return {}

	var dados = json.data
	if typeof(dados) != TYPE_DICTIONARY or not dados.has("ficha"):
		return {}

	return dados["ficha"]
