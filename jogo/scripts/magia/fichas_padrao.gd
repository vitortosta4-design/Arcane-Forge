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
