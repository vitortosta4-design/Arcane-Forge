class_name EventosAmbientais
extends RefCounted
## Lista de eventos ambientais raros (ADR-047). Cada entrada é só a chance de
## acontecer por partida e o caminho da cena que sabe tocar o evento; quem
## sorteia e dispara (GerenciadorEventosAmbientais) não precisa saber o que
## cada evento faz por dentro. Para cadastrar um evento novo, acrescente uma
## entrada aqui.

const LISTA: Array[Dictionary] = [
	{
		"id": "arvore_gigante",
		"chance_por_partida": 0.5,
		"cena": "res://cenas/eventos/arvore_gigante.tscn",
	},
]
