shader_type canvas_item;
// Brilho dourado que atravessa texto/ícone. progress: -0.3 .. 1.3 (em relação a area_size).
uniform float progress = -0.3;
uniform float width = 0.12;
uniform vec2 area_size = vec2(800.0, 120.0);
uniform vec4 sheen : source_color = vec4(1.0, 0.95, 0.7, 1.0);
varying vec2 lp;
void vertex() {
	lp = VERTEX;
}
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float d = abs((lp.x / area_size.x + lp.y / area_size.y * 0.25) - progress);
	float k = smoothstep(width, 0.0, d);
	c.rgb = mix(c.rgb, sheen.rgb, k * 0.85);
	COLOR = c;
}
