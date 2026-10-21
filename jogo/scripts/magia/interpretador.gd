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
	if "cura" in normalizada or "curar" in normalizada:
		return FichasPadrao.luz_curativa()
	if "escudo" in normalizada:
		return FichasPadrao.escudo_de_pedra()
	if "buraco negro" in normalizada or "puxar" in normalizada or "puxa" in normalizada:
		return FichasPadrao.mini_buraco_negro()
	if "queimar" in normalizada or "queimando" in normalizada or "chama" in normalizada:
		return FichasPadrao.chama_persistente()
	if "lento" in normalizada or "lentidao" in normalizada or "gelado" in normalizada:
		return FichasPadrao.vento_gelado()
	if "bombardeiro" in normalizada or ("pombo" in normalizada and ("ovo" in normalizada or "explo" in normalizada)):
		return FichasPadrao.pombo_bombardeiro()
	if "pombo" in normalizada or "invocar" in normalizada or "invocacao" in normalizada or "invocação" in normalizada:
		return FichasPadrao.pombo_de_pedra()
	if "lava" in normalizada or "poça" in normalizada or "poca" in normalizada:
		return FichasPadrao.poca_de_lava()
	if "chuva" in normalizada:
		return FichasPadrao.nuvem_de_chuva()
	if "água" in normalizada or "agua" in normalizada or "molhar" in normalizada:
		return FichasPadrao.jato_d_agua()
	if "faísca" in normalizada or "faisca" in normalizada or "choque" in normalizada or "elétric" in normalizada or "eletric" in normalizada:
		return FichasPadrao.faisca()
	return {}
