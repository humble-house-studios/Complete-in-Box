// Foil shine for rare and grail play cards: a soft band sweeps across now
// and then (rainbow for grails).
shader_type canvas_item;

uniform float phase = 0.0;
uniform float rainbow = 0.0;
uniform float strength = 0.45;

void fragment() {
	float d = UV.x * 0.7 + UV.y * 0.45;
	float p = fract(TIME * 0.22 + phase) * 2.6 - 0.6;
	float band = smoothstep(0.16, 0.0, abs(d - p));
	vec3 hue = 0.55 + 0.45 * cos(6.2831 * (vec3(0.0, 0.33, 0.67) + d * 1.6 + TIME * 0.1));
	vec3 col = mix(vec3(1.0, 0.96, 0.82), hue, rainbow);
	// A faint steady sheen so grails always look foiled.
	float sheen = rainbow * 0.12 * (0.5 + 0.5 * sin(d * 9.0 + TIME * 0.8));
	COLOR = vec4(col, strength * band + sheen);
}
