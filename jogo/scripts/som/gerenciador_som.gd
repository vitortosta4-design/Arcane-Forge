extends Node
## Sistema de som por camadas (ADR-026): efeitos tocam em 3D, com pequena
## variação de tom a cada execução e um limite de sons simultâneos (o valor
## abaixo é provisório, ainda falta medir desempenho e clareza de verdade).
## Hoje só tiro, explosão e galinha zumbi, gerados por script (sem nenhum
## arquivo de terceiro envolvido, ver docs/creditos-audio.md). Quando o
## Vitor mandar gravações de verdade (ADR-028), é só trocar os streams
## abaixo.

const LIMITE_SONS_SIMULTANEOS := 16

const SomTiro := preload("res://assets/som/tiro.wav")
const SomExplosao := preload("res://assets/som/explosao.wav")
const SomGalinha := preload("res://assets/som/galinha_zumbi.wav")
const SomArvore := preload("res://assets/som/arvore_rangendo.wav")

var _tocadores_ativos: Array[AudioStreamPlayer3D] = []


## Toca um som posicionado em 3D no mundo, numa trilha (bus) de volume
## separada. Respeita o limite de sons simultâneos: se estourar, o som mais
## novo simplesmente não toca (melhor que travar ou cortar um som em
## andamento).
func tocar(stream: AudioStream, posicao: Vector3, bus: String = "Efeitos", variacao_tom: float = 0.08) -> void:
	var mundo := get_tree().current_scene
	if mundo == null or stream == null:
		return

	_tocadores_ativos = _tocadores_ativos.filter(func(p): return is_instance_valid(p) and p.playing)
	if _tocadores_ativos.size() >= LIMITE_SONS_SIMULTANEOS:
		return

	var tocador := AudioStreamPlayer3D.new()
	tocador.stream = stream
	tocador.bus = bus
	tocador.pitch_scale = 1.0 + randf_range(-variacao_tom, variacao_tom)
	mundo.add_child(tocador)
	tocador.global_position = posicao
	tocador.play()
	tocador.finished.connect(tocador.queue_free)
	_tocadores_ativos.append(tocador)


func tocar_tiro(posicao: Vector3) -> void:
	tocar(SomTiro, posicao)


func tocar_explosao(posicao: Vector3) -> void:
	tocar(SomExplosao, posicao)


func tocar_galinha(posicao: Vector3) -> void:
	tocar(SomGalinha, posicao)


func tocar_arvore(posicao: Vector3) -> void:
	tocar(SomArvore, posicao, "Efeitos", 0.05)
