shader_type canvas_item;


uniform float BLOOM_THRESHOLD = 1;
uniform float BLOOM_INTENSITY = 1.8;

uniform int BLUR_ITERATIONS = 3;
uniform float BLUR_SIZE = 0.1;
uniform int BLUR_SUBDIVISIONS = 32;

uniform float r = 0;
uniform vec2 offset = vec2(-0.15, -0.15);

uniform vec4 modulate = vec4(1, 1, 1, 1);

void vertex() {
	VERTEX.xy *= 3.;
}

vec3 getHDR(vec3 tex) {
    return max((tex - BLOOM_THRESHOLD) * BLOOM_INTENSITY, vec3(0.0));
}

vec3 gaussian(sampler2D sampler, vec2 uv) {
    vec3 sum = vec3(0.0);

    for (int i = 1; i <= BLUR_ITERATIONS; i++) {
        float angle = 360.0 / float(BLUR_SUBDIVISIONS);

        for (int j = 0; j < BLUR_SUBDIVISIONS; j++) {
            float dist = BLUR_SIZE * float(i + 1) / float(BLUR_ITERATIONS);
            float s = sin(angle * float(j));
            float c = cos(angle * float(j));

            sum += getHDR(texture(sampler, uv + vec2(c, s) * dist).xyz);
        }
    }

    sum /= float(BLUR_ITERATIONS * BLUR_SUBDIVISIONS);
    return sum * BLOOM_INTENSITY;
}

vec3 blend(vec3 a, vec3 b) {
    return 1.0 - (1.0 - a) * (1.0 - b);
}

void fragment() {
	mat2 rotation_matrix = mat2(vec2(cos(r), sin(r)), vec2(-sin(r), cos(r)));
	mat2 scale_matrix = mat2(vec2(1.0, 0.0),vec2(0.0, TEXTURE_PIXEL_SIZE.x/TEXTURE_PIXEL_SIZE.y));
	vec2 uv = (((UV * 2.0 - 1.0)*3.+1.0)/2.0+vec2(0.5))*scale_matrix;
	vec2 uv_normal = uv * rotation_matrix * inverse(scale_matrix) + vec2(0.5);
	uv = (uv * rotation_matrix + vec2(0.25)*vec2(offset)*rotation_matrix)*inverse(scale_matrix)+vec2(0.5);
	vec4 shadow = vec4(0);
	vec4 real = vec4(0);
	if(length(offset) >= 0.00001 && uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
		vec4 c = texture(TEXTURE, uv);
		shadow = vec4(0.1,0.1,0.1,c.a-0.6);
	}
	if(uv_normal.x >= 0.0 && uv_normal.x <= 1.0 && uv_normal.y >= 0.0 && uv_normal.y <= 1.0) {
		vec4 tx = texture(TEXTURE, uv_normal);
		if (length(tx) > 0.00){
		    vec3 result = gaussian(TEXTURE, uv_normal);

			vec4 bg = vec4(result, 1);

		    float gray = dot(bg.rgb, vec3(0.299, 0.587, 0.114));
		    bg = vec4(bg.rgb, gray);

			vec4 final = bg;

			final = bg + tx;

		    real = final;
			real.a = tx.a;
		} else real = vec4(0);
	}
	COLOR = mix(shadow,real,real.a);
	COLOR = COLOR * modulate;
}