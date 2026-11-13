class_name MoveisDaForja
extends RefCounted
## Móveis e miudezas do posto avançado da forja (etapa 3 da caverna, ADR-049),
## pela folha `docs/referencias/lote02/lote02_09_caverna_forja.png`: estantes
## com tábuas de runa, mesa do grimório, mesa de trabalho, baú, barris,
## caixotes, estandartes, pilhas de livros, velas, lanternas penduradas e um
## mirante de madeira na beira do abismo.
##
## Pedido do Vitor (13/11/2026): "pode encher de detalhes, mais do que
## acharia recomendado; é o lugar que dá nome ao jogo". Tudo é junto em duas
## malhas (madeira e pedra numa, coisas acesas na outra), então muito
## detalhe custa pouco para a placa de vídeo: o que pesa é quantidade de
## malhas soltas e de luzes, não de triângulos.
##
## Cada conjunto ("estação") é montado num referencial próprio: X corre ao
## longo da parede, Y é para cima e Z aponta para o centro da câmara.

const MADEIRA := Color(0.6, 0.43, 0.29)
const MADEIRA_ESCURA := Color(0.44, 0.31, 0.22)
const FERRO := Color(0.2, 0.17, 0.21)
const OURO := Color(0.95, 0.72, 0.25)
const PANO := Color(0.42, 0.24, 0.62)
const PAPEL := Color(0.9, 0.84, 0.68)
const CERA := Color(0.93, 0.88, 0.74)
const CHAMA := Color(1.0, 0.76, 0.3)
const PEDRA_DE_RUNA := Color(0.34, 0.3, 0.4)
const CAPAS := [Color(0.62, 0.2, 0.2), Color(0.2, 0.36, 0.62), Color(0.24, 0.5, 0.3), Color(0.55, 0.36, 0.7), Color(0.75, 0.55, 0.2), Color(0.3, 0.22, 0.2)]
const ALTURA_DO_ANDAIME := 4.9
const POCOES := [Color(1.0, 0.35, 0.3), Color(0.35, 0.7, 1.0), Color(0.45, 0.95, 0.5), Color(0.8, 0.5, 1.0)]

var _st: SurfaceTool        # madeira, pedra, ferro, pano (material toon)
var _aceso: SurfaceTool     # chamas, runas, poções, cristais (cor acesa)
var _rng := RandomNumberGenerator.new()
var _colisores: StaticBody3D
var _centro: Vector3
var _cores_runa: Array = []
var livros := 0
var velas := 0
## Lugares de pouso em cima das estantes, para os livros voadores:
## cada um é {"pos": ponto no espaço da caverna, "estante": número da estante}.
var pousos: Array = []
var _estantes := 0


## Monta tudo e pendura as duas malhas e as luzes em `dono`.
static func montar(dono: Node3D, centro: Vector3, raio_camara: float, altura_do_teto: Callable, material: Material, colisores: StaticBody3D) -> MoveisDaForja:
	var m := MoveisDaForja.new()
	m._st = GeometriaLowPoly.nova()
	m._aceso = GeometriaLowPoly.nova()
	m._rng.seed = 2026
	m._colisores = colisores
	m._centro = centro
	m._cores_runa = RunaColetavel.CORES.values()
	var r := raio_camara - 5.0

	# Os móveis ficam em dois blocos encostados na parede, cada um dentro de
	# um andaime de madeira de dois andares com escada e passarela (folha).
	var parede := raio_camara - 3.3
	# Bloco esquerdo de quem entra (+Z): estante grande, baú e barris embaixo;
	# estante pequena e caixotes em cima; mesa do grimório na frente.
	var esq := m._estacao(deg_to_rad(96.0), parede)
	m._andaime(esq, 15.0, 3.6, ALTURA_DO_ANDAIME, 1.0)
	m._estante(m._em(esq, -3.4, 0.0, -0.9), 6.4, 3, 9)
	m._bau_e_barris(m._em(esq, 4.3, 0.0, 0.2))
	m._estante(m._em(esq, -3.0, ALTURA_DO_ANDAIME + 0.1, -1.0), 3.4, 2, 4)
	m._caixote(m._em(esq, 2.0, ALTURA_DO_ANDAIME + 0.1, -0.6), Vector3.ZERO, 1.0, 0.3)
	m._barril(m._em(esq, 3.4, ALTURA_DO_ANDAIME + 0.1, -0.8), Vector3.ZERO, 1.1)
	m._pilha_de_livros(m._em(esq, 2.0, ALTURA_DO_ANDAIME + 1.1, -0.6), Vector3.ZERO, 4)
	m._velas(m._em(esq, 0.4, ALTURA_DO_ANDAIME + 0.1, -1.0), Vector3.ZERO, 5)
	m._estandarte(m._em(esq, -5.6, 0.0, 1.85), ALTURA_DO_ANDAIME - 0.25, 1.3)
	m._estandarte(m._em(esq, 1.9, 0.0, 1.85), ALTURA_DO_ANDAIME - 0.25, 1.3)
	m._mesa_do_grimorio(m._em(esq, -3.0, 0.0, 5.2))
	# Bloco direito (-Z): estante de poções e caixotes embaixo; tábuas de runa
	# e barris em cima; mesa de trabalho na frente.
	var dir := m._estacao(deg_to_rad(-92.0), parede)
	m._andaime(dir, 15.0, 3.6, ALTURA_DO_ANDAIME, -1.0)
	m._estante(m._em(dir, 3.2, 0.0, -0.9), 5.0, 3, 5, true)
	m._caixotes(m._em(dir, -4.0, 0.0, 0.0))
	m._estante(m._em(dir, 2.8, ALTURA_DO_ANDAIME + 0.1, -1.0), 3.4, 2, 6)
	m._barril(m._em(dir, -2.2, ALTURA_DO_ANDAIME + 0.1, -0.8), Vector3.ZERO, 1.15)
	m._barril(m._em(dir, -3.3, ALTURA_DO_ANDAIME + 0.1, -0.5), Vector3.ZERO, 1.0)
	m._caixote(m._em(dir, -0.6, ALTURA_DO_ANDAIME + 0.1, -0.7), Vector3.ZERO, 0.9, -0.2)
	m._velas(m._em(dir, 0.6, ALTURA_DO_ANDAIME + 0.1, -1.0), Vector3.ZERO, 4)
	m._estandarte(m._em(dir, 5.6, 0.0, 1.85), ALTURA_DO_ANDAIME - 0.25, 1.3)
	m._estandarte(m._em(dir, -1.9, 0.0, 1.85), ALTURA_DO_ANDAIME - 0.25, 1.3)
	m._mesa_de_trabalho(m._em(dir, 3.0, 0.0, 5.4))
	# Mirante de madeira na beira do abismo (as passarelas da folha, em pequeno).
	m._mirante(m._estacao(deg_to_rad(152.0), raio_camara - 4.6))
	# Miudezas espalhadas: velas no chão, pilhas de livros, lanternas penduradas.
	for grau: float in [20.0, 38.0, 70.0, 88.0, 112.0, 134.0, -20.0, -36.0, -66.0, -92.0, -110.0, -134.0, 170.0, -168.0]:
		var t := m._estacao(deg_to_rad(grau + m._rng.randf_range(-3.0, 3.0)), r - m._rng.randf_range(1.6, 3.4))
		m._velas(t, Vector3.ZERO, 3 + m._rng.randi() % 3)
	for grau: float in [46.0, 62.0, 92.0, 108.0, -50.0, -70.0, -88.0, -114.0, -128.0, 128.0]:
		var t := m._estacao(deg_to_rad(grau), r - m._rng.randf_range(2.6, 4.6))
		m._pilha_de_livros(t, Vector3(m._rng.randf_range(-0.8, 0.8), 0, 0), 3 + m._rng.randi() % 4)
	for grau: float in [70.0, 122.0, 50.0, -62.0, -122.0, -40.0]:
		var a := deg_to_rad(grau)
		var pe := centro + Vector3(cos(a), 0, sin(a)) * (r - 1.5)
		var teto: float = altura_do_teto.call(r - 1.5)
		m._lanterna_pendurada(pe + Vector3.UP * teto, teto - m._rng.randf_range(4.2, 5.4))

	var moveis := MeshInstance3D.new()
	moveis.name = "MoveisDaForja"
	moveis.mesh = GeometriaLowPoly.finalizar(m._st)
	moveis.material_override = material
	dono.add_child(moveis)
	var acesos := MeshInstance3D.new()
	acesos.name = "MoveisAcesos"
	acesos.mesh = GeometriaLowPoly.finalizar(m._aceso)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	acesos.material_override = mat
	acesos.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dono.add_child(acesos)
	# Quatro poças de luz quente, uma por canto do posto (as velas e lanternas
	# em si são só cor acesa).
	for k in 4:
		var a := deg_to_rad([84.0, 108.0, -80.0, -104.0][k])
		var luz := OmniLight3D.new()
		luz.name = "LuzDosMoveis%d" % k
		luz.light_color = Color(1.0, 0.6, 0.24)
		luz.light_energy = 5.0
		luz.omni_range = 14.0
		luz.omni_attenuation = 0.8
		luz.position = centro + Vector3(cos(a), 0, sin(a)) * (r - 2.6) + Vector3.UP * 3.0
		dono.add_child(luz)
	return m


# --- Ferramentas -------------------------------------------------------------

## Referencial de uma estação: no ângulo e raio dados, olhando para o centro.
func _estacao(angulo: float, raio: float) -> Transform3D:
	var fora := Vector3(cos(angulo), 0, sin(angulo))
	return Transform3D(Basis(Vector3(-sin(angulo), 0, cos(angulo)), Vector3.UP, -fora), _centro + fora * raio)


## Um ponto dentro de uma estação vira a origem de outra (mesma orientação).
func _em(t: Transform3D, x: float, y: float, z: float) -> Transform3D:
	return t * Transform3D(Basis(), Vector3(x, y, z))


## Rampa de degraus com colisão: sobe de frente, do centro da câmara para a
## parede. `z_topo` é onde ela chega em cima; o pé fica `corrida` adiante.
func _rampa(t: Transform3D, x: float, z_topo: float, corrida: float, alto: float, largura := 2.0) -> void:
	var comprimento := sqrt(alto * alto + corrida * corrida)
	var plano := Transform3D(Basis(Vector3.RIGHT, atan2(alto, corrida)), Vector3(x, alto / 2.0 + 0.02, z_topo + corrida / 2.0))
	_colidir(t * plano, Vector3(0, -0.15, 0), Vector3(largura, 0.3, comprimento))
	var degraus := int(alto / 0.26)
	for k in degraus:
		var f := (k + 0.5) / degraus
		_caixa(t, Vector3(x, alto * (1.0 - f) - 0.03, z_topo + corrida * f), Vector3(largura, 0.12, corrida / degraus + 0.06), MADEIRA if k % 2 else MADEIRA * 1.12)
	for dx: float in [-1.0, 1.0]:
		_caixa(t * plano, Vector3(dx * (largura / 2.0 + 0.05), -0.2, 0), Vector3(0.14, 0.34, comprimento), MADEIRA_ESCURA)
		# corrimão da escada
		_caixa(t * plano, Vector3(dx * (largura / 2.0 + 0.05), 0.95, 0), Vector3(0.08, 0.08, comprimento), MADEIRA)
		for q in 4:
			_caixa(t * plano, Vector3(dx * (largura / 2.0 + 0.05), 0.4, -comprimento / 2.0 + 0.4 + q * (comprimento - 0.8) / 3.0), Vector3(0.1, 1.1, 0.1), MADEIRA_ESCURA)


func _caixa(t: Transform3D, pos: Vector3, tam: Vector3, cor: Color, giro := 0.0, tomba := 0.0, aceso := false) -> void:
	var base := Basis(Vector3.UP, giro) * Basis(Vector3.RIGHT, tomba)
	GeometriaLowPoly.anexar(_aceso if aceso else _st, GeometriaLowPoly.cubo(tam), t * Transform3D(base, pos), GeometriaLowPoly.variar(cor, _rng, 0.0 if aceso else 0.09))


func _cilindro(t: Transform3D, pos: Vector3, raio_baixo: float, raio_cima: float, altura: float, lados: int, cor: Color, base := Basis(), aceso := false) -> void:
	GeometriaLowPoly.anexar(_aceso if aceso else _st, GeometriaLowPoly.cilindro(raio_baixo, raio_cima, altura, lados),
		t * Transform3D(base, pos), GeometriaLowPoly.variar(cor, _rng, 0.0 if aceso else 0.09))


func _colidir(t: Transform3D, pos: Vector3, tam: Vector3) -> void:
	var forma := BoxShape3D.new()
	forma.size = tam
	var col := CollisionShape3D.new()
	col.shape = forma
	col.transform = t * Transform3D(Basis(), pos)
	_colisores.add_child(col)


# --- Miudezas ----------------------------------------------------------------

## Livro fechado deitado: capa e miolo de páginas (24 triângulos).
func _livro(t: Transform3D, pos: Vector3, giro: float, escala := 1.0) -> void:
	var capa: Color = CAPAS[_rng.randi() % CAPAS.size()]
	_caixa(t, pos + Vector3.UP * 0.045 * escala, Vector3(0.36, 0.09, 0.26) * escala, capa, giro)
	_caixa(t, pos + Vector3.UP * 0.045 * escala + Vector3(0, 0, 0.012).rotated(Vector3.UP, giro), Vector3(0.33, 0.062, 0.265) * escala, PAPEL, giro)
	livros += 1


func _pilha_de_livros(t: Transform3D, pos: Vector3, quantos: int) -> void:
	for k in quantos:
		_livro(t, pos + Vector3(_rng.randf_range(-0.03, 0.03), 0.09 * k, _rng.randf_range(-0.03, 0.03)), _rng.randf_range(-0.5, 0.5))


## Livros em pé numa prateleira, lombada para a frente, um ou outro tombado.
func _fileira_de_livros(t: Transform3D, pos: Vector3, largura: float) -> void:
	var x := -largura / 2.0
	while x < largura / 2.0 - 0.1:
		var grossura := _rng.randf_range(0.06, 0.12)
		var altura := _rng.randf_range(0.3, 0.42)
		var tomba := 0.28 if _rng.randf() < 0.12 else 0.0
		var capa: Color = CAPAS[_rng.randi() % CAPAS.size()]
		GeometriaLowPoly.anexar(_st, GeometriaLowPoly.cubo(Vector3(grossura, altura, 0.26)),
			t * Transform3D(Basis(Vector3.BACK, tomba), pos + Vector3(x + grossura / 2.0, altura / 2.0, 0)), capa)
		# filete dourado na lombada
		GeometriaLowPoly.anexar(_st, GeometriaLowPoly.cubo(Vector3(grossura * 0.9, 0.03, 0.01)),
			t * Transform3D(Basis(Vector3.BACK, tomba), pos + Vector3(x + grossura / 2.0, altura * 0.75, 0.133)), OURO)
		livros += 1
		x += grossura + 0.012 + tomba * 0.3


func _vela(t: Transform3D, pos: Vector3, altura: float) -> void:
	_cilindro(t, pos + Vector3.UP * altura / 2.0, 0.045, 0.04, altura, 5, CERA)
	_cilindro(t, pos + Vector3.UP * (altura + 0.06), 0.03, 0.0, 0.11, 4, CHAMA, Basis(), true)
	velas += 1


## Grupo de velas num pratinho de cera derretida.
func _velas(t: Transform3D, pos: Vector3, quantas: int) -> void:
	_cilindro(t, pos + Vector3.UP * 0.015, 0.26, 0.2, 0.03, 7, CERA * 0.85)
	for k in quantas:
		var a := TAU * k / quantas + _rng.randf_range(-0.3, 0.3)
		_vela(t, pos + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(0.04, 0.16), _rng.randf_range(0.12, 0.42))


func _pergaminho(t: Transform3D, pos: Vector3, giro: float) -> void:
	var deitado := Basis(Vector3.UP, giro) * Basis(Vector3.BACK, PI / 2.0)
	_cilindro(t, pos + Vector3.UP * 0.05, 0.05, 0.05, 0.46, 6, PAPEL, deitado)
	_cilindro(t, pos + Vector3.UP * 0.05, 0.056, 0.056, 0.07, 6, CAPAS[0], deitado)


func _pocao(t: Transform3D, pos: Vector3, escala := 1.0) -> void:
	var cor: Color = POCOES[_rng.randi() % POCOES.size()]
	_cilindro(t, pos + Vector3.UP * 0.1 * escala, 0.09 * escala, 0.07 * escala, 0.2 * escala, 6, cor, Basis(), true)
	_cilindro(t, pos + Vector3.UP * 0.25 * escala, 0.07 * escala, 0.03 * escala, 0.1 * escala, 6, cor.lerp(Color.WHITE, 0.35), Basis(), true)
	_cilindro(t, pos + Vector3.UP * 0.33 * escala, 0.035 * escala, 0.035 * escala, 0.06 * escala, 5, MADEIRA_ESCURA)


## Tábua de runa (folha): disco de pedra de seis lados com o sinal aceso.
func _tabua_de_runa(t: Transform3D, pos: Vector3, cor: Color, tamanho := 0.34) -> void:
	var em_pe := Basis(Vector3.RIGHT, PI / 2.0 - 0.14)
	_cilindro(t, pos, tamanho, tamanho, 0.1, 6, PEDRA_DE_RUNA, em_pe)
	_cilindro(t, pos + Vector3(0, 0, 0.012), tamanho * 0.86, tamanho * 0.86, 0.1, 6, PEDRA_DE_RUNA * 1.35, em_pe)
	# sinal: losango aceso com um miolo mais claro
	var frente := pos + Vector3(0, 0.01, 0.07)
	GeometriaLowPoly.anexar(_aceso, GeometriaLowPoly.cilindro(tamanho * 0.5, tamanho * 0.5, 0.02, 4), t * Transform3D(em_pe, frente), cor)
	GeometriaLowPoly.anexar(_aceso, GeometriaLowPoly.cilindro(tamanho * 0.22, tamanho * 0.22, 0.02, 4), t * Transform3D(em_pe, frente + Vector3(0, 0, 0.012)), cor.lerp(Color.WHITE, 0.6))


func _lanterna(t: Transform3D, pos: Vector3, escala := 1.0) -> void:
	_caixa(t, pos + Vector3.UP * 0.03 * escala, Vector3(0.3, 0.06, 0.3) * escala, FERRO)
	_caixa(t, pos + Vector3.UP * 0.2 * escala, Vector3(0.2, 0.28, 0.2) * escala, CHAMA, 0.0, 0.0, true)
	for dx: float in [-1.0, 1.0]:
		for dz: float in [-1.0, 1.0]:
			_caixa(t, pos + Vector3(dx * 0.12, 0.2, dz * 0.12) * escala, Vector3(0.035, 0.3, 0.035) * escala, FERRO)
	_cilindro(t, pos + Vector3.UP * 0.42 * escala, 0.22 * escala, 0.0, 0.16 * escala, 4, FERRO, Basis(Vector3.UP, PI / 4.0))


## Lanterna pendurada do teto por uma corrente de elos.
func _lanterna_pendurada(topo: Vector3, comprimento: float) -> void:
	var t := Transform3D(Basis(), topo)
	var elos := int(comprimento / 0.45)
	for k in elos:
		_caixa(t, Vector3.DOWN * (0.2 + k * 0.45), Vector3(0.07, 0.3, 0.07) if k % 2 else Vector3(0.12, 0.3, 0.035), FERRO, k * 0.7)
	_lanterna(t, Vector3.DOWN * (comprimento + 0.5), 1.7)


func _barril(t: Transform3D, pos: Vector3, escala := 1.0) -> void:
	for k in 3:
		var r0: float = [0.36, 0.44, 0.44][k]
		var r1: float = [0.44, 0.44, 0.36][k]
		_cilindro(t, pos + Vector3.UP * (0.18 + k * 0.36) * escala, r0 * escala, r1 * escala, 0.36 * escala, 8, MADEIRA)
	for y: float in [0.3, 0.78]:
		_cilindro(t, pos + Vector3.UP * y * escala, 0.455 * escala, 0.455 * escala, 0.07 * escala, 8, FERRO)
	_cilindro(t, pos + Vector3.UP * 1.085 * escala, 0.33 * escala, 0.33 * escala, 0.02 * escala, 8, MADEIRA_ESCURA)


func _caixote(t: Transform3D, pos: Vector3, lado: float, giro := 0.0) -> void:
	_caixa(t, pos + Vector3.UP * lado / 2.0, Vector3.ONE * lado, MADEIRA, giro)
	for dx: float in [-1.0, 1.0]:
		for dz: float in [-1.0, 1.0]:
			_caixa(t, pos + Vector3(dx * lado * 0.47, lado / 2.0, dz * lado * 0.47).rotated(Vector3.UP, giro), Vector3(lado * 0.12, lado * 1.04, lado * 0.12), MADEIRA_ESCURA, giro)
	_caixa(t, pos + Vector3(0, lado / 2.0, lado * 0.505).rotated(Vector3.UP, giro), Vector3(lado * 1.2, lado * 0.1, 0.03), MADEIRA_ESCURA, giro, 0.0)


func _banquinho(t: Transform3D, pos: Vector3) -> void:
	_cilindro(t, pos + Vector3.UP * 0.5, 0.26, 0.26, 0.07, 7, MADEIRA)
	for k in 3:
		var a := TAU * k / 3.0
		_caixa(t, pos + Vector3(cos(a) * 0.17, 0.24, sin(a) * 0.17), Vector3(0.06, 0.48, 0.06), MADEIRA_ESCURA, 0.0, 0.0)


## Mesa: tampo, quatro pernas, travessas e gaveta (uns 100 triângulos).
func _mesa(t: Transform3D, pos: Vector3, largura: float, fundo: float, altura := 0.9) -> void:
	_caixa(t, pos + Vector3.UP * altura, Vector3(largura, 0.1, fundo), MADEIRA)
	_caixa(t, pos + Vector3.UP * (altura - 0.09), Vector3(largura * 0.92, 0.08, fundo * 0.9), MADEIRA_ESCURA)
	for dx: float in [-1.0, 1.0]:
		for dz: float in [-1.0, 1.0]:
			_caixa(t, pos + Vector3(dx * (largura / 2.0 - 0.1), altura / 2.0, dz * (fundo / 2.0 - 0.1)), Vector3(0.12, altura, 0.12), MADEIRA_ESCURA)
		_caixa(t, pos + Vector3(dx * (largura / 2.0 - 0.1), 0.22, 0), Vector3(0.07, 0.07, fundo - 0.2), MADEIRA)
	_caixa(t, pos + Vector3(0, 0.22, 0), Vector3(largura - 0.2, 0.07, 0.07), MADEIRA)
	_caixa(t, pos + Vector3(0, altura - 0.2, fundo / 2.0 - 0.04), Vector3(largura * 0.4, 0.16, 0.05), MADEIRA)
	_caixa(t, pos + Vector3(0, altura - 0.2, fundo / 2.0), Vector3(0.1, 0.04, 0.05), OURO)
	_colidir(t, pos + Vector3.UP * altura / 2.0, Vector3(largura, altura, fundo))


# --- Estações ----------------------------------------------------------------

## Estante de madeira com tábuas de runa, livros, poções e velas (folha, dos
## dois lados da praça). `de_pocoes`: mais frascos e menos tábuas.
func _estante(t: Transform3D, largura: float, prateleiras: int, tabuas: int, de_pocoes := false) -> void:
	var altura := 0.5 + prateleiras * 1.15
	var fundo := 0.9
	for dx: float in [-1.0, 0.0, 1.0]:
		_caixa(t, Vector3(dx * (largura / 2.0 - 0.09), altura / 2.0, 0), Vector3(0.18, altura, fundo), MADEIRA_ESCURA)
	_caixa(t, Vector3(0, altura / 2.0, -fundo / 2.0 + 0.04), Vector3(largura, altura, 0.06), MADEIRA_ESCURA * 0.8)
	_caixa(t, Vector3(0, altura + 0.08, 0), Vector3(largura + 0.3, 0.16, fundo + 0.2), MADEIRA)
	_colidir(t, Vector3(0, altura / 2.0, 0), Vector3(largura, altura, fundo))
	var posta := 0
	for p in prateleiras:
		var y := 0.4 + p * 1.15
		_caixa(t, Vector3(0, y, 0), Vector3(largura - 0.2, 0.09, fundo - 0.06), MADEIRA)
		for meio: float in [-1.0, 1.0]:
			var centro_x := meio * largura / 4.0
			var vao := largura / 2.0 - 0.45
			var sorte := _rng.randf()
			if posta < tabuas and (sorte < 0.62 or p == 1):
				# duas ou três tábuas de runa lado a lado
				var quantas := 2 if vao < 2.4 else 3
				for k in quantas:
					if posta >= tabuas:
						break
					var cor: Color = _cores_runa[posta % _cores_runa.size()]
					_tabua_de_runa(t, Vector3(centro_x + (k - (quantas - 1) / 2.0) * 0.86, y + 0.4, 0.05), cor)
					posta += 1
			elif de_pocoes or sorte > 0.85:
				for k in 5:
					_pocao(t, Vector3(centro_x - vao / 2.0 + 0.3 + k * (vao - 0.6) / 4.0, y + 0.045, _rng.randf_range(-0.1, 0.2)), _rng.randf_range(0.9, 1.5))
			else:
				_fileira_de_livros(t, Vector3(centro_x - 0.3, y + 0.045, 0.1), vao - 0.7)
				_pilha_de_livros(t, Vector3(centro_x + vao / 2.0 - 0.3, y + 0.045, 0.1), 2 + _rng.randi() % 2)
	# lugares de pouso dos livros voadores, em cima da estante
	_estantes += 1
	for dx: float in [-1.0, 0.0, 1.0]:
		pousos.append({"pos": t * Vector3(dx * (largura / 2.0 - 1.25), altura + (0.3 if dx == 0.0 else 0.2), 0.05), "estante": _estantes})
	# em cima: velas, um cristal e pergaminhos
	_velas(t, Vector3(-largura / 2.0 + 0.5, altura + 0.16, 0.1), 4)
	_velas(t, Vector3(largura / 2.0 - 0.5, altura + 0.16, 0.1), 3)
	for k in 3:
		_pergaminho(t, Vector3(-0.5 + k * 0.5, altura + 0.16, 0.05), _rng.randf_range(-0.4, 0.4))
	_cilindro(t, Vector3(0.9, altura + 0.5, 0), 0.16, 0.0, 0.7, 5, Color(0.6, 0.35, 1.0), Basis(Vector3.BACK, 0.2), true)
	_cilindro(t, Vector3(1.15, altura + 0.38, 0.1), 0.11, 0.0, 0.45, 5, Color(0.75, 0.55, 1.0), Basis(Vector3.BACK, -0.3), true)
	# lanternas de gancho nas duas pontas
	for dx: float in [-1.0, 1.0]:
		_caixa(t, Vector3(dx * (largura / 2.0 + 0.35), altura - 0.3, 0.3), Vector3(0.6, 0.07, 0.07), FERRO)
		_lanterna(t, Vector3(dx * (largura / 2.0 + 0.6), altura - 0.95, 0.3), 1.5)


## Estandarte roxo com o losango dourado (folha), num mastro de madeira.
func _estandarte(t: Transform3D, altura_topo: float, largura: float) -> void:
	var comprimento := largura * 1.9
	_caixa(t, Vector3(0, altura_topo + 0.1, 0.1), Vector3(largura + 0.7, 0.12, 0.12), MADEIRA_ESCURA)
	for dx: float in [-1.0, 1.0]:
		_cilindro(t, Vector3(dx * (largura / 2.0 + 0.4), altura_topo + 0.1, 0.1), 0.11, 0.11, 0.16, 6, OURO, Basis(Vector3.BACK, PI / 2.0))
	# pano: corpo e barra em bico
	_caixa(t, Vector3(0, altura_topo - comprimento / 2.0, 0.14), Vector3(largura, comprimento, 0.04), PANO)
	for dx: float in [-1.0, 1.0]:
		GeometriaLowPoly.anexar(_st, GeometriaLowPoly.cilindro(0.0, largura * 0.36, largura * 0.5, 3),
			t * Transform3D(Basis(Vector3.RIGHT, PI) * Basis().scaled(Vector3(1, 1, 0.08)), Vector3(dx * largura / 4.0, altura_topo - comprimento - largura * 0.24, 0.14)), PANO * 0.9)
	# barra dourada em cima e embaixo, e o losango
	_caixa(t, Vector3(0, altura_topo - 0.16, 0.165), Vector3(largura, 0.1, 0.02), OURO)
	_caixa(t, Vector3(0, altura_topo - comprimento + 0.1, 0.165), Vector3(largura, 0.08, 0.02), OURO)
	var meio := Vector3(0, altura_topo - comprimento * 0.5, 0.17)
	GeometriaLowPoly.anexar(_st, GeometriaLowPoly.cilindro(largura * 0.4, largura * 0.4, 0.03, 4), t * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), meio), OURO)
	GeometriaLowPoly.anexar(_st, GeometriaLowPoly.cilindro(largura * 0.27, largura * 0.27, 0.03, 4), t * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), meio + Vector3(0, 0, 0.012)), PANO * 1.2)
	GeometriaLowPoly.anexar(_aceso, GeometriaLowPoly.cilindro(largura * 0.11, largura * 0.11, 0.03, 4), t * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), meio + Vector3(0, 0, 0.024)), OURO.lerp(Color.WHITE, 0.3))


## Mesa do grimório (folha, canto da frente): atril inclinado com o livro
## aberto, banquinho, tinteiro, pena, velas e pilhas de livros.
func _mesa_do_grimorio(t: Transform3D) -> void:
	_mesa(t, Vector3.ZERO, 3.0, 1.4)
	# atril: cunha de madeira com o livro aberto em cima
	_caixa(t, Vector3(0, 1.12, -0.15), Vector3(1.5, 0.08, 0.95), MADEIRA_ESCURA, 0.0, -0.5)
	_caixa(t, Vector3(0, 1.0, -0.45), Vector3(1.3, 0.3, 0.1), MADEIRA_ESCURA)
	for lado: float in [-1.0, 1.0]:
		# capa, bloco de páginas e a página de cima levemente arqueada
		GeometriaLowPoly.anexar(_st, GeometriaLowPoly.cubo(Vector3(0.62, 0.04, 0.84)),
			t * Transform3D(Basis(Vector3.RIGHT, -0.5) * Basis(Vector3.BACK, lado * 0.1), Vector3(lado * 0.31, 1.19, -0.13)), CAPAS[0])
		GeometriaLowPoly.anexar(_st, GeometriaLowPoly.cubo(Vector3(0.58, 0.07, 0.78)),
			t * Transform3D(Basis(Vector3.RIGHT, -0.5) * Basis(Vector3.BACK, lado * 0.14), Vector3(lado * 0.3, 1.235, -0.11)), PAPEL)
		# sinais de runa escritos na página (acesos, fraquinhos)
		for linha in 4:
			for coluna in 2:
				var cor: Color = _cores_runa[(linha * 2 + coluna + (3 if lado > 0 else 0)) % _cores_runa.size()]
				GeometriaLowPoly.anexar(_aceso, GeometriaLowPoly.cubo(Vector3(0.11, 0.012, 0.09)),
					t * Transform3D(Basis(Vector3.RIGHT, -0.5) * Basis(Vector3.BACK, lado * 0.14), Vector3(lado * (0.17 + coluna * 0.24), 1.28 - linha * 0.085, 0.16 - linha * 0.155)), cor * 0.85)
	_caixa(t, Vector3(0, 1.26, -0.12), Vector3(0.05, 0.05, 0.86), OURO, 0.0, -0.5)        # lombada
	_caixa(t, Vector3(0.08, 1.2, 0.36), Vector3(0.05, 0.012, 0.3), CAPAS[0], 0.0, -0.5)   # fita marcadora
	# em cima da mesa: tinteiro com pena, velas, pergaminhos, livros
	_cilindro(t, Vector3(1.1, 1.01, 0.3), 0.08, 0.06, 0.12, 6, FERRO)
	_caixa(t, Vector3(1.13, 1.22, 0.3), Vector3(0.03, 0.4, 0.09), PAPEL, 0.0, 0.0)
	_velas(t, Vector3(-1.15, 0.95, 0.35), 4)
	_velas(t, Vector3(1.2, 0.95, -0.35), 3)
	_pergaminho(t, Vector3(-0.9, 0.95, -0.2), 0.5)
	_pergaminho(t, Vector3(-1.0, 0.95, 0.0), 0.2)
	_pilha_de_livros(t, Vector3(-1.2, 0.95, -0.4), 3)
	_banquinho(t, Vector3(0.1, 0, 1.25))
	_pilha_de_livros(t, Vector3(1.9, 0, 0.4), 5)
	_pilha_de_livros(t, Vector3(2.25, 0, -0.1), 3)
	_lanterna(t, Vector3(-1.9, 0, 0.3), 1.6)


## Baú com ferragens douradas, barris e um caixote (folha, lado esquerdo).
func _bau_e_barris(t: Transform3D) -> void:
	# baú: corpo, tampa em meia-lua (meio cilindro deitado), cintas e fecho
	_caixa(t, Vector3(0, 0.36, 0), Vector3(1.7, 0.72, 1.0), MADEIRA)
	_cilindro(t, Vector3(0, 0.72, 0), 0.5, 0.5, 1.7, 8, MADEIRA_ESCURA, Basis(Vector3.BACK, PI / 2.0))
	for dx: float in [-0.62, 0.0, 0.62]:
		_cilindro(t, Vector3(dx, 0.72, 0), 0.525, 0.525, 0.12, 8, OURO, Basis(Vector3.BACK, PI / 2.0))
		_caixa(t, Vector3(dx, 0.36, 0), Vector3(0.12, 0.74, 1.04), OURO)
	_caixa(t, Vector3(0, 0.66, 0.52), Vector3(0.22, 0.26, 0.06), OURO)
	_caixa(t, Vector3(0, 0.62, 0.555), Vector3(0.07, 0.1, 0.02), FERRO)
	_colidir(t, Vector3(0, 0.6, 0), Vector3(1.7, 1.2, 1.0))
	_barril(t, Vector3(-1.9, 0, -0.2), 1.25)
	_barril(t, Vector3(-2.9, 0, 0.3), 1.1)
	_barril(t, Vector3(-2.4, 0, -1.0), 1.25)
	_colidir(t, Vector3(-2.4, 0.7, -0.3), Vector3(2.2, 1.4, 2.0))
	_caixote(t, Vector3(1.8, 0, -0.3), 1.0, 0.3)
	_caixote(t, Vector3(1.9, 1.0, -0.35), 0.7, -0.2)
	_colidir(t, Vector3(1.85, 0.85, -0.3), Vector3(1.1, 1.7, 1.1))
	_velas(t, Vector3(0.9, 0, 0.9), 5)
	_lanterna(t, Vector3(-1.3, 0, 0.9), 1.6)
	_pilha_de_livros(t, Vector3(1.75, 1.7, -0.35), 2)
	_pocao(t, Vector3(-1.9, 1.38, -0.2), 1.6)


## Mesa de trabalho (folha, lado direito): pergaminhos, livros, frascos, uma
## tábua de runa em obra e ferramentas.
func _mesa_de_trabalho(t: Transform3D) -> void:
	_mesa(t, Vector3.ZERO, 3.6, 1.5)
	_tabua_de_runa(t, Vector3(-0.2, 1.25, -0.3), _cores_runa[4 % _cores_runa.size()], 0.4)
	_caixa(t, Vector3(-0.2, 1.0, -0.42), Vector3(0.5, 0.1, 0.12), MADEIRA_ESCURA)
	# martelinho e cinzel
	_caixa(t, Vector3(0.7, 0.99, 0.2), Vector3(0.45, 0.05, 0.05), MADEIRA, 0.5)
	_caixa(t, Vector3(0.88, 0.99, 0.1), Vector3(0.1, 0.1, 0.22), FERRO, 0.5)
	_caixa(t, Vector3(0.4, 0.98, 0.42), Vector3(0.36, 0.035, 0.05), FERRO, -0.3)
	for k in 4:
		_pocao(t, Vector3(1.2 + k * 0.17, 0.95, -0.4 + (k % 2) * 0.16), _rng.randf_range(1.0, 1.6))
	for k in 3:
		_pergaminho(t, Vector3(-1.35, 0.95 + k * 0.0, -0.3 + k * 0.2), _rng.randf_range(-0.2, 0.2))
	# pergaminho aberto com sinais
	_caixa(t, Vector3(-0.95, 0.955, 0.38), Vector3(0.7, 0.012, 0.46), PAPEL, 0.15)
	for k in 3:
		_caixa(t, Vector3(-1.15 + k * 0.2, 0.965, 0.38 + k * 0.03), Vector3(0.1, 0.01, 0.1), _cores_runa[k % _cores_runa.size()], 0.15, 0.0, true)
	_pilha_de_livros(t, Vector3(1.45, 0.95, 0.35), 4)
	_velas(t, Vector3(0.1, 0.95, 0.5), 3)
	_velas(t, Vector3(-1.6, 0.95, 0.5), 4)
	_banquinho(t, Vector3(-0.4, 0, 1.3))
	_banquinho(t, Vector3(1.0, 0, 1.25))
	_barril(t, Vector3(2.5, 0, -0.1), 1.2)
	_colidir(t, Vector3(2.5, 0.7, -0.1), Vector3(1.0, 1.4, 1.0))
	_pilha_de_livros(t, Vector3(2.5, 1.32, -0.1), 2)
	_lanterna(t, Vector3(-2.4, 0, 0.2), 1.6)
	_caixote(t, Vector3(-2.7, 0, -0.7), 0.9, 0.2)


## Caixotes empilhados, um deles aberto com cristais roxos (folha).
func _caixotes(t: Transform3D) -> void:
	_caixote(t, Vector3(0, 0, 0), 1.3, 0.1)
	_caixote(t, Vector3(1.5, 0, 0.2), 1.1, -0.25)
	_caixote(t, Vector3(0.2, 1.3, 0.0), 0.9, 0.4)
	_caixote(t, Vector3(-1.5, 0, 0.3), 1.0, 0.5)
	_colidir(t, Vector3(0.0, 1.0, 0.1), Vector3(4.2, 2.0, 1.5))
	for k in 5:
		var altura := _rng.randf_range(0.5, 1.0)
		_cilindro(t, Vector3(1.5 + _rng.randf_range(-0.3, 0.3), 1.1 + altura / 2.0 - 0.1, 0.2 + _rng.randf_range(-0.3, 0.3)), altura * 0.2, 0.0, altura, 5,
			Color(0.6, 0.35, 1.0).lerp(Color.WHITE, _rng.randf_range(0.0, 0.3)), Basis(Vector3(1, 0, 0.4).normalized(), _rng.randf_range(-0.35, 0.35)), true)
	_barril(t, Vector3(-2.7, 0, -0.2), 1.15)
	_colidir(t, Vector3(-2.7, 0.7, -0.2), Vector3(1.0, 1.4, 1.0))
	_velas(t, Vector3(-1.5, 1.0, 0.3), 3)
	_velas(t, Vector3(0.9, 0, 1.2), 4)
	_lanterna(t, Vector3(0.2, 2.2, 0.0), 1.5)
	_pergaminho(t, Vector3(-0.3, 1.3, 0.3), 0.6)


## Mirante: plataforma de madeira com rampa de degraus, corrimão e lanternas,
## na beira do abismo, para olhar as ilhas e as cachoeiras.
func _mirante(t: Transform3D) -> void:
	var alto := 2.2
	_caixa(t, Vector3(0, alto, -0.4), Vector3(5.4, 0.22, 3.6), MADEIRA)
	for k in 7:
		_caixa(t, Vector3(-2.4 + k * 0.8, alto + 0.115, -0.4), Vector3(0.05, 0.02, 3.6), MADEIRA_ESCURA)
	for dx: float in [-1.0, 1.0]:
		for dz: float in [-1.0, 1.0]:
			_caixa(t, Vector3(dx * 2.45, alto / 2.0, -0.4 + dz * 1.55), Vector3(0.3, alto, 0.3), MADEIRA_ESCURA)
		_caixa(t, Vector3(dx * 2.45, alto * 0.55, -0.4), Vector3(0.12, 0.12, 3.5), MADEIRA_ESCURA, 0.0, 0.6 * dx)
	_colidir(t, Vector3(0, alto - 0.3, -0.4), Vector3(5.4, 0.82, 3.6))
	# rampa de degraus subindo de frente (do centro da câmara para a beirada)
	_rampa(t, 0.0, 1.4, 4.2, alto)
	# corrimão: postes e travessa nos três lados que dão para o vazio
	for k in 6:
		var x := -2.6 + k * 1.04
		_caixa(t, Vector3(x, alto + 0.55, -2.1), Vector3(0.14, 1.1, 0.14), MADEIRA_ESCURA)
	_caixa(t, Vector3(0, alto + 1.05, -2.1), Vector3(5.5, 0.1, 0.1), MADEIRA)
	_caixa(t, Vector3(0, alto + 0.6, -2.1), Vector3(5.5, 0.07, 0.07), MADEIRA)
	for dx: float in [-1.0, 1.0]:
		for k in 3:
			_caixa(t, Vector3(dx * 2.6, alto + 0.55, -1.9 + k * 1.3), Vector3(0.14, 1.1, 0.14), MADEIRA_ESCURA)
		_caixa(t, Vector3(dx * 2.6, alto + 1.05, -0.6), Vector3(0.1, 0.1, 2.9), MADEIRA)
		_colidir(t, Vector3(dx * 2.6, alto + 0.6, -0.6), Vector3(0.2, 1.2, 3.0))
		_lanterna(t, Vector3(dx * 2.6, alto + 1.1, -2.1), 1.6)
	_colidir(t, Vector3(0, alto + 0.6, -2.1), Vector3(5.5, 1.2, 0.2))
	# o que alguém deixou lá em cima: luneta num tripé, livros, velas, caixote
	_cilindro(t, Vector3(1.2, alto + 1.25, -1.4), 0.07, 0.11, 0.9, 6, OURO, Basis(Vector3.RIGHT, PI / 2.0 - 0.25))
	for k in 3:
		var a := TAU * k / 3.0
		_caixa(t, Vector3(1.2 + cos(a) * 0.22, alto + 0.6, -1.25 + sin(a) * 0.22), Vector3(0.05, 1.1, 0.05), MADEIRA_ESCURA, 0.0, 0.0)
	_pilha_de_livros(t, Vector3(-1.6, alto + 0.11, -1.2), 4)
	_velas(t, Vector3(-0.9, alto + 0.11, -1.5), 4)
	_caixote(t, Vector3(-1.9, alto + 0.11, 0.4), 0.7, 0.3)
	_barril(t, Vector3(2.1, 0, 2.2), 1.2)
	_velas(t, Vector3(-1.5, 0, 2.4), 3)


## Andaime de madeira de dois andares (folha): postes, passarela em cima com
## corrimão, travessas em X no fundo, escada numa ponta e correntes em arco
## com lanterna entre os postes da frente. `lado_da_escada`: +1 ou -1 (ponta
## em X onde a escada sobe).
func _andaime(t: Transform3D, largura: float, fundo: float, altura: float, lado_da_escada: float) -> void:
	var vaos := 5
	var passo := largura / vaos
	var x_escada := lado_da_escada * (largura / 2.0 - passo / 2.0)
	for k in vaos + 1:
		var x := -largura / 2.0 + k * passo
		# poste do fundo (até o piso de cima) e da frente (sobe além do corrimão)
		_caixa(t, Vector3(x, altura / 2.0, -fundo / 2.0), Vector3(0.34, altura, 0.34), MADEIRA_ESCURA)
		_caixa(t, Vector3(x, (altura + 2.4) / 2.0, fundo / 2.0), Vector3(0.34, altura + 2.4, 0.34), MADEIRA_ESCURA)
		_caixa(t, Vector3(x, altura + 2.45, fundo / 2.0), Vector3(0.46, 0.12, 0.46), MADEIRA)
		_colidir(t, Vector3(x, altura / 2.0, fundo / 2.0), Vector3(0.4, altura, 0.4))
		# viga entre a frente e o fundo, sob o piso
		_caixa(t, Vector3(x, altura - 0.22, 0), Vector3(0.2, 0.24, fundo), MADEIRA_ESCURA)
		if k < vaos:
			var meio := x + passo / 2.0
			# travessas em X no fundo
			for sentido: float in [-1.0, 1.0]:
				GeometriaLowPoly.anexar(_st, GeometriaLowPoly.cubo(Vector3(sqrt(passo * passo + altura * altura * 0.36), 0.12, 0.1)),
					t * Transform3D(Basis(Vector3.BACK, sentido * atan2(altura * 0.6, passo)), Vector3(meio, altura * 0.5, -fundo / 2.0 - 0.05 * sentido)), MADEIRA_ESCURA * 0.85)
			# corrimão da frente (menos no vão em que a escada chega)
			if absf(meio - x_escada) > 0.1:
				_caixa(t, Vector3(meio, altura + 1.05, fundo / 2.0), Vector3(passo, 0.1, 0.1), MADEIRA)
				_caixa(t, Vector3(meio, altura + 0.6, fundo / 2.0), Vector3(passo, 0.07, 0.07), MADEIRA)
				_colidir(t, Vector3(meio, altura + 0.6, fundo / 2.0), Vector3(passo, 1.2, 0.2))
			# corrente em arco entre os topos dos postes, com lanterna no meio
			for q in 7:
				var f := (q + 0.5) / 7.0
				var queda := sin(f * PI) * 0.9
				_caixa(t, Vector3(x + passo * f, altura + 2.3 - queda, fundo / 2.0), Vector3(0.36, 0.06, 0.06) if q % 2 else Vector3(0.36, 0.11, 0.035), FERRO)
			if k % 2 == 0:
				_lanterna(t, Vector3(meio, altura + 0.75, fundo / 2.0), 1.4)
	# piso de cima: tábuas com fresta
	var tabuas := int(largura / 0.75)
	for k in tabuas:
		_caixa(t, Vector3(-largura / 2.0 + (k + 0.5) * largura / tabuas, altura, 0), Vector3(largura / tabuas - 0.05, 0.16, fundo + 0.3), MADEIRA if k % 3 else MADEIRA * 0.88)
	_colidir(t, Vector3(0, altura - 0.12, 0), Vector3(largura, 0.4, fundo + 0.3))
	# corrimão das duas pontas; atrás, uma parede invisível encostada na pedra
	for ponta: float in [-1.0, 1.0]:
		_caixa(t, Vector3(ponta * largura / 2.0, altura + 1.05, 0), Vector3(0.1, 0.1, fundo), MADEIRA)
		_colidir(t, Vector3(ponta * (largura / 2.0 + 0.1), altura + 0.6, 0), Vector3(0.2, 1.2, fundo))
	_colidir(t, Vector3(0, altura + 0.6, -fundo / 2.0 - 0.2), Vector3(largura, 1.2, 0.2))
	# escada
	_rampa(t, x_escada, fundo / 2.0 + 0.1, 7.6, altura, passo - 0.9)
