shader_type canvas_item;
// Pergaminho procedural: ruído FBM, manchas, borda queimada e vinheta. Motivos por cenário.
uniform vec4 base_color : source_color = vec4(0.78, 0.68, 0.48, 1.0);
uniform vec4 stain_color : source_color = vec4(0.45, 0.32, 0.16, 1.0);
uniform vec4 ink_color : source_color = vec4(0.25, 0.17, 0.08, 1.0);
uniform int motif = 0;            // 0 nenhum, 1 colinas, 2 rochas, 3 ondas, 4 rachaduras
uniform float motif_strength = 0.18;
uniform float burn = 0.55;
uniform float vignette = 0.5;
uniform vec2 rect_size = vec2(1920.0, 780.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.02; a *= 0.5; }
	return v;
}

void fragment() {
	vec2 uv = UV;
	vec2 px = uv * rect_size;
	float n = fbm(px / 140.0);
	float fine = fbm(px / 9.0);
	vec3 col = mix(base_color.rgb, stain_color.rgb, smoothstep(0.45, 0.85, n) * 0.55);
	col *= 0.93 + fine * 0.14;

	float m = 0.0;
	if (motif == 1) {          // colinas: curvas de nível
		float h = fbm(px / 220.0) * 9.0;
		m = smoothstep(0.06, 0.0, abs(fract(h) - 0.5) - 0.44) ;
	} else if (motif == 2) {   // rochas: hachuras diagonais em manchas
		float mask = smoothstep(0.5, 0.7, fbm(px / 160.0 + 7.0));
		m = mask * step(0.82, fract((px.x + px.y) / 11.0));
	} else if (motif == 3) {   // ondas
		float w = sin(px.x / 26.0 + sin(px.y / 38.0) * 2.0 + px.y / 14.0);
		m = smoothstep(0.93, 1.0, w) * smoothstep(0.35, 0.6, fbm(px / 120.0 + 3.0));
	} else if (motif == 4) {   // rachaduras
		float c = abs(fbm(px / 90.0 + 11.0) - 0.5);
		m = smoothstep(0.018, 0.0, c);
	}
	col = mix(col, ink_color.rgb, m * motif_strength * 2.2);

	// borda queimada + vinheta
	float edge = min(min(uv.x, 1.0 - uv.x) * rect_size.x, min(uv.y, 1.0 - uv.y) * rect_size.y);
	float b = smoothstep(70.0 * (0.6 + n * 0.8), 0.0, edge);
	col = mix(col, vec3(0.12, 0.07, 0.03), b * burn);
	float v = distance(uv, vec2(0.5));
	col *= 1.0 - smoothstep(0.35, 0.85, v) * vignette;
	COLOR = vec4(col, 1.0);
}
