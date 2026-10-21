class_name ModelosProps
extends RefCounted
## Malhas dos objetos de cenário que dá para quebrar ou explodir, no estilo
## da referência: caixote de tábuas com quinas reforçadas e barril de
## madeira bojudo com cintas de metal. O barril inflamável tem uma faixa
## vermelha, para o jogador saber de longe que ele pega fogo.

const COR_MADEIRA := Color(0.6, 0.4, 0.22)
const COR_MADEIRA_ESCURA := Color(0.46, 0.29, 0.16)
const COR_METAL := Color(0.32, 0.31, 0.33)
const COR_PERIGO := Color(0.78, 0.16, 0.1)


static func caixa(lado: float) -> ArrayMesh:
	var st := GeometriaLowPoly.nova()
	var G := GeometriaLowPoly
	var meio := lado / 2.0
	var viga := lado * 0.13
	G.anexar(st, G.cubo(Vector3.ONE * (lado - 0.02)), Transform3D(), COR_MADEIRA)
	# Doze vigas nas quinas.
	for eixo in 3:
		for a in [-1.0, 1.0]:
			for b in [-1.0, 1.0]:
				var tamanho := Vector3.ONE * viga
				tamanho[eixo] = lado
				var pos := Vector3.ZERO
				pos[(eixo + 1) % 3] = a * (meio - viga / 2.0 + 0.005)
				pos[(eixo + 2) % 3] = b * (meio - viga / 2.0 + 0.005)
				G.anexar(st, G.cubo(tamanho), Transform3D(Basis(), pos), COR_MADEIRA_ESCURA)
	# Tábua em diagonal na frente e atrás, e frestas entre as tábuas dos lados.
	for lado_z in [-1.0, 1.0]:
		var diagonal := Basis(Vector3(0, 0, 1), PI / 4.0)
		G.anexar(st, G.cubo(Vector3(lado * 1.2, viga * 0.9, 0.02)),
			Transform3D(diagonal, Vector3(0, 0, lado_z * (meio + 0.002))), COR_MADEIRA_ESCURA)
	for lado_x in [-1.0, 1.0]:
		for y in [-lado / 6.0, lado / 6.0]:
			G.anexar(st, G.cubo(Vector3(0.02, 0.012, lado - viga)),
				Transform3D(Basis(), Vector3(lado_x * (meio - 0.005), y, 0)), COR_MADEIRA_ESCURA * 0.8)
	return G.finalizar(st)


static func barril(raio: float, altura: float, inflamavel: bool) -> ArrayMesh:
	var st := GeometriaLowPoly.nova()
	var G := GeometriaLowPoly
	var bojo := raio * 1.1
	var ponta := raio * 0.88
	G.anexar(st, G.cilindro(ponta, bojo, altura / 2.0, 9), Transform3D(Basis(), Vector3(0, -altura / 4.0, 0)), COR_MADEIRA)
	G.anexar(st, G.cilindro(bojo, ponta, altura / 2.0, 9), Transform3D(Basis(), Vector3(0, altura / 4.0, 0)), COR_MADEIRA)
	for y in [-altura * 0.38, altura * 0.38]:
		var r := lerpf(bojo, ponta, absf(y) / (altura / 2.0)) + 0.012
		G.anexar(st, G.cilindro(r, r, altura * 0.07, 9), Transform3D(Basis(), Vector3(0, y, 0)), COR_METAL)
	var faixa := COR_PERIGO if inflamavel else COR_METAL
	G.anexar(st, G.cilindro(bojo + 0.012, bojo + 0.012, altura * 0.16, 9), Transform3D(), faixa)
	for y in [-altura / 2.0, altura / 2.0]:
		G.anexar(st, G.cilindro(ponta * 0.92, ponta * 0.92, 0.02, 9), Transform3D(Basis(), Vector3(0, y, 0)), COR_MADEIRA_ESCURA)
	return G.finalizar(st)
