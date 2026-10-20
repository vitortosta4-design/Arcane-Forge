extends RefCounted
class_name Interpretador
## Camada trocável que traduz uma frase em ficha de magia (ADR-002).
## Por enquanto, sem nenhuma IA: reconhece só algumas palavras-chave, para
## testar o caminho inteiro (texto -> ficha -> validador -> executor) sem
## gastar cota nem precisar de internet. Quando a Fase 2 ligar o porteiro
## no Supabase, só esta função muda; quem chama continua igual.
##
## Devolve uma ficha (Dictionary) quando reconhece a frase, ou um
## Dictionary vazio quando não entende.

static func interpretar(frase: String) -> Dictionary:
	var normalizada := frase.to_lower()
	if "fogo" in normalizada and ("bola" in normalizada or "bala" in normalizada):
		return FichasPadrao.bola_de_fogo()
	return {}
