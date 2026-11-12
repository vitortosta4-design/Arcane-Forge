extends Node
## Sistema de som por camadas (ADR-026): efeitos tocam em 3D, com pequena
## variação de tom a cada execução e um limite de sons simultâneos (o valor
## abaixo é provisório, ainda falta medir desempenho e clareza de verdade).
## Hoje só tiro, explosão, galinha zumbi, árvore e martelo, gerados por script (sem nenhum
## arquivo de terceiro envolvido, ver docs/creditos-audio.md). Quando o
## Vitor mandar gravações de verdade (ADR-028), é só trocar os streams
## abaixo.

const LIMITE_SONS_SIMULTANEOS := 16
## Volume (pedido do Vitor, 12/11/2026: tudo mais baixo e suave, a explosão
## principalmente). Dois botões:
## 1. a trilha "Efeitos" inteira está 6 dB mais baixa e passa por um filtro que
##    corta o agudo áspero acima de 3,2 kHz (default_bus_layout.tres);
## 2. cada som tem aqui o seu desconto extra em dB (-6 dB soa mais ou menos
##    como metade da força).
const VOLUME_DB := {"tiro": -3.0, "explosao": -9.0, "galinha": -2.0, "arvore": -5.0, "martelo": -3.0}

const SomTiro := preload("res://assets/som/tiro.wav")
const SomExplosao := preload("res://assets/som/explosao.wav")
const SomGalinha := preload("res://assets/som/galinha_zumbi.wav")
const SomArvore := preload("res://assets/som/arvore_rangendo.wav")
## Provisório, gerado por ferramentas/gerar_som_martelo.py. Para trocar pela
## gravação do Vitor: salvar o arquivo novo por cima deste, com o mesmo nome.
const SomMartelo := preload("res://assets/som/martelo_bigorna.wav")

var _tocadores_ativos: Array[AudioStreamPlayer3D] = []


## Toca um som posicionado em 3D no mundo, numa trilha (bus) de volume
## separada. Respeita o limite de sons simultâneos: se estourar, o som mais
## novo simplesmente não toca (melhor que travar ou cortar um som em
## andamento).
func tocar(stream: AudioStream, posicao: Vector3, bus: String = "Efeitos", variacao_tom: float = 0.08, volume_db: float = 0.0) -> void:
	var mundo := get_tree().current_scene
	if mundo == null or stream == null:
		return

	_tocadores_ativos = _tocadores_ativos.filter(func(p): return is_instance_valid(p) and p.playing)
	if _tocadores_ativos.size() >= LIMITE_SONS_SIMULTANEOS:
		return

	var tocador := AudioStreamPlayer3D.new()
	tocador.stream = stream
	tocador.bus = bus
	tocador.volume_db = volume_db
	tocador.pitch_scale = 1.0 + randf_range(-variacao_tom, variacao_tom)
	mundo.add_child(tocador)
	tocador.global_position = posicao
	tocador.play()
	tocador.finished.connect(tocador.queue_free)
	_tocadores_ativos.append(tocador)


func tocar_tiro(posicao: Vector3) -> void:
	tocar(SomTiro, posicao, "Efeitos", 0.08, VOLUME_DB["tiro"])


func tocar_explosao(posicao: Vector3) -> void:
	# Tom um pouco mais grave e menos variado: estouro surdo em vez de estalo.
	tocar(SomExplosao, posicao, "Efeitos", 0.05, VOLUME_DB["explosao"])


func tocar_galinha(posicao: Vector3) -> void:
	tocar(SomGalinha, posicao, "Efeitos", 0.08, VOLUME_DB["galinha"])


func tocar_arvore(posicao: Vector3) -> void:
	tocar(SomArvore, posicao, "Efeitos", 0.05, VOLUME_DB["arvore"])


func tocar_martelo(posicao: Vector3) -> void:
	tocar(SomMartelo, posicao, "Efeitos", 0.06, VOLUME_DB["martelo"])
