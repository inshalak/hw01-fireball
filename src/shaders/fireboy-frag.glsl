#version 300 es

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time; // Time uniform for animation
uniform vec4 u_Eye;
uniform float u_HairGrowth;


in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;
out vec4 out_Col;


float square_wave(float x, float freq, float amplitude) {
    return abs(mod(floor(x * freq), 2.0) * amplitude);
}

float triangle_wave(float x, float freq, float amp) {
    return abs(mod((x*freq), amp) - (0.5 * amp ));
}


float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float valueNoise2D(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + 
           (c - a) * u.y * (1.0 - u.x) + 
           (d - b) * u.x * u.y;
}

float fbm(vec3 p) {
    float f = 0.0;
    float w = 0.5;
    for (int i = 0; i < 4; i++) {
        f += w * valueNoise2D(p.xy);
        p *= 2.0;
        w *= 0.5;
    }
    return f;
}

float bias(float b, float t) {
    return pow(t, log(b)/log(0.5));
}

float snoise(vec3 uv, float res)
{
	const vec3 s = vec3(1e0, 1e2, 1e4);
	uv *= res;
	vec3 uv0 = floor(mod(uv, res))*s;
	vec3 uv1 = floor(mod(uv+vec3(1.), res))*s;
	vec3 f = fract(uv); f = f*f*(3.0-2.0*f);
	vec4 v = vec4(uv0.x+uv0.y+uv0.z, uv1.x+uv0.y+uv0.z, uv0.x+uv1.y+uv0.z, uv1.x+uv1.y+uv0.z);
	vec4 r = fract(sin(v*1e-3)*1e5);
	float r0 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
	r = fract(sin((v + uv1.z - uv0.z)*1e-3)*1e5);
	float r1 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
	return mix(r0, r1, f.z)*2.-1.;
}


void main() {
    // Define some parameters for the displacement effect
    float frequency = 4.0;
    float amplitude = 0.1;
    vec3 offset = vec3(0.0, 0.0, u_Time * 0.1); // Add time-based offset for animation
    
    // Calculate the displacement using snoise
    vec3 displacedPos = fs_Pos.xyz + snoise(fs_Pos.xyz * frequency + offset, 15.0) * amplitude;

    float gradientFactor = displacedPos.y; 
    vec3 gradientColor = mix(vec3(1.0, 1.0, 0.0), vec3(1.0, 1.0, 1.0), gradientFactor);

    // Calculate the color of the geometry based on the gradient and displacement
    vec3 color = gradientColor; // Start with the gradient color
    float displacementEffect = snoise(displacedPos, 15.0);
    
    // Add some color variations based on displacement
    color += vec3(0.2, 0.2, 0.2) * displacementEffect;
    
    // Apply rim lighting based on the dot product
    float dotVal = dot(normalize(fs_Nor.xyz), normalize(u_Eye.xyz - displacedPos));
    float rim = pow(1.0 - dotVal, 5.0);
    
    // Combine color with rim lighting
    color += vec3(0.5, 0.5, 0.5) * rim;

    if(dotVal <= 0.3f) {
         color = vec3(0.f, 0.f, 0.f);
    }
    
    // Output the final color
    out_Col = vec4(color, 1.0) * u_Color;
}



