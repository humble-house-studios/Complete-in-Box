// The data side of a CD / DVD / GD-ROM: a mirror-silver (or PS-style black)
// surface with the classic diffraction rainbow. The spectrum fans out in two
// opposite streaks that follow the viewer around the disc, plus fine
// concentric track rings and a clear hub. PSX vertex snap + fog to match psx.gdshader.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;

uniform vec4 base : source_color = vec4(0.78, 0.8, 0.86, 1.0);
uniform float strength = 1.0;
uniform float hub = 0.07;
uniform float snap = 700.0;
uniform vec4 fog_color : source_color = vec4(0.04, 0.03, 0.05, 1.0);
uniform float fog_near = 4.0;
uniform float fog_far = 14.0;

varying float fog;
varying vec3 cam_local;

void vertex() {
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	fog = clamp((-view.z - fog_near) / max(fog_far - fog_near, 0.01), 0.0, 1.0);
	cam_local = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz - VERTEX;
	vec4 clip = PROJECTION_MATRIX * view;
	clip.xy = floor(clip.xy / clip.w * snap) / snap * clip.w;
	POSITION = clip;
}

vec3 spectrum(float h) {
	return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p) * 2.0;
	if (r > 1.0 || r < hub * 2.0) {
		discard;
	}
	float ang = atan(p.y, p.x);
	vec2 cv = normalize(cam_local.xy + vec2(0.0001));
	float view_ang = atan(cv.y, cv.x) + TIME * 0.15;
	// Two bright opposite fans, each a full spectrum across its width.
	float d = sin(ang - view_ang);
	float fan = pow(abs(cos(ang - view_ang)), 6.0);
	float tilt = clamp(1.0 - abs(normalize(cam_local).z), 0.15, 1.0);
	vec3 rainbow = spectrum(fract(d * 0.55 + r * 0.6 + tilt * 0.4));
	vec3 c = base.rgb;
	float data = smoothstep(0.42, 0.46, r) * (1.0 - smoothstep(0.96, 0.99, r));
	// Fine track rings and the burned/pressed area edge.
	float rings = 0.92 + 0.08 * sin(r * 260.0);
	c *= mix(1.0, rings, data);
	float sheen = 0.12 + 0.88 * fan * fan;
	c = mix(c, c * 0.45 + rainbow * 0.85, data * sheen * strength);
	// Clear plastic hub ring and the stacking ring.
	float clear = (1.0 - smoothstep(0.38, 0.42, r));
	c = mix(c, vec3(0.86, 0.88, 0.92), clear * 0.55);
	c += vec3(0.25) * (1.0 - smoothstep(0.0, 0.02, abs(r - 0.33)));
	c += vec3(0.35) * pow(fan, 12.0) * data;
	ALBEDO = mix(c, fog_color.rgb, fog * 0.7);
	ROUGHNESS = 1.0;
	EMISSION = c * 0.2 * (1.0 - fog);
}
