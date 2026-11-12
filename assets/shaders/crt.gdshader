// Full-screen overlay over the UI: scanlines, slight vignette and grain.
shader_type canvas_item;

uniform float strength = 1.0;
uniform float t = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec2 q = SCREEN_UV - 0.5;
	float v = dot(q, q) * 0.9;
	float lines = step(0.5, fract(FRAGCOORD.y * 0.5)) * 0.07;
	float n = (hash(floor(FRAGCOORD.xy / 2.0) + floor(t * 24.0)) - 0.5) * 0.05;
	float a = clamp(v + lines + n, 0.0, 1.0) * strength;
	COLOR = vec4(0.0, 0.0, 0.0, a);
}
