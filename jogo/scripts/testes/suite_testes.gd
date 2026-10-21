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
	await _testar_estado_pinta_o_corpo_inteiro_da_galinha()
	await _testar_cor_do_estado_some_quando_ele_acaba()
	await _testar_choque_pisca_e_volta_para_a_cor_de_baixo()
	await _testar_hud_mostra_estados_do_mago()
	_testar_validador_corta_area()
	_testar_validador_calcula_custo_da_area()
	await _testar_area_machuca_so_quem_esta_dentro()
	await _testar_area_nao_machuca_quem_criou()
	await _testar_area_aplica_estado_em_quem_esta_dentro()
	await _testar_area_de_fogo_acende_barril()
	await _testar_area_some_depois_da_duracao()
	await _testar_limite_de_tres_areas_por_jogador()
	await _testar_projetil_deixa_area_no_chao()
	await _testar_area_no_topo_da_ficha_nasce_aos_pes_do_mago()
	_testar_ficha_so_com_area_sem_efeito_conta_como_nao_entendida()
	_testar_interpretador_reconhece_lava_e_chuva()
	_testar_validador_corta_parede_e_teleporte()
	_testar_validador_calcula_custo_de_parede_e_teleporte()
	await _testar_parede_nasce_na_frente_do_mago()
	await _testar_parede_segura_projetil()
	await _testar_parede_some_depois_da_duracao()
	await _testar_parede_e_area_dividem_o_limite_de_magias_ativas()
	await _testar_teleporte_leva_o_mago_para_frente()
	await _testar_teleporte_para_antes_da_parede()
	await _testar_teleporte_nao_vira_voo()
	_testar_parede_e_teleporte_contam_como_magia_de_verdade()
	_testar_interpretador_reconhece_muro_e_teleporte()
	_testar_validador_descarta_projetil_dentro_de_projetil()
	_testar_validador_limita_tamanho_das_listas()
	await _testar_galinha_cega_nao_persegue_nem_bica()
	await _testar_mago_cego_ve_a_tela_escura()
	await _testar_teleporte_faz_um_puf_na_saida_e_na_chegada()
	_testar_interpretador_reconhece_cegueira()
	await _testar_teleporte_da_clarao_na_tela_do_mago()
	_testar_validador_aceita_nomes_com_acento_e_maiuscula()

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
	var ficha := {"componentes": [{"tipo": "estado", "nome_estado": "petrificado", "duracao_s": 999.0}]}
	var corrigida := Validador.validar_ficha(ficha)
	var estado: Dictionary = corrigida["componentes"][0]
	_afirmar(
		"estado que não existe vira um padrão seguro da lista",
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


## Sinal visual dos estados (ADR-017: feedback claro). Antes deste lote
## nada mostrava que alguém estava molhado ou queimando.
func _testar_estado_pinta_o_corpo_inteiro_da_galinha() -> void:
	var galinha: Node = load("res://cenas/inimigos/galinha_zumbi.tscn").instantiate()
	add_child(galinha)
	await get_tree().process_frame
	galinha.aplicar_estado("molhado", 3.0)
	var malhas := galinha.find_children("*", "MeshInstance3D", true, false)
	var todas_pintadas := malhas.size() > 0 and malhas.all(func(m): return m.material_overlay != null)
	_afirmar("estado pinta todas as malhas da galinha (corpo e bico)", todas_pintadas)
	var cor: Color = galinha.estados.camada_atual().albedo_color
	_afirmar("molhado pinta de azul", cor.b > cor.r and cor.b > cor.g)
	galinha.queue_free()


func _testar_cor_do_estado_some_quando_ele_acaba() -> void:
	var galinha: Node = load("res://cenas/inimigos/galinha_zumbi.tscn").instantiate()
	add_child(galinha)
	await get_tree().process_frame
	galinha.aplicar_estado("lento", 0.05)
	await get_tree().create_timer(0.3).timeout
	var malhas := galinha.find_children("*", "MeshInstance3D", true, false)
	_afirmar("cor some quando o estado acaba", malhas.all(func(m): return m.material_overlay == null))
	galinha.queue_free()


func _testar_choque_pisca_e_volta_para_a_cor_de_baixo() -> void:
	var galinha: Node = load("res://cenas/inimigos/galinha_zumbi.tscn").instantiate()
	add_child(galinha)
	galinha.global_position = Vector3(80, 0, 0)
	await get_tree().process_frame
	galinha.aplicar_estado("molhado", 5.0)
	galinha.aplicar_estado("eletrizado", 1.0)
	_afirmar("choque aparece por cima de tudo", galinha.estados.ativos()[0] == "eletrizado")
	await get_tree().create_timer(ControladorEstados.DURACAO_PISCADA_CHOQUE_S + 0.2).timeout
	_afirmar("depois do choque volta a cor de molhado", galinha.estados.ativos() == ["molhado"])
	galinha.queue_free()


## Em primeira pessoa o jogador não vê o próprio corpo, então o HUD avisa.
func _testar_hud_mostra_estados_do_mago() -> void:
	var mago: Node = load("res://cenas/mago.tscn").instantiate()
	var hud: Node = load("res://cenas/hud.tscn").instantiate()
	add_child(mago)
	add_child(hud)
	await get_tree().process_frame
	hud.configurar(mago)
	mago.aplicar_estado("lento", 3.0)
	_afirmar("HUD mostra quando o mago está lento", "Lento" in hud.get_node("Estados").text)
	mago.queue_free()
	hud.queue_free()


## Área persistente (proposta técnica, seção 3).
func _testar_validador_corta_area() -> void:
	var c: Dictionary = Validador.validar_ficha({"componentes": [{
		"tipo": "area", "raio_m": 99.0, "duracao_s": 99.0, "dano_por_s": 99.0,
		"nome_estado": "petrificado", "material": "queijo"
	}]})["componentes"][0]
	_afirmar("raio da área cortado no limite", c["raio_m"] == Validador.RAIO_AREA_MAXIMO)
	_afirmar("duração da área cortada no limite", c["duracao_s"] == Validador.DURACAO_MAXIMA_S)
	_afirmar("dano por segundo da área cortado no limite", c["dano_por_s"] == Validador.DANO_AREA_POR_S_MAXIMO)
	_afirmar("estado fora da lista vira nenhum (área sem estado)", c["nome_estado"] == "")
	_afirmar("material fora da lista cai na lista fechada", c["material"] in Validador.MATERIAIS_VALIDOS)


func _testar_validador_calcula_custo_da_area() -> void:
	var sem_dano := Validador.validar_ficha({"componentes": [{"tipo": "area", "duracao_s": 3.0, "nome_estado": "molhado"}]})
	var com_dano := Validador.validar_ficha({"componentes": [{"tipo": "area", "duracao_s": 3.0, "dano_por_s": 5.0, "nome_estado": "molhado"}]})
	var longa := Validador.validar_ficha({"componentes": [{"tipo": "area", "duracao_s": 8.0, "dano_por_s": 5.0, "nome_estado": "molhado"}]})
	_afirmar("área custa mana", Validador.calcular_custo_mana(sem_dano) > 0.0)
	_afirmar("área com dano custa mais", Validador.calcular_custo_mana(com_dano) > Validador.calcular_custo_mana(sem_dano))
	_afirmar("área mais longa custa mais", Validador.calcular_custo_mana(longa) > Validador.calcular_custo_mana(com_dano))


func _criar_area_de_teste(pos: Vector3, campos: Dictionary, dono: Node = null) -> Node:
	var componente: Dictionary = Validador.validar_ficha({"componentes": [campos.merged({"tipo": "area"})]})["componentes"][0]
	return Executor.criar_area(componente, pos, dono, [], self)


func _galinha_em(pos: Vector3) -> Node:
	var galinha: Node = load("res://cenas/inimigos/galinha_zumbi.tscn").instantiate()
	add_child(galinha)
	galinha.global_position = pos
	return galinha


func _chao_em(pos: Vector3) -> StaticBody3D:
	var chao := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	(forma.shape as BoxShape3D).size = Vector3(20, 0.2, 20)
	chao.add_child(forma)
	add_child(chao)
	chao.global_position = pos + Vector3.DOWN * 0.1
	return chao


func _testar_area_machuca_so_quem_esta_dentro() -> void:
	# Com chão: sem ele a galinha cai uns 8 m em 1 s e sai da altura da área.
	var chao := _chao_em(Vector3(100, 0, 0))
	var dentro := _galinha_em(Vector3(100, 0, 0))
	var fora := _galinha_em(Vector3(105, 0, 0))
	await get_tree().process_frame
	var area := _criar_area_de_teste(Vector3(100, 0, 0), {"raio_m": 2.0, "duracao_s": 5.0, "dano_por_s": 4.0})
	await get_tree().physics_frame
	await get_tree().physics_frame
	_afirmar("área machuca quem está dentro logo no primeiro tick", dentro._vida_atual < dentro.vida)
	_afirmar("área não machuca quem está fora", fora._vida_atual == fora.vida)
	var depois_do_primeiro: float = dentro._vida_atual
	await get_tree().create_timer(1.15).timeout
	_afirmar("área continua machucando a cada segundo", dentro._vida_atual < depois_do_primeiro)
	for n in [dentro, fora, area, chao]:
		n.queue_free()


func _testar_area_nao_machuca_quem_criou() -> void:
	var mago: Node = load("res://cenas/mago.tscn").instantiate()
	add_child(mago)
	mago.global_position = Vector3(110, 0, 0)
	await get_tree().process_frame
	var area := _criar_area_de_teste(Vector3(110, 0, 0), {"raio_m": 3.0, "duracao_s": 3.0, "dano_por_s": 8.0}, mago)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_afirmar("área não machuca quem a criou", mago.vida_atual == mago.vida_maxima)
	mago.queue_free()
	area.queue_free()


func _testar_area_aplica_estado_em_quem_esta_dentro() -> void:
	var galinha := _galinha_em(Vector3(120, 0, 0))
	await get_tree().process_frame
	var area := _criar_area_de_teste(Vector3(120, 0, 0), {"raio_m": 2.0, "duracao_s": 3.0, "nome_estado": "molhado", "material": "agua"})
	await get_tree().physics_frame
	await get_tree().physics_frame
	_afirmar("área de chuva molha quem está dentro", galinha.estados.esta_molhado())
	galinha.queue_free()
	area.queue_free()


func _testar_area_de_fogo_acende_barril() -> void:
	var barril: Node = load("res://cenas/barril_inflamavel.tscn").instantiate()
	add_child(barril)
	barril.global_position = Vector3(130, 0, 0)
	await get_tree().process_frame
	var area := _criar_area_de_teste(Vector3(130.5, 0, 0), {"raio_m": 2.0, "duracao_s": 3.0, "dano_por_s": 2.0, "material": "fogo"})
	await get_tree().physics_frame
	await get_tree().physics_frame
	_afirmar("área de fogo acende barril dentro dela (etiquetas)", barril._queimando)
	area.queue_free()
	await get_tree().process_frame
	if is_instance_valid(barril):
		barril.queue_free()


func _testar_area_some_depois_da_duracao() -> void:
	var area := _criar_area_de_teste(Vector3(140, 0, 0), {"duracao_s": 0.2, "dano_por_s": 1.0})
	await get_tree().create_timer(0.5).timeout
	_afirmar("área some sozinha depois da duração", not is_instance_valid(area))


## Proposta técnica, seção 5: no máximo 3 magias ativas por jogador.
func _testar_limite_de_tres_areas_por_jogador() -> void:
	var dono := Node3D.new()
	var outro := Node3D.new()
	add_child(dono)
	add_child(outro)
	var criadas: Array = []
	for i in 5:
		criadas.append(_criar_area_de_teste(Vector3(150 + i * 10, 0, 0), {"duracao_s": 5.0, "dano_por_s": 1.0}, dono))
	var do_outro := _criar_area_de_teste(Vector3(150, 0, 20), {"duracao_s": 5.0, "dano_por_s": 1.0}, outro)
	var validas := criadas.filter(func(a): return a != null)
	_afirmar("no máximo 3 áreas ativas por jogador", validas.size() == Host.LIMITE_MAGIAS_ATIVAS_POR_DONO)
	_afirmar("o limite é por jogador: outro jogador ainda pode criar", do_outro != null)
	for a in validas + [do_outro]:
		a.queue_free()
	dono.queue_free()
	outro.queue_free()
	await get_tree().process_frame


func _testar_projetil_deixa_area_no_chao() -> void:
	var chao := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	forma.shape = BoxShape3D.new()
	(forma.shape as BoxShape3D).size = Vector3(10, 0.2, 10)
	chao.add_child(forma)
	add_child(chao)
	chao.global_position = Vector3(200, -0.1, 0)

	var projetil: Node = load("res://cenas/magias/projetil.tscn").instantiate()
	add_child(projetil)
	projetil.global_position = Vector3(200, 1.5, 0)
	projetil.ao_impactar = Validador.validar_ficha({"componentes": [{"tipo": "projetil", "ao_impactar": [{"tipo": "area", "duracao_s": 2.0, "dano_por_s": 1.0}]}]})["componentes"][0]["ao_impactar"]
	await get_tree().physics_frame
	projetil._explodir(null)

	var areas := get_tree().get_nodes_in_group("area_persistente").filter(func(a): return a.global_position.x > 199.0 and a.global_position.x < 201.0)
	_afirmar("projétil com área deixa uma área no impacto", areas.size() == 1)
	if areas.size() == 1:
		_afirmar("a área nasce no chão, não onde o projétil bateu no ar", absf(areas[0].global_position.y) < 0.05)
		areas[0].queue_free()
	chao.queue_free()


func _testar_area_no_topo_da_ficha_nasce_aos_pes_do_mago() -> void:
	var mago: Node = load("res://cenas/mago.tscn").instantiate()
	add_child(mago)
	mago.global_position = Vector3(220, 0, 0)
	await get_tree().process_frame
	Executor.executar_ficha(FichasPadrao.nuvem_de_chuva(), Vector3(220, 1.6, -1), Vector3.FORWARD, mago, self)
	var areas := get_tree().get_nodes_in_group("area_persistente").filter(func(a): return a.dono == mago)
	# O mago já caiu uns milímetros (sem chão na cena de teste): tolerância.
	_afirmar("área no topo da ficha nasce aos pés de quem conjurou", areas.size() == 1 and areas[0].global_position.distance_to(mago.global_position) < 0.05)
	for a in areas:
		a.queue_free()
	mago.queue_free()


func _testar_ficha_so_com_area_sem_efeito_conta_como_nao_entendida() -> void:
	var mago: Node = load("res://cenas/mago.tscn").instantiate()
	add_child(mago)
	_afirmar(
		"área sem dano e sem estado conta como sem componentes",
		mago._ficha_sem_componentes({"componentes": [{"tipo": "area", "duracao_s": 5.0}]})
	)
	_afirmar(
		"área com estado conta como magia de verdade",
		not mago._ficha_sem_componentes({"componentes": [{"tipo": "area", "duracao_s": 5.0, "nome_estado": "molhado"}]})
	)
	mago.queue_free()


func _testar_interpretador_reconhece_lava_e_chuva() -> void:
	_afirmar("interpretador reconhece \"lava\"", Interpretador.interpretar("uma poça de lava").get("nome") == "Poça de Lava")
	_afirmar("interpretador reconhece \"chuva\"", Interpretador.interpretar("uma nuvem de chuva").get("nome") == "Nuvem de Chuva")


## Parede e teleporte curto (proposta técnica, seção 3): fecham a primeira
## leva de componentes ("cego" veio logo depois).
func _testar_validador_corta_parede_e_teleporte() -> void:
	var fichas: Array = Validador.validar_ficha({"componentes": [
		{"tipo": "parede", "largura_m": 99.0, "altura_m": 99.0, "duracao_s": 99.0, "distancia_m": 99.0, "material": "queijo"},
		{"tipo": "teleporte", "distancia_m": 999.0}
	]})["componentes"]
	_afirmar("largura da parede cortada", fichas[0]["largura_m"] == Validador.LARGURA_PAREDE_MAXIMA)
	_afirmar("altura da parede cortada", fichas[0]["altura_m"] == Validador.ALTURA_PAREDE_MAXIMA)
	_afirmar("distância da parede cortada", fichas[0]["distancia_m"] == Validador.DISTANCIA_PAREDE_MAXIMA)
	_afirmar("material da parede cai na lista fechada", fichas[0]["material"] in Validador.MATERIAIS_VALIDOS)
	_afirmar("distância do teleporte cortada", fichas[1]["distancia_m"] == Validador.DISTANCIA_TELEPORTE_MAXIMA)


func _testar_validador_calcula_custo_de_parede_e_teleporte() -> void:
	var pequena := Validador.validar_ficha({"componentes": [{"tipo": "parede", "largura_m": 1.0, "altura_m": 1.0, "duracao_s": 3.0}]})
	var grande := Validador.validar_ficha({"componentes": [{"tipo": "parede", "largura_m": 4.0, "altura_m": 3.0, "duracao_s": 3.0}]})
	var perto := Validador.validar_ficha({"componentes": [{"tipo": "teleporte", "distancia_m": 2.0}]})
	var longe := Validador.validar_ficha({"componentes": [{"tipo": "teleporte", "distancia_m": 8.0}]})
	_afirmar("parede maior custa mais", Validador.calcular_custo_mana(grande) > Validador.calcular_custo_mana(pequena))
	_afirmar("teleporte mais longe custa mais", Validador.calcular_custo_mana(longe) > Validador.calcular_custo_mana(perto))


func _mago_em(pos: Vector3) -> Node:
	var mago: Node = load("res://cenas/mago.tscn").instantiate()
	add_child(mago)
	mago.global_position = pos
	return mago


func _testar_parede_nasce_na_frente_do_mago() -> void:
	var chao := _chao_em(Vector3(300, 0, 0))
	var mago := _mago_em(Vector3(300, 0, 0))
	await get_tree().physics_frame
	Executor.executar_ficha(FichasPadrao.muro_de_pedra(), Vector3(300, 1.6, -0.5), Vector3.FORWARD, mago, self)
	var paredes := get_children().filter(func(n): return n.get_script() == load("res://scripts/magia/parede.gd"))
	_afirmar("muro cria uma parede", paredes.size() == 1)
	if paredes.size() == 1:
		var parede: Node3D = paredes[0]
		_afirmar("parede nasce 3 m à frente do mago", parede.global_position.distance_to(Vector3(300, 0, -3)) < 0.1)
		var largura_no_mundo := parede.global_transform.basis.x.normalized()
		_afirmar("parede fica atravessada na frente do mago, não de lado", absf(largura_no_mundo.dot(Vector3.FORWARD)) < 0.01)
		parede.queue_free()
	mago.queue_free()
	chao.queue_free()


func _testar_parede_segura_projetil() -> void:
	var parede: Node = load("res://cenas/magias/parede.tscn").instantiate()
	add_child(parede)
	parede.global_position = Vector3(320, 0, -3)
	var projetil: Node = load("res://cenas/magias/projetil.tscn").instantiate()
	add_child(projetil)
	projetil.global_position = Vector3(320, 1, 0)
	projetil.look_at(Vector3(320, 1, -10), Vector3.UP)
	projetil.velocidade = 20.0
	await get_tree().create_timer(0.5).timeout
	var passou: bool = is_instance_valid(projetil) and projetil.global_position.z < -3.5
	_afirmar("parede segura o projétil (ele não passa para o outro lado)", not passou)
	if is_instance_valid(projetil):
		projetil.queue_free()
	parede.queue_free()


func _testar_parede_some_depois_da_duracao() -> void:
	var parede: Node = load("res://cenas/magias/parede.tscn").instantiate()
	parede.duracao_s = 0.2
	add_child(parede)
	await get_tree().create_timer(0.5).timeout
	_afirmar("parede some sozinha depois da duração", not is_instance_valid(parede))


## As duas ficam no mundo e têm dono: dividem o limite de 3 da seção 5.
func _testar_parede_e_area_dividem_o_limite_de_magias_ativas() -> void:
	var mago := _mago_em(Vector3(340, 0, 0))
	await get_tree().process_frame
	var a1 := _criar_area_de_teste(Vector3(340, 0, 5), {"duracao_s": 5.0, "dano_por_s": 1.0}, mago)
	var a2 := _criar_area_de_teste(Vector3(340, 0, 10), {"duracao_s": 5.0, "dano_por_s": 1.0}, mago)
	Executor.executar_ficha(FichasPadrao.muro_de_pedra(), Vector3(340, 1.6, 0), Vector3.FORWARD, mago, self)
	var a3 := _criar_area_de_teste(Vector3(340, 0, 15), {"duracao_s": 5.0, "dano_por_s": 1.0}, mago)
	_afirmar("duas áreas e uma parede usam as 3 vagas; a quarta magia não sai", a1 != null and a2 != null and a3 == null)
	for m in Host.magias_ativas.duplicate():
		if is_instance_valid(m) and m.dono == mago:
			m.queue_free()
	mago.queue_free()
	await get_tree().process_frame


func _testar_teleporte_leva_o_mago_para_frente() -> void:
	var chao := _chao_em(Vector3(360, 0, 0))
	var mago := _mago_em(Vector3(360, 0, 0))
	await get_tree().physics_frame
	Executor.executar_ficha(FichasPadrao.salto_arcano(), Vector3.ZERO, Vector3.FORWARD, mago, self)
	_afirmar("teleporte leva o mago 6 m para a frente, no chão", mago.global_position.distance_to(Vector3(360, 0, -6)) < 0.1)
	mago.queue_free()
	chao.queue_free()


func _testar_teleporte_para_antes_da_parede() -> void:
	var chao := _chao_em(Vector3(380, 0, 0))
	var mago := _mago_em(Vector3(380, 0, 0))
	var parede: Node = load("res://cenas/magias/parede.tscn").instantiate()
	add_child(parede)
	parede.global_position = Vector3(380, 0, -3)
	await get_tree().physics_frame
	Executor.executar_ficha(FichasPadrao.salto_arcano(), Vector3.ZERO, Vector3.FORWARD, mago, self)
	_afirmar("teleporte para antes da parede, sem atravessar", mago.global_position.z > -3.0 + 0.2)
	_afirmar("teleporte ainda anda até perto da parede", mago.global_position.z < -1.5)
	mago.queue_free()
	parede.queue_free()
	chao.queue_free()


func _testar_teleporte_nao_vira_voo() -> void:
	var chao := _chao_em(Vector3(400, 0, 0))
	var mago := _mago_em(Vector3(400, 0, 0))
	await get_tree().physics_frame
	Executor.executar_ficha(FichasPadrao.salto_arcano(), Vector3.ZERO, Vector3(0, 1, -1).normalized(), mago, self)
	_afirmar("olhar para cima no teleporte não faz o mago voar", absf(mago.global_position.y) < 0.1)
	mago.queue_free()
	chao.queue_free()


func _testar_parede_e_teleporte_contam_como_magia_de_verdade() -> void:
	var mago: Node = load("res://cenas/mago.tscn").instantiate()
	add_child(mago)
	_afirmar("parede com duração conta como magia", not mago._ficha_sem_componentes(FichasPadrao.muro_de_pedra()))
	_afirmar("teleporte com distância conta como magia", not mago._ficha_sem_componentes(FichasPadrao.salto_arcano()))
	_afirmar("teleporte de distância zero não conta", mago._ficha_sem_componentes({"componentes": [{"tipo": "teleporte", "distancia_m": 0.0}]}))
	mago.queue_free()


func _testar_interpretador_reconhece_muro_e_teleporte() -> void:
	_afirmar("interpretador reconhece \"muro\"", Interpretador.interpretar("um muro de pedra").get("nome") == "Muro de Pedra")
	_afirmar("interpretador reconhece \"teleporte\"", Interpretador.interpretar("quero me teleportar").get("nome") == "Salto Arcano")


## Revisão de segurança: a IA pode mandar fichas absurdas de propósito ou
## por erro. Não quebrava, mas o validador agora corta antes.
func _testar_validador_descarta_projetil_dentro_de_projetil() -> void:
	var ficha := {"tipo": "explosao", "dano": 5.0}
	for i in 40:
		ficha = {"tipo": "projetil", "ao_impactar": [ficha]}
	var projetil: Dictionary = Validador.validar_ficha({"componentes": [ficha]})["componentes"][0]
	_afirmar("projétil dentro de projétil é descartado no impacto", (projetil["ao_impactar"] as Array).is_empty())
	var normal: Dictionary = Validador.validar_ficha(FichasPadrao.bola_de_fogo())["componentes"][0]
	_afirmar("explosão no impacto continua valendo", normal["ao_impactar"].size() == 1)


func _testar_validador_limita_tamanho_das_listas() -> void:
	var muitos: Array = []
	var efeitos: Array = []
	for i in 50:
		muitos.append({"tipo": "cura", "quantidade": 1.0})
		efeitos.append({"tipo": "explosao", "dano": 1.0})
	var v := Validador.validar_ficha({"componentes": muitos + [{"tipo": "projetil", "ao_impactar": efeitos}]})
	_afirmar("ficha com 51 componentes fica com no máximo 8", v["componentes"].size() == Validador.MAXIMO_COMPONENTES)
	var p: Dictionary = Validador.validar_ficha({"componentes": [{"tipo": "projetil", "ao_impactar": efeitos}]})["componentes"][0]
	_afirmar("projétil com 50 efeitos fica com no máximo 4", p["ao_impactar"].size() == Validador.MAXIMO_EFEITOS_DE_IMPACTO)


## Estado "cego": o último que faltava da proposta técnica (seção 3).
func _testar_galinha_cega_nao_persegue_nem_bica() -> void:
	var chao := _chao_em(Vector3(420, 0, 0))
	var mago := _mago_em(Vector3(420, 0, 0))
	var galinha := _galinha_em(Vector3(421, 0, 0))
	# Cegar antes do primeiro quadro: nascendo colada no mago, ela bicaria já.
	galinha.aplicar_estado("cego", 3.0)
	await get_tree().physics_frame
	var pos_inicial: Vector3 = galinha.global_position
	await get_tree().create_timer(1.3).timeout
	_afirmar("galinha cega não persegue o mago", galinha.global_position.distance_to(pos_inicial) < 0.05)
	_afirmar("galinha cega não bica nem com o mago colado nela", mago.vida_atual == mago.vida_maxima)
	for n in [mago, galinha, chao]:
		n.queue_free()


func _testar_mago_cego_ve_a_tela_escura() -> void:
	var mago := _mago_em(Vector3(440, 0, 0))
	var hud: Node = load("res://cenas/hud.tscn").instantiate()
	add_child(hud)
	await get_tree().process_frame
	hud.configurar(mago)
	var tela: ColorRect = hud.get_node("Cegueira")
	_afirmar("tela começa normal", not tela.visible)
	mago.aplicar_estado("cego", 0.1)
	_afirmar("mago cego vê a tela escura", tela.visible)
	await get_tree().create_timer(0.4).timeout
	_afirmar("a tela volta ao normal quando a cegueira passa", not tela.visible)
	mago.queue_free()
	hud.queue_free()


func _testar_teleporte_faz_um_puf_na_saida_e_na_chegada() -> void:
	var mago := _mago_em(Vector3(460, 0, 0))
	await get_tree().process_frame
	var script_efeito := load("res://scripts/magia/efeito_explosao.gd")
	var antes := get_children().filter(func(n): return n.get_script() == script_efeito).size()
	Executor.executar_ficha(FichasPadrao.salto_arcano(), Vector3.ZERO, Vector3.FORWARD, mago, self)
	var depois := get_children().filter(func(n): return n.get_script() == script_efeito).size()
	_afirmar("teleporte deixa um efeito visual na saída e outro na chegada", depois - antes == 2)
	mago.queue_free()


func _testar_interpretador_reconhece_cegueira() -> void:
	_afirmar("interpretador reconhece \"cegar\"", Interpretador.interpretar("um pó que cega o inimigo").get("nome") == "Pó Ofuscante")


func _testar_teleporte_da_clarao_na_tela_do_mago() -> void:
	var mago := _mago_em(Vector3(480, 0, 0))
	var hud: Node = load("res://cenas/hud.tscn").instantiate()
	add_child(hud)
	await get_tree().process_frame
	hud.configurar(mago)
	var clarao: ColorRect = hud.get_node("Clarao")
	_afirmar("sem teleporte, sem clarão", clarao.color.a == 0.0)
	Executor.executar_ficha(FichasPadrao.salto_arcano(), Vector3.ZERO, Vector3.FORWARD, mago, self)
	_afirmar("teleporte dá um clarão na tela de quem se teleportou", clarao.color.a > 0.5)
	await get_tree().create_timer(0.5).timeout
	_afirmar("o clarão some sozinho", clarao.color.a < 0.01)
	mago.queue_free()
	hud.queue_free()


## A IA escreve em português: pode mandar "explosão", "Área", "Água".
## Antes isso virava "não entendi" sem ninguém perceber (custo 0).
func _testar_validador_aceita_nomes_com_acento_e_maiuscula() -> void:
	var v := Validador.validar_ficha({"componentes": [
		{"tipo": "Projétil", "material": "Água", "forma": " Cubo ", "ao_impactar": [{"tipo": "explosão", "dano": 10}]},
		{"tipo": "Área", "duracao_s": 3, "nome_estado": "Molhado"},
		{"tipo": "invocação", "corpo": "Quadrúpede", "vida": 10, "duracao_s": 3}
	]})
	var comps: Array = v["componentes"]
	_afirmar("\"Projétil\" vira projetil", comps[0]["tipo"] == "projetil")
	_afirmar("\"Água\" vira o material agua", comps[0]["material"] == "agua")
	_afirmar("\" Cubo \" vira a forma cubo", comps[0]["forma"] == "cubo")
	_afirmar("\"explosão\" no impacto vira explosao e continua valendo", comps[0]["ao_impactar"].size() == 1 and comps[0]["ao_impactar"][0]["tipo"] == "explosao")
	_afirmar("\"Área\" com \"Molhado\" vira área de molhar", comps[1]["tipo"] == "area" and comps[1]["nome_estado"] == "molhado")
	_afirmar("\"Quadrúpede\" vira o corpo quadrupede", comps[2]["corpo"] == "quadrupede")
	_afirmar("ficha com acentos tem custo de mana de verdade", Validador.calcular_custo_mana(v) > 0.0)
