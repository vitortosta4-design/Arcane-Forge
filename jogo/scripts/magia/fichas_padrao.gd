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
