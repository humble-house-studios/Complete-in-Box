// Low-res screen look: ordered dither + colour crush + vignette + faint scanlines.
shader_type canvas_item;

uniform float levels = 40.0;
uniform float vignette = 0.22;
uniform float scan = 0.025;
uniform float pixel = 3.0;
uniform vec4 tint : source_color = vec4(1.0);

const float bayer[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	ivec2 p = ivec2(FRAGCOORD.xy / pixel);
	float d = bayer[(p.x % 4) + (p.y % 4) * 4] / 16.0 - 0.5;
	c.rgb = floor(c.rgb * levels + d * 0.6 + 0.5) / levels;
	c.rgb *= tint.rgb;
	c.rgb = pow(c.rgb, vec3(0.9)) * 1.06;
	float luma = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(vec3(luma), c.rgb, 1.15);
	vec2 q = UV - 0.5;
	c.rgb *= 1.0 - dot(q, q) * vignette * 2.0;
	c.rgb *= 1.0 - scan * step(0.5, fract(FRAGCOORD.y / pixel * 0.5));
	COLOR = vec4(c.rgb, 1.0);
}
