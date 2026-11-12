// Ink outline (inverted hull) drawn as a next_pass: a constant-width dark rim
// around items and people so the 3D world reads like the cards' thick borders.
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(0.07, 0.04, 0.12, 1.0);
uniform float width = 1.4;
uniform float snap = 700.0;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 n = mat3(MODELVIEW_MATRIX) * NORMAL;
	vec2 nc = (PROJECTION_MATRIX * vec4(n, 0.0)).xy;
	float l = length(nc);
	if (l > 0.00001) {
		clip.xy += nc / l * width * 2.0 / VIEWPORT_SIZE * clip.w;
	}
	clip.xy = floor(clip.xy / clip.w * snap) / snap * clip.w;
	POSITION = clip;
}

void fragment() {
	ALBEDO = color.rgb;
}
