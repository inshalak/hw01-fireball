#version 300 es

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time; // Time uniform for animation
uniform vec4 u_Eye; // UNIFORM EYE
uniform vec2 u_Mouse; // mouse


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

void main()
{

    // adding rim lighting
    // bad practice lol but i'm lazy so here is the camera pos directly
    // nvm changed this
    float dotVal = dot(normalize(fs_Nor.xyz), normalize(u_Eye.xyz - fs_Pos.xyz));
    vec4 diffuseColor = vec4(1., 1., 1., 1.);
    float rim = pow(1.0 - dotVal, 5.0); // Here 5.0 is just an example power value
    if(dotVal <= 0.4f) {
        diffuseColor = vec4(0.f, 0.f, 0.f, 1.f);
    }
    if (dotVal >= 0.3f  && dotVal <= 0.5f) {
       // diffuseColor = vec4(1.f, 0.f, 0.f, 1.f);
    }
    if (dotVal >= 0.5f  && dotVal <= 0.7f) {
      //  diffuseColor = vec4(1.f, 1.f, 0.f, 1.f);
    }

    out_Col =  vec4(1.f, 1.f, 0.f, 1.f) * diffuseColor;
}
