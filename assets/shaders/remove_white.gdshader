shader_type canvas_item;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float white = step(0.95, col.r) * step(0.95, col.g) * step(0.95, col.b);
	COLOR = vec4(col.rgb, col.a * (1.0 - white));
}
