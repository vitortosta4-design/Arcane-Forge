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
	_testar_validador_aguenta_campos_com_tipo_errado_da_ia()
	await _testar_ficha_com_componentes_null_conta_como_nao_entendida()
	await _testar_mira_identica_entre_1a_e_3a_pessoa()
	await _testar_galinha_morre_com_vida_zero()
	await _testar_explosao_quebra_caixa_e_acende_barril()
	await _testar_executor_cria_projetil_a_partir_da_ficha()
	await _testar_projetil_usa_a_cor_do_material_da_ficha()
	await _testar_projetil_usa_a_forma_da_ficha()
	await _testar_porteiro_desligado_nao_faz_pedido_e_devolve_vazio()
	await _testar_gerenciador_som_respeita_limite_simultaneo()
	_testar_interpretador_reconhece_bola_de_fogo()
	_testar_interpretador_nao_entende_frase_desconhecida()
	_testar_validador_calcula_custo_de_mana_pelos_componentes()
	await _testar_conjurar_por_texto_reconhecido_gasta_mana_e_cria_projetil()
	await _testar_conjurar_por_texto_desconhecido_nao_gasta_mana()
	await _testar_ficha_sem_componentes_conta_como_nao_entendida()
	_testar_validador_corta_cura_acima_do_limite()
	_testar_validador_calcula_custo_de_mana_da_cura()
	await _testar_executor_aplica_cura_no_dono_da_ficha()
	await _testar_cura_nao_passa_do_teto_de_vida()
	await _testar_ficha_so_com_cura_zero_conta_como_nao_entendida()
	_testar_interpretador_reconhece_cura()
	_testar_validador_corta_escudo_acima_do_limite()
	_testar_validador_calcula_custo_de_mana_do_escudo()
	await _testar_executor_aplica_escudo_no_dono_da_ficha()
	await _testar_escudo_reduz_dano_recebido()
	await _testar_escudo_mais_forte_nao_e_substituido_por_um_mais_fraco()
	await _testar_escudo_expira_depois_da_duracao()
	_testar_ficha_so_com_escudo_sem_duracao_conta_como_nao_entendida()
	_testar_interpretador_reconhece_escudo()
	await _testar_ficha_com_cura_e_escudo_juntos_aplica_os_dois()
	_testar_custo_de_mana_soma_componentes_diferentes()
	_testar_validador_aceita_empurrao_negativo_para_puxar()
	await _testar_empurrao_negativo_puxa_o_mago_para_o_centro()
	await _testar_empurrao_negativo_conta_como_efeito_real()
	_testar_interpretador_reconhece_buraco_negro()
	_testar_validador_corta_estado_fora_da_lista_e_duracao_maxima()
	_testar_validador_calcula_custo_de_mana_do_estado()
	await _testar_lento_reduz_multiplicador_de_velocidade()
	await _testar_lento_expira_depois_da_duracao()
	await _testar_queimando_causa_dano_imediato_no_primeiro_tick()
	await _testar_reaplicar_queimando_estende_sem_duplicar_o_tick()
	await _testar_projetil_aplica_estado_em_quem_atingiu()
	_testar_ficha_so_com_estado_sem_duracao_conta_como_nao_entendida()
	_testar_interpretador_reconhece_queimando_e_lento()
	_testar_validador_corta_invocacao_nos_limites_e_padroes()
	_testar_validador_calcula_custo_de_mana_da_invocacao()
	await _testar_executor_cria_invocacao_com_vida_e_duracao_da_ficha()
	await _testar_executor_respeita_limite_de_criaturas_invocadas()
	await _testar_invocacao_morre_com_vida_zero()
	await _testar_invocacao_persegue_inimigo_mais_proximo()
	await _testar_invocacao_expira_depois_da_duracao()
	_testar_ficha_so_com_invocacao_sem_vida_conta_como_nao_entendida()
	_testar_interpretador_reconhece_pombo()
	_testar_validador_monta_projetil_do_lancador()
	_testar_validador_calcula_custo_do_lancador()
	await _testar_executor_anexa_lancador_na_criatura_certa()
	await _testar_criatura_com_lancador_dispara_no_inimigo()
	await _testar_lancador_sem_criatura_nao_cria_nada()
	await _testar_galinha_tambem_fica_lenta()
	await _testar_molhado_apaga_queimando()
	await _testar_alvo_molhado_nao_pega_fogo()
	await _testar_eletrizado_da_choque()
	await _testar_eletricidade_em_molhado_espalha_so_perto()
	_testar_interpretador_reconhece_agua_faisca_e_bombardeiro()
	await _testar_ovo_do_pombo_nao_machuca_quem_invocou()

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


## Achado numa revisão de segurança: a IA pode mandar "componentes": null
## (ou outro lixo de tipo errado em qualquer campo) em vez de uma lista de
## verdade. Antes disso quebrava um tipo fixo (Array/float) no meio da
## função e devolvia um resultado errado sem avisar ninguém. Testa que o
## validador aguenta isso sem travar e sem deixar passar.
func _testar_validador_aguenta_campos_com_tipo_errado_da_ia() -> void:
	var corrigida := Validador.validar_ficha({"componentes": null})
	_afirmar(
		"componentes: null vira lista vazia, não quebra",
		(corrigida["componentes"] as Array).is_empty()
	)

	var corrigida2 := Validador.validar_ficha({
		"componentes": ["isso não é um dicionário", 123, null, {"tipo": "projetil", "velocidade": "muito rápido"}]
	})
	var lista2: Array = corrigida2["componentes"]
	_afirmar("lixo dentro da lista de componentes é ignorado, só sobra o dicionário válido", lista2.size() == 1)
	_afirmar(
		"velocidade como texto vira o padrão em vez de quebrar",
		is_equal_approx(lista2[0]["velocidade"], 10.0)
	)


## A mesma ficha maluca não pode fazer o mago gastar mana e conjurar nada
## sem o jogador perceber (o bug de verdade que a revisão achou).
func _testar_ficha_com_componentes_null_conta_como_nao_entendida() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	_afirmar(
		"ficha com componentes:null conta como sem componentes (não passa sem ser percebida)",
		mago._ficha_sem_componentes({"nome": "Mistério", "componentes": null, "legenda": "..."})
	)

	mago.queue_free()


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


## Pedido do Vitor: as magias não podem ser sempre uma bolinha. Testa que um
## componente com "forma": "cubo" realmente vira uma malha de cubo, não a
## esfera padrão da cena do projétil.
func _testar_projetil_usa_a_forma_da_ficha() -> void:
	var ficha := {
		"componentes": [
			{
				"tipo": "projetil",
				"material": "pedra",
				"forma": "cubo",
				"velocidade": 10.0,
				"ao_impactar": []
			}
		]
	}
	Executor.executar_ficha(ficha, Vector3(0, 1, 0), Vector3.FORWARD, null, self)
	await get_tree().process_frame

	var projeteis := get_children().filter(func(n): return n.get_script() == load("res://scripts/magia/projetil.gd"))
	_afirmar("projétil cúbico foi criado", projeteis.size() == 1)
	if projeteis.size() > 0:
		var projetil = projeteis[0]
		var mesh: MeshInstance3D = projetil.get_node("MeshInstance3D")
		_afirmar("projétil com forma cubo usa uma malha de caixa", mesh.mesh is BoxMesh)
		projetil.queue_free()


## Testa o limite de sons simultâneos do ADR-026: pedir mais sons do que o
## limite não deve travar nem estourar a lista de tocadores ativos.
func _testar_gerenciador_som_respeita_limite_simultaneo() -> void:
	for i in GerenciadorSom.LIMITE_SONS_SIMULTANEOS + 10:
		GerenciadorSom.tocar_tiro(Vector3.ZERO)
	_afirmar(
		"gerenciador de som nunca passa do limite simultâneo",
		GerenciadorSom._tocadores_ativos.size() <= GerenciadorSom.LIMITE_SONS_SIMULTANEOS
	)
	for tocador in GerenciadorSom._tocadores_ativos:
		tocador.stop()
		tocador.queue_free()
	GerenciadorSom._tocadores_ativos.clear()
	await get_tree().process_frame


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


## Testa o componente "cura" (proposta técnica, seção 3, primeira leva da
## Fase 2): mesma regra de corte de outros componentes, nunca confiar num
## número que a IA sugira sem passar pelo limite do jogo.
func _testar_validador_corta_cura_acima_do_limite() -> void:
	var ficha := {"componentes": [{"tipo": "cura", "quantidade": 999.0}]}
	var corrigida := Validador.validar_ficha(ficha)
	_afirmar(
		"cura cortada no limite máximo",
		corrigida["componentes"][0]["quantidade"] == Validador.CURA_MAXIMA
	)


func _testar_validador_calcula_custo_de_mana_da_cura() -> void:
	var ficha_pequena := Validador.validar_ficha({"componentes": [{"tipo": "cura", "quantidade": 5.0}]})
	var ficha_grande := Validador.validar_ficha({"componentes": [{"tipo": "cura", "quantidade": 20.0}]})
	var custo_pequeno := Validador.calcular_custo_mana(ficha_pequena)
	var custo_grande := Validador.calcular_custo_mana(ficha_grande)
	_afirmar("cura custa mana", custo_pequeno > 0.0)
	_afirmar("cura maior custa mais mana que uma pequena", custo_grande > custo_pequeno)


## Testa o caminho completo: Executor lê o componente "cura" da ficha e
## chama mago.curar(), em vez de precisar de projétil ou colisão.
func _testar_executor_aplica_cura_no_dono_da_ficha() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	mago.receber_dano(40.0, Vector3.ZERO, 0.0)
	Executor.executar_ficha(FichasPadrao.luz_curativa(), Vector3.ZERO, Vector3.FORWARD, mago, self)
	await get_tree().process_frame

	_afirmar("executor curou o dono da ficha", is_equal_approx(mago.vida_atual, 80.0))
	mago.queue_free()


func _testar_cura_nao_passa_do_teto_de_vida() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	mago.receber_dano(10.0, Vector3.ZERO, 0.0)
	mago.curar(1000.0)
	_afirmar("cura nunca passa do teto de vida", mago.vida_atual == mago.vida_maxima)
	mago.queue_free()


## Mesma regra do "projétil fantasma": uma cura de quantidade zero não pode
## passar como magia entendida, senão o jogador gasta a tentativa e não vê
## nada acontecer sem nenhum aviso (ADR-002).
func _testar_ficha_so_com_cura_zero_conta_como_nao_entendida() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	_afirmar(
		"cura de quantidade zero conta como sem componentes",
		mago._ficha_sem_componentes({"componentes": [{"tipo": "cura", "quantidade": 0.0}]})
	)
	_afirmar(
		"cura de quantidade real não conta como vazia",
		not mago._ficha_sem_componentes({"componentes": [{"tipo": "cura", "quantidade": 15.0}]})
	)
	mago.queue_free()


func _testar_interpretador_reconhece_cura() -> void:
	var ficha := Interpretador.interpretar("quero uma luz de CURA para mim")
	_afirmar("interpretador reconhece \"cura\"", not ficha.is_empty())
	_afirmar("interpretador devolve a ficha de luz curativa", ficha.get("nome") == "Luz Curativa")


## Testa o componente "escudo" (proposta técnica, seção 3, primeira leva da
## Fase 2): mesma regra de corte das outras magias.
func _testar_validador_corta_escudo_acima_do_limite() -> void:
	var ficha := {"componentes": [{"tipo": "escudo", "reducao": 5.0, "duracao_s": 999.0}]}
	var corrigida := Validador.validar_ficha(ficha)
	var escudo: Dictionary = corrigida["componentes"][0]
	_afirmar("redução do escudo cortada no limite máximo (nunca 100%)", escudo["reducao"] == Validador.REDUCAO_ESCUDO_MAXIMA)
	_afirmar("duração do escudo cortada no limite máximo", escudo["duracao_s"] == Validador.DURACAO_MAXIMA_S)


func _testar_validador_calcula_custo_de_mana_do_escudo() -> void:
	var ficha_pequena := Validador.validar_ficha({"componentes": [{"tipo": "escudo", "reducao": 0.2, "duracao_s": 2.0}]})
	var ficha_grande := Validador.validar_ficha({"componentes": [{"tipo": "escudo", "reducao": 0.8, "duracao_s": 6.0}]})
	var custo_pequeno := Validador.calcular_custo_mana(ficha_pequena)
	var custo_grande := Validador.calcular_custo_mana(ficha_grande)
	_afirmar("escudo custa mana", custo_pequeno > 0.0)
	_afirmar("escudo maior e mais longo custa mais mana", custo_grande > custo_pequeno)


## Testa o caminho completo: Executor lê o componente "escudo" da ficha e
## chama mago.aplicar_escudo(), em vez de precisar de projétil ou alvo.
func _testar_executor_aplica_escudo_no_dono_da_ficha() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	Executor.executar_ficha(FichasPadrao.escudo_de_pedra(), Vector3.ZERO, Vector3.FORWARD, mago, self)
	await get_tree().process_frame

	_afirmar("executor aplicou o escudo no dono da ficha", mago._reducao_escudo > 0.0)
	mago.queue_free()


func _testar_escudo_reduz_dano_recebido() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	mago.aplicar_escudo(0.5, 5.0)
	mago.receber_dano(20.0, Vector3.ZERO, 0.0)
	_afirmar("escudo de 50% reduz o dano recebido pela metade", is_equal_approx(mago.vida_atual, 90.0))
	mago.queue_free()


## A proposta técnica não prevê somar escudos (duas magias fracas virando
## imunidade total). Testa que aplicar um escudo mais fraco por cima de um
## mais forte não enfraquece a proteção que já estava ativa.
func _testar_escudo_mais_forte_nao_e_substituido_por_um_mais_fraco() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	mago.aplicar_escudo(0.7, 5.0)
	mago.aplicar_escudo(0.3, 5.0)
	_afirmar("escudo mais fraco não substitui o mais forte já ativo", is_equal_approx(mago._reducao_escudo, 0.7))
	mago.queue_free()


func _testar_escudo_expira_depois_da_duracao() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	mago.aplicar_escudo(0.5, 0.05)
	await get_tree().create_timer(0.2).timeout
	_afirmar("escudo some depois da duração acabar", mago._reducao_escudo == 0.0)
	mago.queue_free()


func _testar_ficha_so_com_escudo_sem_duracao_conta_como_nao_entendida() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	_afirmar(
		"escudo sem duração conta como sem componentes",
		mago._ficha_sem_componentes({"componentes": [{"tipo": "escudo", "reducao": 0.5, "duracao_s": 0.0}]})
	)
	_afirmar(
		"escudo com duração real não conta como vazio",
		not mago._ficha_sem_componentes({"componentes": [{"tipo": "escudo", "reducao": 0.5, "duracao_s": 5.0}]})
	)
	mago.queue_free()


func _testar_interpretador_reconhece_escudo() -> void:
	var ficha := Interpretador.interpretar("quero um ESCUDO para me proteger")
	_afirmar("interpretador reconhece \"escudo\"", not ficha.is_empty())
	_afirmar("interpretador devolve a ficha de escudo de pedra", ficha.get("nome") == "Escudo de Pedra")


## O prompt da IA (supabase/functions/interpretar-magia/index.ts) agora avisa
## que uma ficha pode combinar mais de um componente na mesma lista (ex.: um
## projétil E um escudo). Testa que o jogo realmente aplica os dois quando
## isso acontece, não só o primeiro da lista.
func _testar_ficha_com_cura_e_escudo_juntos_aplica_os_dois() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	mago.receber_dano(50.0, Vector3.ZERO, 0.0)
	var ficha := {
		"componentes": [
			{"tipo": "cura", "quantidade": 10.0},
			{"tipo": "escudo", "reducao": 0.5, "duracao_s": 5.0}
		]
	}
	Executor.executar_ficha(ficha, Vector3.ZERO, Vector3.FORWARD, mago, self)
	await get_tree().process_frame

	_afirmar("ficha com cura e escudo juntos aplicou a cura", is_equal_approx(mago.vida_atual, 60.0))
	_afirmar("ficha com cura e escudo juntos aplicou o escudo", mago._reducao_escudo > 0.0)
	mago.queue_free()


func _testar_custo_de_mana_soma_componentes_diferentes() -> void:
	var ficha_so_cura := Validador.validar_ficha({"componentes": [{"tipo": "cura", "quantidade": 10.0}]})
	var ficha_cura_e_escudo := Validador.validar_ficha({
		"componentes": [
			{"tipo": "cura", "quantidade": 10.0},
			{"tipo": "escudo", "reducao": 0.3, "duracao_s": 3.0}
		]
	})
	var custo_so_cura := Validador.calcular_custo_mana(ficha_so_cura)
	var custo_dos_dois := Validador.calcular_custo_mana(ficha_cura_e_escudo)
	_afirmar("custo de mana soma os dois componentes, não só o primeiro", custo_dos_dois > custo_so_cura)


## "Empurrar/puxar" (proposta técnica, seção 3) não é um componente novo:
## é o "empurrao" da explosão aceitando sinal negativo para puxar para o
## centro em vez de afastar (ex.: um mini buraco negro).
func _testar_validador_aceita_empurrao_negativo_para_puxar() -> void:
	var ficha := {"componentes": [{"tipo": "explosao", "empurrao": -999.0}]}
	var corrigida := Validador.validar_ficha(ficha)
	_afirmar(
		"empurrão muito negativo é cortado no limite, não zerado",
		corrigida["componentes"][0]["empurrao"] == -Validador.EMPURRAO_MAXIMO
	)


func _testar_empurrao_negativo_puxa_o_mago_para_o_centro() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	mago.global_position = Vector3(5, 0, 0)
	mago.velocity = Vector3.ZERO # isola o empurrão: sem isso, a gravidade já acumulada no eixo Y atrapalha a comparação de direção
	var origem := Vector3.ZERO
	mago.receber_dano(0.0, origem, -3.0)

	var pos_mago: Vector3 = mago.global_position
	var direcao_esperada := (origem - pos_mago).normalized()
	_afirmar(
		"empurrão negativo puxa o mago na direção do centro, não para longe",
		mago.velocity.normalized().is_equal_approx(direcao_esperada)
	)
	mago.queue_free()


## Mesma regra do "projétil fantasma": um empurrão/puxão de verdade (mesmo
## sem dano) tem que contar como magia entendida.
func _testar_empurrao_negativo_conta_como_efeito_real() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	_afirmar(
		"empurrão negativo (puxar) sem dano ainda conta como efeito real",
		not mago._ficha_sem_componentes({
			"componentes": [{"tipo": "projetil", "ao_impactar": [{"tipo": "explosao", "dano": 0.0, "empurrao": -3.0}]}]
		})
	)
	mago.queue_free()


func _testar_interpretador_reconhece_buraco_negro() -> void:
	var ficha := Interpretador.interpretar("quero invocar um buraco negro que puxa tudo")
	_afirmar("interpretador reconhece \"buraco negro\"", not ficha.is_empty())
	_afirmar("interpretador devolve a ficha do mini buraco negro", ficha.get("nome") == "Mini Buraco Negro")


## Componente "estado" (proposta técnica, seção 3: queimando, molhado,
## eletrizado, cego, lento). Só "queimando" e "lento" têm efeito de verdade
## por enquanto; os outros caem no padrão seguro, igual a qualquer valor
## fora de uma lista fechada.
func _testar_validador_corta_estado_fora_da_lista_e_duracao_maxima() -> void:
	var ficha := {"componentes": [{"tipo": "estado", "nome_estado": "cego", "duracao_s": 999.0}]}
	var corrigida := Validador.validar_ficha(ficha)
	var estado: Dictionary = corrigida["componentes"][0]
	_afirmar(
		"estado ainda não implementado vira um padrão seguro da lista",
		estado["nome_estado"] in Validador.ESTADOS_VALIDOS
	)
	_afirmar("duração do estado cortada no limite máximo", estado["duracao_s"] == Validador.DURACAO_MAXIMA_S)


func _testar_validador_calcula_custo_de_mana_do_estado() -> void:
	var ficha_curta := Validador.validar_ficha({"componentes": [{"tipo": "estado", "nome_estado": "lento", "duracao_s": 1.0}]})
	var ficha_longa := Validador.validar_ficha({"componentes": [{"tipo": "estado", "nome_estado": "lento", "duracao_s": 6.0}]})
	var custo_curto := Validador.calcular_custo_mana(ficha_curta)
	var custo_longo := Validador.calcular_custo_mana(ficha_longa)
	_afirmar("estado custa mana", custo_curto > 0.0)
	_afirmar("estado mais longo custa mais mana", custo_longo > custo_curto)


func _testar_lento_reduz_multiplicador_de_velocidade() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	_afirmar("sem lentidão, multiplicador de velocidade é 1", mago._multiplicador_velocidade() == 1.0)
	mago.aplicar_estado("lento", 2.0)
	_afirmar("com lentidão, multiplicador de velocidade cai", mago._multiplicador_velocidade() < 1.0)
	mago.queue_free()


func _testar_lento_expira_depois_da_duracao() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	mago.aplicar_estado("lento", 0.05)
	await get_tree().create_timer(0.3).timeout
	_afirmar("lentidão termina depois da duração", mago._multiplicador_velocidade() == 1.0)
	mago.queue_free()


func _testar_queimando_causa_dano_imediato_no_primeiro_tick() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	var vida_antes: float = mago.vida_atual
	mago.aplicar_estado("queimando", 1.0)
	_afirmar("queimando causa dano logo no primeiro tick, sem esperar 1s", mago.vida_atual < vida_antes)
	mago.queue_free()


## Achado pensando no caso "duas chamas no mesmo alvo": reaplicar queimando
## não pode somar um segundo incêndio por cima (dano em dobro na hora), só
## estender a duração do que já está queimando.
func _testar_reaplicar_queimando_estende_sem_duplicar_o_tick() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	mago.aplicar_estado("queimando", 3.0)
	var vida_depois_do_primeiro_tick: float = mago.vida_atual
	mago.aplicar_estado("queimando", 5.0) # reaplica por cima, antes do próximo tick
	_afirmar(
		"reaplicar queimando não causa um segundo tick de dano na hora",
		mago.vida_atual == vida_depois_do_primeiro_tick
	)
	_afirmar(
		"reaplicar queimando estende a duração para a maior das duas",
		mago.estados._ticks_queimando_restantes == 5
	)
	mago.queue_free()


## Testa o caminho completo: um projétil com "estado" no ao_impactar aplica
## o estado em quem ele atingiu, não numa área ao redor (diferente da
## explosão).
func _testar_projetil_aplica_estado_em_quem_atingiu() -> void:
	var projetil: Node = load("res://cenas/magias/projetil.tscn").instantiate()
	add_child(projetil)
	projetil.ao_impactar = [{"tipo": "estado", "nome_estado": "lento", "duracao_s": 3.0}]

	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	await get_tree().process_frame

	projetil._explodir(mago)
	_afirmar("projétil aplicou o estado em quem atingiu", mago.estados._lento_restante_s > 0.0)
	mago.queue_free()


func _testar_ficha_so_com_estado_sem_duracao_conta_como_nao_entendida() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	_afirmar(
		"estado sem duração conta como sem componentes",
		mago._ficha_sem_componentes({"componentes": [{"tipo": "estado", "nome_estado": "lento", "duracao_s": 0.0}]})
	)
	_afirmar(
		"estado com duração real não conta como vazio",
		not mago._ficha_sem_componentes({"componentes": [{"tipo": "estado", "nome_estado": "lento", "duracao_s": 3.0}]})
	)
	mago.queue_free()


func _testar_interpretador_reconhece_queimando_e_lento() -> void:
	var ficha_queimando := Interpretador.interpretar("quero uma chama que fica queimando")
	_afirmar("interpretador reconhece \"queimando\"", not ficha_queimando.is_empty())
	_afirmar("interpretador devolve a ficha de chama persistente", ficha_queimando.get("nome") == "Chama Persistente")

	var ficha_lento := Interpretador.interpretar("um vento gelado que deixa tudo mais lento")
	_afirmar("interpretador reconhece \"lento\"", not ficha_lento.is_empty())
	_afirmar("interpretador devolve a ficha de vento gelado", ficha_lento.get("nome") == "Vento Gelado")


## Componente "invocação" (proposta técnica, seção 3, exemplo do "Pombo de
## Pedra"). O Host já tinha o controle de limite pronto (ADR-004); esta é a
## primeira coisa que o liga de verdade.
func _testar_validador_corta_invocacao_nos_limites_e_padroes() -> void:
	var ficha := {
		"componentes": [{
			"tipo": "invocacao",
			"corpo": "dragao",
			"comportamento": "ignorar_tudo",
			"escala": 999.0,
			"vida": 999.0,
			"duracao_s": 999.0,
			"dano_contato": 999.0
		}]
	}
	var corrigida := Validador.validar_ficha(ficha)
	var invocacao: Dictionary = corrigida["componentes"][0]
	_afirmar("corpo fora da lista vira um padrão seguro", invocacao["corpo"] in Validador.CORPOS_VALIDOS)
	_afirmar("comportamento fora da lista vira um padrão seguro", invocacao["comportamento"] in Validador.COMPORTAMENTOS_VALIDOS)
	_afirmar("escala cortada no limite máximo", invocacao["escala"] == Validador.ESCALA_INVOCACAO_MAXIMA)
	_afirmar("vida cortada no limite máximo", invocacao["vida"] == Validador.VIDA_INVOCACAO_MAXIMA)
	_afirmar("duração cortada no limite máximo", invocacao["duracao_s"] == Validador.DURACAO_MAXIMA_S)
	_afirmar("dano de contato cortado no limite máximo", invocacao["dano_contato"] == Validador.DANO_CONTATO_MAXIMO)


func _testar_validador_calcula_custo_de_mana_da_invocacao() -> void:
	var ficha_fraca := Validador.validar_ficha({"componentes": [{"tipo": "invocacao", "vida": 5.0, "duracao_s": 2.0, "dano_contato": 2.0}]})
	var ficha_forte := Validador.validar_ficha({"componentes": [{"tipo": "invocacao", "vida": 35.0, "duracao_s": 7.0, "dano_contato": 7.0}]})
	var custo_fraco := Validador.calcular_custo_mana(ficha_fraca)
	var custo_forte := Validador.calcular_custo_mana(ficha_forte)
	_afirmar("invocação custa mana", custo_fraco > 0.0)
	_afirmar("invocação mais forte custa mais mana", custo_forte > custo_fraco)


## Testa o caminho completo: o Executor lê "vida", "dano_contato" e
## "duracao_s" da ficha e aplica na criatura antes dela entrar na árvore
## (achado implementando: lido depois do add_child, o _ready() da criatura
## já tinha capturado os valores padrão, e a ficha seria ignorada).
func _testar_executor_cria_invocacao_com_vida_e_duracao_da_ficha() -> void:
	var ficha := Validador.validar_ficha({
		"componentes": [{"tipo": "invocacao", "material": "metal", "vida": 33.0, "duracao_s": 5.0, "dano_contato": 4.0}]
	})
	Executor.executar_ficha(ficha, Vector3(2, 0, 2), Vector3.FORWARD, null, self)
	await get_tree().process_frame

	var criaturas := get_tree().get_nodes_in_group("criatura_invocada")
	_afirmar("executor criou uma criatura invocada no mundo", criaturas.size() == 1)
	if criaturas.size() > 0:
		var criatura = criaturas[0]
		_afirmar("criatura nasceu com a vida da ficha, não o padrão", criatura._vida_atual == 33.0)
		_afirmar("criatura nasceu com o dano de contato da ficha", criatura.dano_contato == 4.0)
		Host.criaturas_invocadas.erase(criatura)
		criatura.queue_free()


func _testar_executor_respeita_limite_de_criaturas_invocadas() -> void:
	var ficha := FichasPadrao.pombo_de_pedra()
	var criadas: Array = []
	for i in Host.LIMITE_CRIATURAS_INVOCADAS + 2:
		Executor.executar_ficha(ficha, Vector3(i, 0, 0), Vector3.FORWARD, null, self)
	await get_tree().process_frame

	var criaturas := get_tree().get_nodes_in_group("criatura_invocada")
	_afirmar(
		"invocação para de criar criaturas no limite do Host (ADR-004)",
		criaturas.size() == Host.LIMITE_CRIATURAS_INVOCADAS
	)
	for criatura in criaturas:
		Host.criaturas_invocadas.erase(criatura)
		criatura.queue_free()


func _testar_invocacao_morre_com_vida_zero() -> void:
	var criatura: Node = load("res://cenas/magias/invocacao.tscn").instantiate()
	criatura.vida = 10.0
	add_child(criatura)
	await get_tree().process_frame

	criatura.receber_dano(15.0, Vector3.ZERO, 0.0)
	_afirmar("criatura invocada morre com dano suficiente", not is_instance_valid(criatura) or not criatura.is_in_group("recebe_dano"))


## Mesma lógica da galinha zumbi (mira no mago mais próximo), mas a
## invocação mira no grupo "inimigo" em vez de "mago" — ela luta pro
## jogador, não contra ele.
func _testar_invocacao_persegue_inimigo_mais_proximo() -> void:
	var criatura: Node = load("res://cenas/magias/invocacao.tscn").instantiate()
	add_child(criatura)
	criatura.global_position = Vector3(0, 0, 0)

	var inimigo := Node3D.new()
	add_child(inimigo)
	inimigo.add_to_group("inimigo")
	inimigo.global_position = Vector3(5, 0, 0)

	await get_tree().physics_frame
	await get_tree().physics_frame

	_afirmar("invocação anda na direção do inimigo mais próximo", criatura.velocity.x > 0.0)

	criatura.queue_free()
	inimigo.queue_free()


func _testar_invocacao_expira_depois_da_duracao() -> void:
	var criatura: Node = load("res://cenas/magias/invocacao.tscn").instantiate()
	criatura.duracao_s = 0.05
	add_child(criatura)
	await get_tree().create_timer(0.3).timeout
	_afirmar("criatura invocada some sozinha depois da duração", not is_instance_valid(criatura))


func _testar_ficha_so_com_invocacao_sem_vida_conta_como_nao_entendida() -> void:
	var cena: PackedScene = load("res://cenas/mago.tscn")
	var mago := cena.instantiate()
	add_child(mago)
	_afirmar(
		"invocação sem vida conta como sem componentes",
		mago._ficha_sem_componentes({"componentes": [{"tipo": "invocacao", "vida": 0.0, "duracao_s": 6.0}]})
	)
	_afirmar(
		"invocação com vida e duração reais não conta como vazia",
		not mago._ficha_sem_componentes({"componentes": [{"tipo": "invocacao", "vida": 20.0, "duracao_s": 6.0}]})
	)
	mago.queue_free()


func _testar_interpretador_reconhece_pombo() -> void:
	var ficha := Interpretador.interpretar("quero invocar um pombo para me ajudar")
	_afirmar("interpretador reconhece \"pombo\"", not ficha.is_empty())
	_afirmar("interpretador devolve a ficha do pombo de pedra", ficha.get("nome") == "Pombo de Pedra")


## Lançador (proposta técnica, seção 3): aceita o formato da proposta, com
## "ao_impactar" ao lado do "projetil", e vira um projétil validado completo.
func _testar_validador_monta_projetil_do_lancador() -> void:
	var corrigida := Validador.validar_ficha({
		"componentes": [{
			"tipo": "lancador",
			"intervalo_s": 0.01,
			"projetil": {"forma": "ovo", "material": "queijo", "velocidade": 999.0},
			"ao_impactar": [{"tipo": "explosao", "dano": 999.0}]
		}]
	})
	var lancador: Dictionary = corrigida["componentes"][0]
	var projetil: Dictionary = lancador["projetil"]
	_afirmar("intervalo do lançador nunca abaixo do mínimo", lancador["intervalo_s"] == Validador.INTERVALO_LANCADOR_MINIMO_S)
	_afirmar("projétil do lançador vira tipo projetil", projetil.get("tipo") == "projetil")
	_afirmar("material do projétil do lançador cai na lista fechada", projetil["material"] in Validador.MATERIAIS_VALIDOS)
	_afirmar("velocidade do projétil do lançador cortada", projetil["velocidade"] == Validador.VELOCIDADE_MAXIMA)
	_afirmar("ao_impactar do lançador vai para dentro do projétil, já validado", projetil["ao_impactar"][0]["dano"] == Validador.DANO_MAXIMO)


func _testar_validador_calcula_custo_do_lancador() -> void:
	var lento := Validador.validar_ficha({"componentes": [{"tipo": "lancador", "intervalo_s": 4.0, "projetil": {}}]})
	var rapido := Validador.validar_ficha({"componentes": [{"tipo": "lancador", "intervalo_s": 1.0, "projetil": {}}]})
	_afirmar("lançador custa mana", Validador.calcular_custo_mana(lento) > 0.0)
	_afirmar("lançador que dispara mais rápido custa mais", Validador.calcular_custo_mana(rapido) > Validador.calcular_custo_mana(lento))


func _testar_executor_anexa_lancador_na_criatura_certa() -> void:
	# Lançador listado ANTES da criatura de propósito: tem que funcionar igual.
	var ficha := FichasPadrao.pombo_bombardeiro()
	ficha["componentes"].reverse()
	Executor.executar_ficha(ficha, Vector3(3, 0, 3), Vector3.FORWARD, null, self)
	await get_tree().process_frame

	var criaturas := get_tree().get_nodes_in_group("criatura_invocada")
	_afirmar("bombardeiro criou uma criatura", criaturas.size() == 1)
	if criaturas.size() > 0:
		_afirmar("lançador foi anexado à criatura", criaturas[0].lancador_intervalo_s == 1.5)
		_afirmar("projétil do lançador tem a explosão da ficha", criaturas[0].lancador_projetil["ao_impactar"].size() == 1)
		criaturas[0].queue_free()
	await get_tree().process_frame


func _testar_criatura_com_lancador_dispara_no_inimigo() -> void:
	var criatura: Node = load("res://cenas/magias/invocacao.tscn").instantiate()
	add_child(criatura)
	criatura.global_position = Vector3(20, 0, 20)
	criatura.anexar_lancador(Validador.validar_ficha({"componentes": [{"tipo": "projetil", "velocidade": 5.0}]})["componentes"][0], 0.8)

	var inimigo := Node3D.new()
	add_child(inimigo)
	inimigo.add_to_group("inimigo")
	inimigo.global_position = Vector3(26, 0, 20)

	await get_tree().create_timer(1.1).timeout

	var projeteis := get_children().filter(func(n): return n.get_script() == load("res://scripts/magia/projetil.gd"))
	var do_pombo := projeteis.filter(func(p): return p.dono == criatura)
	_afirmar("criatura com lançador disparou um projétil", do_pombo.size() >= 1)
	if do_pombo.size() > 0:
		var frente: Vector3 = -(do_pombo[0] as Node3D).global_transform.basis.z
		_afirmar("projétil do lançador vai na direção do inimigo", frente.x > 0.5)
	for p in projeteis:
		p.queue_free()
	criatura.queue_free()
	inimigo.queue_free()
	await get_tree().process_frame


func _testar_lancador_sem_criatura_nao_cria_nada() -> void:
	var ficha := {"componentes": [{"tipo": "lancador", "intervalo_s": 1.0, "projetil": {}}]}
	Executor.executar_ficha(ficha, Vector3.ZERO, Vector3.FORWARD, null, self)
	await get_tree().process_frame
	_afirmar("lançador sozinho não cria criatura nem quebra", get_tree().get_nodes_in_group("criatura_invocada").is_empty())


## Antes deste lote, estados só funcionavam no mago: a galinha ignorava
## "lento" e "queimando". Agora todo mundo usa o mesmo ControladorEstados.
func _testar_galinha_tambem_fica_lenta() -> void:
	var galinha: Node = load("res://cenas/inimigos/galinha_zumbi.tscn").instantiate()
	add_child(galinha)
	await get_tree().process_frame
	galinha.aplicar_estado("lento", 3.0)
	_afirmar("galinha zumbi também fica lenta", galinha.estados.multiplicador_velocidade() < 1.0)
	galinha.queue_free()


func _testar_molhado_apaga_queimando() -> void:
	var galinha: Node = load("res://cenas/inimigos/galinha_zumbi.tscn").instantiate()
	add_child(galinha)
	await get_tree().process_frame
	galinha.aplicar_estado("queimando", 5.0)
	galinha.aplicar_estado("molhado", 3.0)
	_afirmar("molhar apaga quem está queimando", not galinha.estados.esta_queimando())
	galinha.queue_free()


func _testar_alvo_molhado_nao_pega_fogo() -> void:
	var galinha: Node = load("res://cenas/inimigos/galinha_zumbi.tscn").instantiate()
	add_child(galinha)
	await get_tree().process_frame
	galinha.aplicar_estado("molhado", 3.0)
	var vida_antes: float = galinha._vida_atual
	galinha.aplicar_estado("queimando", 5.0)
	_afirmar("alvo molhado não pega fogo", not galinha.estados.esta_queimando())
	_afirmar("alvo molhado não leva dano de fogo", galinha._vida_atual == vida_antes)
	galinha.queue_free()


func _testar_eletrizado_da_choque() -> void:
	var galinha: Node = load("res://cenas/inimigos/galinha_zumbi.tscn").instantiate()
	add_child(galinha)
	await get_tree().process_frame
	var vida_antes: float = galinha._vida_atual
	galinha.aplicar_estado("eletrizado", 1.0)
	_afirmar("eletrizado dá dano na hora", is_equal_approx(galinha._vida_atual, vida_antes - ControladorEstados.DANO_ELETRICO))
	galinha.queue_free()


## O exemplo de etiquetas da proposta técnica: "eletricidade em algo molhado
## se espalha num raio". Quem está perto leva choque; quem está longe, não.
func _testar_eletricidade_em_molhado_espalha_so_perto() -> void:
	var cena: PackedScene = load("res://cenas/inimigos/galinha_zumbi.tscn")
	var alvo: Node = cena.instantiate()
	var vizinha: Node = cena.instantiate()
	var distante: Node = cena.instantiate()
	for g in [alvo, vizinha, distante]:
		add_child(g)
	alvo.global_position = Vector3(40, 0, 0)
	vizinha.global_position = Vector3(41.5, 0, 0)
	distante.global_position = Vector3(50, 0, 0)
	await get_tree().process_frame

	var vida_inicial: float = alvo._vida_atual
	alvo.aplicar_estado("molhado", 5.0)
	alvo.aplicar_estado("eletrizado", 1.0)

	_afirmar(
		"alvo molhado leva choque dobrado",
		is_equal_approx(alvo._vida_atual, vida_inicial - ControladorEstados.DANO_ELETRICO * ControladorEstados.MULTIPLICADOR_ELETRICO_MOLHADO)
	)
	_afirmar("choque se espalha para quem está perto", vizinha._vida_atual < vida_inicial)
	_afirmar("choque não chega em quem está longe", distante._vida_atual == vida_inicial)
	for g in [alvo, vizinha, distante]:
		g.queue_free()


func _testar_interpretador_reconhece_agua_faisca_e_bombardeiro() -> void:
	_afirmar("interpretador reconhece \"água\"", Interpretador.interpretar("um jato de água").get("nome") == "Jato d'Água")
	_afirmar("interpretador reconhece \"faísca\"", Interpretador.interpretar("uma faísca elétrica").get("nome") == "Faísca")
	_afirmar(
		"interpretador reconhece o pombo bombardeiro",
		Interpretador.interpretar("um pombo que solta ovos explosivos").get("nome") == "Pombo de Pedra Bombardeiro"
	)
	_afirmar(
		"\"pombo\" sozinho continua sendo o pombo simples",
		Interpretador.interpretar("invocar um pombo").get("nome") == "Pombo de Pedra"
	)


## Achado rodando o pombo bombardeiro quadro a quadro: o ovo explodindo na
## galinha tirava 12 de vida do próprio mago. Pela ADR-017, só magia "má"
## pode se voltar contra quem conjurou; o pombo é neutro.
func _testar_ovo_do_pombo_nao_machuca_quem_invocou() -> void:
	var mago: Node = load("res://cenas/mago.tscn").instantiate()
	var galinha: Node = load("res://cenas/inimigos/galinha_zumbi.tscn").instantiate()
	var ovo: Node = load("res://cenas/magias/projetil.tscn").instantiate()
	for n in [mago, galinha, ovo]:
		add_child(n)
	mago.global_position = Vector3(60, 0, 0)
	galinha.global_position = Vector3(61, 0, 0)
	ovo.global_position = Vector3(60.5, 0.5, 0)
	ovo.aliados = [mago]
	ovo.ao_impactar = [{"tipo": "explosao", "raio_m": 3.0, "dano": 10.0, "empurrao": 0.0}]
	await get_tree().process_frame

	# Compara só antes/depois da explosão: a galinha pode bicar o mago antes.
	var vida_mago: float = mago.vida_atual
	var vida_galinha: float = galinha._vida_atual
	ovo._explodir(galinha)
	_afirmar("ovo do pombo não machuca o mago que invocou", mago.vida_atual == vida_mago)
	_afirmar("ovo do pombo continua machucando o inimigo", galinha._vida_atual < vida_galinha)
	mago.queue_free()
	galinha.queue_free()
