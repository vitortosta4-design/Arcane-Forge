extends Node
## Testes automáticos do executor e das regras de dano/mana (critério de
## aceitação da Fase 1). Sem framework externo: roda como uma cena normal
## (para que os autoloads, como o Host, existam de verdade) com
## `godot --headless res://cenas/testes/suite_testes.tscn`.
## Sai com código 0 se tudo passar, 1 se algo falhar.

var _falhas := 0
var _total := 0


func _ready() -> void:
	await _testar_mago_comeca_com_vida_e_mana_cheias()
	await _testar_receber_dano_reduz_vida_e_nao_fica_negativa()
	await _testar_gastar_mana_recusa_sem_mana_suficiente()
	_testar_validador_corta_dano_acima_do_limite()
	_testar_validador_rejeita_material_fora_da_lista()
	await _testar_mira_identica_entre_1a_e_3a_pessoa()
	await _testar_galinha_morre_com_vida_zero()
	await _testar_explosao_quebra_caixa_e_acende_barril()
	await _testar_executor_cria_projetil_a_partir_da_ficha()
	await _testar_projetil_usa_a_cor_do_material_da_ficha()
	await _testar_porteiro_desligado_nao_faz_pedido_e_devolve_vazio()
	_testar_interpretador_reconhece_bola_de_fogo()
	_testar_interpretador_nao_entende_frase_desconhecida()
	_testar_validador_calcula_custo_de_mana_pelos_componentes()
	await _testar_conjurar_por_texto_reconhecido_gasta_mana_e_cria_projetil()
	await _testar_conjurar_por_texto_desconhecido_nao_gasta_mana()
	await _testar_ficha_sem_componentes_conta_como_nao_entendida()

	print("")
	if _falhas == 0:
		print("TODOS OS TESTES PASSARAM (%d/%d)" % [_total, _total])
		get_tree().quit(0)
	else:
		print("FALHAS: %d de %d testes" % [_falhas, _total])
		get_tree().quit(1)


func _afirmar(descricao: String, condicao: bool) -> void:
	_total += 1
	if condicao:
		print("[OK] %s" % descricao)
	else:
		_falhas += 1
		print("[FALHOU] %s" % descricao)


func _testar_mago_comeca_com_vida_e_mana_cheias() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame
	_afirmar("mago começa com vida cheia", mago.vida_atual == mago.vida_maxima)
	_afirmar("mago começa com mana cheia", mago.mana_atual == mago.mana_maxima)
	mago.queue_free()


func _testar_receber_dano_reduz_vida_e_nao_fica_negativa() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame
	mago.receber_dano(30.0, Vector3.ZERO, 0.0)
	_afirmar("dano de 30 deixa a vida em 70", is_equal_approx(mago.vida_atual, 70.0))
	mago.receber_dano(1000.0, Vector3.ZERO, 0.0)
	_afirmar("vida nunca fica negativa", mago.vida_atual == 0.0)
	mago.queue_free()


func _testar_gastar_mana_recusa_sem_mana_suficiente() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	var conseguiu_gastar_mais_que_tem: bool = mago.gastar_mana(1000.0)
	_afirmar("não deixa gastar mais mana do que tem", not conseguiu_gastar_mais_que_tem)
	_afirmar("mana não foi descontada na tentativa recusada", mago.mana_atual == mago.mana_maxima)
	var conseguiu_gastar_valido: bool = mago.gastar_mana(15.0)
	_afirmar("deixa gastar mana dentro do saldo", conseguiu_gastar_valido)
	_afirmar("mana foi descontada corretamente", is_equal_approx(mago.mana_atual, mago.mana_maxima - 15.0))
	mago.queue_free()


func _testar_validador_corta_dano_acima_do_limite() -> void:
	var ficha := {
		"componentes": [
			{
				"tipo": "projetil",
				"material": "fogo",
				"forma": "esfera",
				"velocidade": 999.0,
				"ao_impactar": [
					{"tipo": "explosao", "raio_m": 999.0, "dano": 999.0, "empurrao": 999.0}
				]
			}
		]
	}
	var corrigida := Validador.validar_ficha(ficha)
	var explosao: Dictionary = corrigida["componentes"][0]["ao_impactar"][0]
	_afirmar("dano cortado no limite máximo", explosao["dano"] == Validador.DANO_MAXIMO)
	_afirmar("raio cortado no limite máximo", explosao["raio_m"] == Validador.RAIO_EXPLOSAO_MAXIMO)
	_afirmar("velocidade cortada no limite máximo", corrigida["componentes"][0]["velocidade"] == Validador.VELOCIDADE_MAXIMA)


func _testar_validador_rejeita_material_fora_da_lista() -> void:
	var ficha := {
		"componentes": [
			{"tipo": "projetil", "material": "queijo", "forma": "estrela", "velocidade": 10.0, "ao_impactar": []}
		]
	}
	var corrigida := Validador.validar_ficha(ficha)
	var componente: Dictionary = corrigida["componentes"][0]
	_afirmar("material fora da lista vira um material válido", componente["material"] in Validador.MATERIAIS_VALIDOS)
	_afirmar("forma fora da lista vira uma forma válida", componente["forma"] in Validador.FORMAS_VALIDAS)


## Testa a consequência da ADR-011: a câmera de 3ª pessoa precisa acompanhar
## também o olhar para cima/baixo (pitch), não só o giro para os lados (yaw),
## para que a mira aponte para o mesmo lugar nos dois modos.
func _testar_mira_identica_entre_1a_e_3a_pessoa() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	var pivot: Node3D = mago.get_node("PivotCabeca")
	pivot.rotate_x(deg_to_rad(-30))
	await get_tree().process_frame

	var camera_1a: Camera3D = mago.get_node("PivotCabeca/CameraPrimeiraPessoa")
	var camera_3a: Camera3D = mago.get_node("PivotCabeca/BracoCameraTerceiraPessoa/CameraTerceiraPessoa")
	var direcao_1a := -camera_1a.global_transform.basis.z
	var direcao_3a := -camera_3a.global_transform.basis.z
	_afirmar("mira aponta na mesma direção nos dois modos de câmera", direcao_1a.is_equal_approx(direcao_3a))

	mago.queue_free()


func _testar_galinha_morre_com_vida_zero() -> void:
	var cena: PackedScene = load("res://cenas/inimigos/galinha_zumbi.tscn")
	var galinha := cena.instantiate()
	add_child(galinha)
	await get_tree().process_frame
	galinha.receber_dano(30.0, Vector3.ZERO, 0.0)
	_afirmar("galinha com dano suficiente sai do grupo recebe_dano", not galinha.is_in_group("recebe_dano"))
	galinha.queue_free()


## Testa o caminho completo da proposta técnica (seção 4): uma explosão com
## a etiqueta "fogo" precisa quebrar uma caixa por perto e acender um barril
## inflamável por perto, sem passar por nenhuma simulação de teclado/mouse.
func _testar_explosao_quebra_caixa_e_acende_barril() -> void:
	var caixa: Node3D = load("res://cenas/caixa.tscn").instantiate()
	add_child(caixa)
	caixa.global_position = Vector3(0, 0.3, 0)

	var barril: Node3D = load("res://cenas/barril_inflamavel.tscn").instantiate()
	add_child(barril)
	barril.global_position = Vector3(1, 0, 0)

	await get_tree().process_frame

	Host.criar_explosao(Vector3(0, 0.3, 0), 2.5, 15.0, 4.0, ["fogo"])
	await get_tree().process_frame

	_afirmar("caixa foi destruída pela explosão", not is_instance_valid(caixa))
	_afirmar("barril pegou fogo com a explosão", barril._queimando)

	barril.queue_free()


## Testa que o Executor, a partir da ficha da bola de fogo, realmente
## instancia um projétil no mundo com os parâmetros da ficha.
func _testar_executor_cria_projetil_a_partir_da_ficha() -> void:
	var ficha := FichasPadrao.bola_de_fogo()
	Executor.executar_ficha(ficha, Vector3(0, 1, 0), Vector3.FORWARD, null, self)
	await get_tree().process_frame

	var projeteis := get_children().filter(func(n): return n.get_script() == load("res://scripts/magia/projetil.gd"))
	_afirmar("executor criou um projétil no mundo", projeteis.size() == 1)
	if projeteis.size() > 0:
		var projetil = projeteis[0]
		_afirmar("projétil saiu com a velocidade da ficha", is_equal_approx(projetil.velocidade, 18.0))
		_afirmar("projétil carrega o efeito de explosão da ficha", projetil.ao_impactar.size() == 1)
		projetil.queue_free()


## Achado ao testar com o Vitor: magias de materiais diferentes (água,
## pedra...) saíam todas com a cor fixa de fogo, porque nada aplicava a cor
## do material de verdade. Testa que o projétil (e a explosão que ele
## carrega) realmente ficam com a cor certa do material da ficha.
func _testar_projetil_usa_a_cor_do_material_da_ficha() -> void:
	var ficha := {
		"componentes": [
			{
				"tipo": "projetil",
				"material": "agua",
				"forma": "esfera",
				"velocidade": 10.0,
				"ao_impactar": []
			}
		]
	}
	Executor.executar_ficha(ficha, Vector3(0, 1, 0), Vector3.FORWARD, null, self)
	await get_tree().process_frame

	var projeteis := get_children().filter(func(n): return n.get_script() == load("res://scripts/magia/projetil.gd"))
	_afirmar("projétil de água foi criado", projeteis.size() == 1)
	if projeteis.size() > 0:
		var projetil = projeteis[0]
		var mesh: MeshInstance3D = projetil.get_node("MeshInstance3D")
		var cor_esperada := Validador.cor_para_material("agua")
		var cor_aplicada: Color = mesh.get_surface_override_material(0).albedo_color
		_afirmar("projétil de água tem a cor de água, não de fogo", cor_aplicada.is_equal_approx(cor_esperada))
		projetil.queue_free()


## Testa o desligador do porteiro (usado pelos próprios testes para não
## gastar cota nem depender de internet, e que também serve ao jogador se
## quiser forçar o modo offline).
func _testar_porteiro_desligado_nao_faz_pedido_e_devolve_vazio() -> void:
	Porteiro.ativo = false
	var ficha: Dictionary = await Porteiro.interpretar("qualquer coisa")
	_afirmar("porteiro desligado devolve ficha vazia sem tentar a rede", ficha.is_empty())


## Testa a camada trocável da ADR-002: hoje sem IA, só palavras-chave.
func _testar_interpretador_reconhece_bola_de_fogo() -> void:
	var ficha := Interpretador.interpretar("quero conjurar uma BOLA de FOGO enorme")
	_afirmar("interpretador reconhece \"bola de fogo\" (sem diferenciar maiúsculas)", not ficha.is_empty())
	_afirmar("interpretador devolve a ficha certa", ficha.get("nome") == "Bola de Fogo")


func _testar_interpretador_nao_entende_frase_desconhecida() -> void:
	var ficha := Interpretador.interpretar("um dragão de cristal que canta ópera")
	_afirmar("interpretador devolve ficha vazia para frase desconhecida", ficha.is_empty())


## Testa a regra de que o custo de mana vem sempre do jogo, calculado a
## partir dos componentes já validados (proposta técnica, seção 3), nunca
## de um número sugerido pela ficha.
func _testar_validador_calcula_custo_de_mana_pelos_componentes() -> void:
	var ficha_pequena := {
		"componentes": [{"tipo": "projetil", "velocidade": 5.0, "ao_impactar": []}]
	}
	var ficha_grande := {
		"componentes": [
			{
				"tipo": "projetil",
				"velocidade": 20.0,
				"ao_impactar": [{"tipo": "explosao", "raio_m": 4.0, "dano": 30.0, "empurrao": 0.0}]
			}
		]
	}
	var custo_pequeno := Validador.calcular_custo_mana(Validador.validar_ficha(ficha_pequena))
	var custo_grande := Validador.calcular_custo_mana(Validador.validar_ficha(ficha_grande))
	_afirmar("custo de mana é positivo", custo_pequeno > 0.0)
	_afirmar("magia maior custa mais mana que uma pequena", custo_grande > custo_pequeno)


## Testa o caminho completo da Fase 2: texto -> Interpretador -> Validador
## -> Executor, sem precisar de internet nem de IA de verdade ainda.
func _testar_conjurar_por_texto_reconhecido_gasta_mana_e_cria_projetil() -> void:
	Porteiro.ativo = false
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	var mana_antes: float = mago.mana_atual
	mago.conjurar_por_texto("uma bola de fogo")
	await get_tree().process_frame

	_afirmar("conjurar por texto reconhecido gasta mana", mago.mana_atual < mana_antes)
	var projeteis := get_children().filter(func(n): return n.get_script() == load("res://scripts/magia/projetil.gd"))
	_afirmar("conjurar por texto reconhecido cria um projétil no mundo", projeteis.size() == 1)
	for p in projeteis:
		p.queue_free()
	mago.queue_free()


## Achado ao revisar a Fase 2: a IA às vezes pode devolver uma ficha
## "educada" (com nome e legenda) mas sem nenhum componente de verdade.
## Isso tem que contar como "não entendi", senão o jogador gasta a tentativa
## e não vê nada acontecer, sem nenhum aviso.
func _testar_ficha_sem_componentes_conta_como_nao_entendida() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	_afirmar("dicionário vazio conta como sem componentes", mago._ficha_sem_componentes({}))
	_afirmar(
		"ficha com lista de componentes vazia conta como sem componentes",
		mago._ficha_sem_componentes({"nome": "Nada", "componentes": []})
	)
	_afirmar(
		"componente sem nenhum ao_impactar conta como sem componentes",
		mago._ficha_sem_componentes({"componentes": [{"tipo": "projetil"}]})
	)
	_afirmar(
		"componente com dano e empurrão zerados conta como sem componentes (achado com o Vitor)",
		mago._ficha_sem_componentes({
			"componentes": [{"tipo": "projetil", "ao_impactar": [{"tipo": "explosao", "dano": 0.0, "empurrao": 0.0}]}]
		})
	)
	_afirmar(
		"componente com dano de verdade não conta como vazia",
		not mago._ficha_sem_componentes({
			"componentes": [{"tipo": "projetil", "ao_impactar": [{"tipo": "explosao", "dano": 10.0, "empurrao": 0.0}]}]
		})
	)

	mago.queue_free()


func _testar_conjurar_por_texto_desconhecido_nao_gasta_mana() -> void:
	Porteiro.ativo = false
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	var mana_antes: float = mago.mana_atual
	mago.conjurar_por_texto("um dragão de cristal que canta ópera")
	await get_tree().process_frame

	_afirmar("conjurar por texto desconhecido não gasta mana", mago.mana_atual == mana_antes)
	mago.queue_free()
