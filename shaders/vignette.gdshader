shader_type canvas_item;
uniform float strength = 0.7;
uniform vec4 tint : source_color = vec4(0.05, 0.03, 0.02, 1.0);
void fragment() {
	float v = distance(UV, vec2(0.5));
	COLOR = vec4(tint.rgb, smoothstep(0.25, 0.8, v) * strength);
}
