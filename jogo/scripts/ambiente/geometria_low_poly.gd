class_name GeometriaLowPoly
extends RefCounted
## Ferramentas para montar cenário low poly em código, juntando várias peças
## numa malha só (uma árvore inteira, uma ruína inteira). Menos malhas
## separadas = menos trabalho para a placa de vídeo (proposta técnica,
## seção 8). Cada triângulo ganha uma cor lisa e normal "reta", que é o que
## dá o visual facetado da referência (ADR-007).


## Começa uma malha nova em que cada face fica com a normal reta.
static func nova() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	return st


## Copia uma primitiva do Godot (cubo, cilindro, cone, esfera) para dentro
## da malha, já movida/girada/escalada e pintada de uma cor.
static func anexar(st: SurfaceTool, primitiva: PrimitiveMesh, transformada: Transform3D, cor: Color) -> void:
	var arrays := primitiva.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	st.set_color(cor)
	for i in indices:
		st.add_vertex(transformada * vertices[i])


## Igual a anexar, mas com as faces viradas para dentro (para ver de dentro
## de uma cúpula, como o teto da caverna).
static func anexar_invertido(st: SurfaceTool, primitiva: PrimitiveMesh, transformada: Transform3D, cor: Color) -> void:
	var arrays := primitiva.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	st.set_color(cor)
	for t in range(0, indices.size(), 3):
		st.add_vertex(transformada * vertices[indices[t + 2]])
		st.add_vertex(transformada * vertices[indices[t + 1]])
		st.add_vertex(transformada * vertices[indices[t]])


## Triângulo solto, com a frente virada para quem vê a e b e c em sentido
## horário (a convenção do Godot).
static func triangulo(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, cor: Color) -> void:
	st.set_color(cor)
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


static func finalizar(st: SurfaceTool) -> ArrayMesh:
	st.generate_normals()
	return st.commit()


static func cubo(tamanho: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = tamanho
	return m


static func cilindro(raio_baixo: float, raio_cima: float, altura: float, lados: int) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.bottom_radius = raio_baixo
	m.top_radius = raio_cima
	m.height = altura
	m.radial_segments = lados
	m.rings = 1
	return m


static func esfera(raio: float, lados: int, aneis: int) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = raio
	m.height = raio * 2.0
	m.radial_segments = lados
	m.rings = aneis
	return m


## Material toon do projeto usando a cor de cada vértice.
static func material_toon(contorno := 0.25, faixas := 3) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/toon_contorno.gdshader")
	mat.set_shader_parameter("cor_base", Color.WHITE)
	mat.set_shader_parameter("contorno_intensidade", contorno)
	mat.set_shader_parameter("faixas", faixas)
	return mat


## Varia levemente uma cor, para pedras e folhas não ficarem todas iguais.
static func variar(cor: Color, rng: RandomNumberGenerator, quanto := 0.08) -> Color:
	var f := rng.randf_range(1.0 - quanto, 1.0 + quanto)
	return Color(cor.r * f, cor.g * f, cor.b * f, 1.0)
