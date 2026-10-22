class_name Forja
extends Node3D
## A bigorna viva da caverna e as regras de martelar (ADR-032 a 035).
##
## martelar() é quem decide (no cooperativo da Fase 3 ela roda no host, o
## juiz): confere a combinação no livro, confere se o mago tem as runas e
## espaço na barra, só então gasta as runas, equipa o medalhão e anota a
## receita nova no grimório. A bigorna reage: ri com receita especial, fica
## neutra com a versão básica e fica brava (e treme) quando não dá.

signal forjou(resultado: Dictionary)

const CENA_BIGORNA := preload("res://cenas/forja/bigorna_viva.tscn")
const RAIO_INTERACAO := 8.0
const VOLTA_AO_NEUTRO_S := 2.5

var bigorna: BigornaViva = null
var grimorio: Grimorio = null
var _volta_neutro_s := 0.0


func _ready() -> void:
	bigorna = CENA_BIGORNA.instantiate()
	add_child(bigorna)
	if grimorio == null:
		grimorio = Grimorio.abrir()


func perto(corpo: Node3D) -> bool:
	return corpo.global_position.distance_to(global_position) <= RAIO_INTERACAO


## Devolve {"ok", "mensagem", "medalhao", "nova", "espaco"}.
func martelar(mago: Node, selecao: Array) -> Dictionary:
	var livro: LivroReceitas = mago.livro
	var resultado := livro.forjar(selecao)
	if not resultado.get("ok", false):
		return _reagir({"ok": false, "mensagem": resultado["motivo"]}, "raiva")
	var sobra := (mago.runas as Array).duplicate()
	for r in selecao:
		var i := sobra.find(r)
		if i < 0:
			return _reagir({"ok": false, "mensagem": "Você não tem essas runas."}, "raiva")
		sobra.remove_at(i)
	if mago.barra.primeiro_vazio() < 0:
		return _reagir({"ok": false, "mensagem": "Barra cheia: quebre um medalhão primeiro."}, "raiva")
	mago.gastar_runas(selecao)
	var espaco: int = mago.barra.equipar(resultado)
	var nova := false
	if resultado["especial"]:
		nova = grimorio.registrar(resultado["id"])
	var mensagem: String = "%s! %s" % [resultado["nome"], resultado["legenda"]]
	if nova:
		mensagem = "Receita nova! " + mensagem
	var saida := {"ok": true, "mensagem": mensagem, "medalhao": resultado, "nova": nova, "espaco": espaco}
	return _reagir(saida, "rindo" if resultado["especial"] else "neutro")


func _reagir(resultado: Dictionary, expressao: String) -> Dictionary:
	if bigorna:
		bigorna._tremor = 0.12 if expressao == "raiva" else 0.05
		bigorna.mudar_expressao(expressao)
	_volta_neutro_s = VOLTA_AO_NEUTRO_S
	forjou.emit(resultado)
	return resultado


func _process(delta: float) -> void:
	if _volta_neutro_s > 0.0:
		_volta_neutro_s -= delta
		if _volta_neutro_s <= 0.0 and bigorna:
			bigorna.mudar_expressao("neutro")
