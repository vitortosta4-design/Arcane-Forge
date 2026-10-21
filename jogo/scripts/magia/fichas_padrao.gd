extends RefCounted
class_name FichasPadrao
## Fichas escritas à mão (proposta técnica, seção 9, item 8). Nenhuma IA
## envolvida: isso é o formato que a IA vai preencher a partir da Fase 2.

static func bola_de_fogo() -> Dictionary:
	return {
		"versao_sistema": 1,
		"nome": "Bola de Fogo",
		"frase_original": "bola de fogo",
		"natureza": "neutra",
		"ingredientes": ["fogo"],
		"componentes": [
			{
				"tipo": "projetil",
				"forma": "esfera",
				"material": "fogo",
				"velocidade": 18.0,
				"ao_impactar": [
					{
						"tipo": "explosao",
						"raio_m": 2.5,
						"dano": 15.0,
						"empurrao": 4.0,
						"etiquetas": ["fogo"]
					}
				]
			}
		],
		"legenda": "uma bola de fogo que explode ao impacto"
	}


static func luz_curativa() -> Dictionary:
	return {
		"versao_sistema": 1,
		"nome": "Luz Curativa",
		"frase_original": "luz curativa",
		"natureza": "boa",
		"ingredientes": ["cura"],
		"componentes": [
			{
				"tipo": "cura",
				"quantidade": 20.0
			}
		],
		"legenda": "uma luz calorosa que cura quem a conjurou"
	}


static func escudo_de_pedra() -> Dictionary:
	return {
		"versao_sistema": 1,
		"nome": "Escudo de Pedra",
		"frase_original": "escudo de pedra",
		"natureza": "neutra",
		"ingredientes": ["pedra"],
		"componentes": [
			{
				"tipo": "escudo",
				"reducao": 0.5,
				"duracao_s": 5.0
			}
		],
		"legenda": "uma casca de pedra que reduz o próximo dano"
	}


## "Empurrar/puxar" (proposta técnica, seção 3) é o mesmo componente
## "explosao" com o sinal do empurrão invertido: em vez de um novo tipo,
## é um projétil que, ao impactar, puxa para o centro em vez de afastar.
static func mini_buraco_negro() -> Dictionary:
	return {
		"versao_sistema": 1,
		"nome": "Mini Buraco Negro",
		"frase_original": "mini buraco negro",
		"natureza": "ma",
		"ingredientes": ["caos"],
		"componentes": [
			{
				"tipo": "projetil",
				"forma": "esfera",
				"material": "metal",
				"velocidade": 12.0,
				"ao_impactar": [
					{
						"tipo": "explosao",
						"raio_m": 3.0,
						"dano": 0.0,
						"empurrao": -5.0,
						"etiquetas": []
					}
				]
			}
		],
		"legenda": "uma esfera que puxa tudo que está perto para o centro"
	}


## Estado "queimando" (proposta técnica, seção 3): aplicado direto em quem
## o projétil atinge, não numa área, por isso sem efeito de explosão junto.
static func chama_persistente() -> Dictionary:
	return {
		"versao_sistema": 1,
		"nome": "Chama Persistente",
		"frase_original": "chama persistente",
		"natureza": "ma",
		"ingredientes": ["fogo"],
		"componentes": [
			{
				"tipo": "projetil",
				"forma": "esfera",
				"material": "fogo",
				"velocidade": 14.0,
				"ao_impactar": [
					{
						"tipo": "estado",
						"nome_estado": "queimando",
						"duracao_s": 3.0
					}
				]
			}
		],
		"legenda": "uma chama que gruda e queima aos poucos"
	}


## Estado "lento" (proposta técnica, seção 3).
static func vento_gelado() -> Dictionary:
	return {
		"versao_sistema": 1,
		"nome": "Vento Gelado",
		"frase_original": "vento gelado",
		"natureza": "neutra",
		"ingredientes": ["agua"],
		"componentes": [
			{
				"tipo": "projetil",
				"forma": "esfera",
				"material": "agua",
				"velocidade": 14.0,
				"ao_impactar": [
					{
						"tipo": "estado",
						"nome_estado": "lento",
						"duracao_s": 4.0
					}
				]
			}
		],
		"legenda": "um vento gelado que deixa quem é atingido mais lento"
	}


## Invocação (proposta técnica, seção 3): versão simplificada do exemplo
## "Pombo de Pedra" — sem o lançador de ovos explosivos ainda, só a
## criatura perseguindo e batendo. O lançador fica para um próximo
## incremento (ver docs/decisoes.md).
static func pombo_de_pedra() -> Dictionary:
	return {
		"versao_sistema": 1,
		"nome": "Pombo de Pedra",
		"frase_original": "pombo de pedra",
		"natureza": "neutra",
		"ingredientes": ["invocacao"],
		"componentes": [
			{
				"tipo": "invocacao",
				"corpo": "ave",
				"material": "pedra",
				"escala": 0.7,
				"comportamento": "perseguir_inimigo_proximo",
				"vida": 20.0,
				"duracao_s": 6.0,
				"dano_contato": 5.0
			}
		],
		"legenda": "um pombo de pedra que persegue e bica os inimigos"
	}


## O exemplo completo da proposta técnica (seção 3): invocação + lançador
## anexado a ela, soltando ovos de pedra que explodem.
static func pombo_bombardeiro() -> Dictionary:
	return {
		"versao_sistema": 1,
		"nome": "Pombo de Pedra Bombardeiro",
		"frase_original": "um pombo de pedra que voa até o inimigo e solta ovos explosivos",
		"natureza": "neutra",
		"ingredientes": ["invocacao", "explosao"],
		"componentes": [
			{
				"id": "pombo",
				"tipo": "invocacao",
				"corpo": "ave",
				"material": "pedra",
				"escala": 0.7,
				"comportamento": "perseguir_inimigo_proximo",
				"vida": 20.0,
				"duracao_s": 6.0,
				"dano_contato": 3.0
			},
			{
				"tipo": "lancador",
				"anexado_a": "pombo",
				"intervalo_s": 1.5,
				"projetil": {"forma": "ovo", "material": "pedra", "velocidade": 8.0},
				"ao_impactar": [
					{"tipo": "explosao", "raio_m": 2.0, "dano": 12.0, "empurrao": 3.0}
				]
			}
		],
		"legenda": "criatura de pedra que persegue e solta ovos explosivos"
	}


## Estado "molhado" (proposta técnica, seção 3): sozinho não machuca, mas
## apaga fogo e deixa o alvo vulnerável a eletricidade.
static func jato_d_agua() -> Dictionary:
	return {
		"versao_sistema": 1,
		"nome": "Jato d'Água",
		"frase_original": "jato de água",
		"natureza": "neutra",
		"ingredientes": ["agua"],
		"componentes": [
			{
				"tipo": "projetil",
				"forma": "esfera",
				"material": "agua",
				"velocidade": 16.0,
				"ao_impactar": [
					{"tipo": "estado", "nome_estado": "molhado", "duracao_s": 5.0}
				]
			}
		],
		"legenda": "um jato d'água que encharca quem acerta"
	}


## Estado "eletrizado": choque na hora; em alvo molhado, dano dobrado e
## espalha para quem estiver perto.
static func faisca() -> Dictionary:
	return {
		"versao_sistema": 1,
		"nome": "Faísca",
		"frase_original": "faísca elétrica",
		"natureza": "neutra",
		"ingredientes": ["eletricidade"],
		"componentes": [
			{
				"tipo": "projetil",
				"forma": "esfera",
				"material": "metal",
				"velocidade": 22.0,
				"ao_impactar": [
					{"tipo": "estado", "nome_estado": "eletrizado", "duracao_s": 1.0}
				]
			}
		],
		"legenda": "uma faísca que dá choque, e espalha se o alvo estiver molhado"
	}


## Área persistente no ponto de impacto (proposta técnica, seção 3): a bola
## cai e deixa uma poça que queima quem pisar, e acende barris por perto.
static func poca_de_lava() -> Dictionary:
	return {
		"versao_sistema": 1,
		"nome": "Poça de Lava",
		"frase_original": "bola que deixa uma poça de lava",
		"natureza": "neutra",
		"ingredientes": ["fogo"],
		"componentes": [
			{
				"tipo": "projetil",
				"forma": "esfera",
				"material": "fogo",
				"velocidade": 14.0,
				"ao_impactar": [
					{"tipo": "area", "raio_m": 2.0, "duracao_s": 5.0, "dano_por_s": 4.0, "nome_estado": "queimando", "material": "fogo"}
				]
			}
		],
		"legenda": "uma bola que deixa uma poça de lava no chão"
	}


## Área persistente aos pés de quem conjurou: molha quem chegar perto,
## preparando o terreno para a faísca.
static func nuvem_de_chuva() -> Dictionary:
	return {
		"versao_sistema": 1,
		"nome": "Nuvem de Chuva",
		"frase_original": "nuvem de chuva ao meu redor",
		"natureza": "neutra",
		"ingredientes": ["agua"],
		"componentes": [
			{"tipo": "area", "raio_m": 3.0, "duracao_s": 6.0, "dano_por_s": 0.0, "nome_estado": "molhado", "material": "agua"}
		],
		"legenda": "uma chuva em volta de você que encharca quem chegar perto"
	}


## Parede (proposta técnica, seção 3): segura projéteis e inimigos.
static func muro_de_pedra() -> Dictionary:
	return {
		"versao_sistema": 1,
		"nome": "Muro de Pedra",
		"frase_original": "muro de pedra na minha frente",
		"natureza": "neutra",
		"ingredientes": ["pedra", "construcao"],
		"componentes": [
			{"tipo": "parede", "largura_m": 3.0, "altura_m": 2.0, "duracao_s": 5.0, "distancia_m": 3.0, "material": "pedra"}
		],
		"legenda": "um muro de pedra que sobe do chão na sua frente"
	}


## Teleporte curto (proposta técnica, seção 3).
static func salto_arcano() -> Dictionary:
	return {
		"versao_sistema": 1,
		"nome": "Salto Arcano",
		"frase_original": "teleporte para a frente",
		"natureza": "neutra",
		"ingredientes": ["deslocamento"],
		"componentes": [
			{"tipo": "teleporte", "distancia_m": 6.0}
		],
		"legenda": "você some e reaparece alguns metros à frente"
	}


## Estado "cego". ADR-013 põe a cegueira entre os ingredientes maus, por
## isso a natureza "ma".
static func po_ofuscante() -> Dictionary:
	return {
		"versao_sistema": 1,
		"nome": "Pó Ofuscante",
		"frase_original": "pó que cega o inimigo",
		"natureza": "ma",
		"ingredientes": ["caos"],
		"componentes": [
			{
				"tipo": "projetil",
				"forma": "esfera",
				"material": "madeira",
				"velocidade": 16.0,
				"ao_impactar": [
					{"tipo": "estado", "nome_estado": "cego", "duracao_s": 3.0}
				]
			}
		],
		"legenda": "um punhado de pó que deixa o inimigo cego e perdido"
	}
