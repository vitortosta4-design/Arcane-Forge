// Sulcos de lava e linhas de runa do piso da forja: a cor de cada vértice
// com uma onda de brilho que sai do pé da bigorna e corre para as paredes,
// como brasa respirando. Sem luz e sem sombra.
shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform vec3 centro = vec3(0.0);
uniform float velocidade = 2.2;
uniform float comprimento_da_onda = 7.0;

varying vec3 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float longe = distance(mundo.xz, centro.xz);
	float onda = 0.5 + 0.5 * sin(longe * 6.2832 / comprimento_da_onda - TIME * velocidade);
	ALBEDO = COLOR.rgb * (0.78 + 0.5 * onda * onda);
	EMISSION = COLOR.rgb * 0.5 * onda;
}
