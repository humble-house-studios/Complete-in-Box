// PSX-style surface: vertex snapping, nearest textures, hard lambert, distance fog.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D tex : source_color, filter_nearest, repeat_enable;
uniform bool use_tex = false;
uniform vec2 uv_scale = vec2(1.0);
uniform float snap = 120.0;
uniform float emit = 0.0;
// Optional label decal (cartridge stickers): inside label_rect (UV) show label_tex,
// elsewhere tint the body. circle cuts a disc shape (CDs).
uniform sampler2D label_tex : source_color, filter_nearest;
uniform bool use_label = false;
uniform vec4 label_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 body_tint : source_color = vec4(1.0);
uniform bool circle = false;
// Label art fitted into its sticker without stretching: uv = (l - xy) / zw,
// outside shows label_bg (letterbox). tex_fit crops the main texture (cover).
uniform vec4 label_fit = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 label_bg : source_color = vec4(0.06, 0.06, 0.07, 1.0);
uniform vec4 tex_fit = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 fog_color : source_color = vec4(0.04, 0.03, 0.05, 1.0);
uniform float fog_near = 4.0;
uniform float fog_far = 14.0;

varying float fog;

void vertex() {
	UV *= uv_scale;
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	fog = clamp((-view.z - fog_near) / max(fog_far - fog_near, 0.01), 0.0, 1.0);
	vec4 clip = PROJECTION_MATRIX * view;
	clip.xy = floor(clip.xy / clip.w * snap) / snap * clip.w;
	POSITION = clip;
}

void fragment() {
	if (circle) {
		float r = distance(UV, vec2(0.5));
		if (r > 0.5 || r < 0.07) {
			discard;
		}
	}
	vec4 c = albedo;
	if (use_tex) {
		c *= texture(tex, UV * tex_fit.zw + tex_fit.xy);
	}
	if (use_label) {
		vec2 l = (UV - label_rect.xy) / label_rect.zw;
		if (l.x >= 0.0 && l.x <= 1.0 && l.y >= 0.0 && l.y <= 1.0) {
			vec2 f = (l - label_fit.xy) / label_fit.zw;
			if (f.x >= 0.0 && f.x <= 1.0 && f.y >= 0.0 && f.y <= 1.0) {
				c = texture(label_tex, f);
			} else {
				c = label_bg;
			}
		} else {
			c.rgb *= body_tint.rgb;
		}
	}
	ALBEDO = mix(c.rgb, fog_color.rgb, fog * 0.7);
	ROUGHNESS = 1.0;
	EMISSION = c.rgb * emit * (1.0 - fog);
}
