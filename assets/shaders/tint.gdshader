// Recolours a sprite to `tint` by its brightness, keeping specular highlights
// white (a yellow emoji face becomes a pink puffball, a brown hedgehog blue).
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = tint.rgb * clamp(l * 1.45, 0.0, 1.2);
	col = mix(col, vec3(1.0), smoothstep(0.82, 0.98, l));
	COLOR = vec4(col, c.a) * COLOR;
}
