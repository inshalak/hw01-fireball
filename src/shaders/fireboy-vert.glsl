#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself
uniform float u_Time;
uniform float u_HairGrowth;
uniform float u_HairVolume;
uniform float u_HairTwisties;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.



// ROTATSHUNS
mat4 rotationMatrixY(float angle) {
    float s = sin(angle);
    float c = cos(angle);

    return mat4(
        c, 0.0, s, 0.0,
        0.0, 1.0, 0.0, 0.0,
        -s, 0.0, c, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 rotationMatrixZ(float angle) {
    float s = sin(angle);
    float c = cos(angle);

    return mat4(
        c, -s, 0.0, 0.0,
        s, c, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}


// TOOLBOXES
float square_wave(float x, float freq, float amplitude) {
    return abs(mod(floor(x * freq), 2.0) * amplitude);
}

float triangle_wave(float x, float freq, float amp) {
    return abs(mod((x*freq), amp) - (0.5 * amp ));
}

float bias(float b, float t) {
    return pow(t, log(b)/log(0.5));
}

float gain(float g, float t) {
    if (t < 0.5) 
        return (mod(bias(1.f - g , 2.0 *t), 2.0));
    else 
        return (1.f - bias(1.f -g, 2.0 - 2.0*t));
}

float sawtooth_wave(float x, float freq, float amplitude) {
    return (x * freq - floor(x*freq)) * amplitude;
}

float sine_wave(float x, float freq, float amplitude) {
    return sin(x * freq ) * amplitude;
}


// NOISE


float hash(float n) {
    return fract(sin(n) * 753.5453123);
}

float smoothInterpolate(float a, float b, float t) {
    float u = t * t * (3.0 - 2.0 * t);
    return mix(a, b, u);
}

float valueNoise1D(float x) {
    float i = floor(x);
    float f = fract(x);
    float a = hash(i);
    float b = hash(i + 1.0);
    return smoothInterpolate(a, b, f);
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

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    fs_Pos = vs_Pos;
    fs_Pos.xyz *= vec3(0.72, 0.85, 0.7);

    float freq = u_HairGrowth;
    float amplitude = u_HairVolume;

    // credit saksham for this idea!!!!!!
    float square = square_wave((fs_Pos.x - 0.5)* .5, freq * 0.5, amplitude * 0.05);
    float spikes = triangle_wave(fs_Pos.x + .1, freq, amplitude);
    spikes = mix(spikes, spikes * 1.5, ceil(square));

    if(fs_Pos.y > 0.0) {
        fs_Pos.y *= 0.83;
        fs_Pos.y = spikes;        
        fs_Pos.z = mix(fs_Pos.z, 0.0, bias(fs_Pos.y/spikes, 0.8));
        fs_Pos.z = mix(fs_Pos.z, bias(spikes, 0.8), 0.4);
        fs_Pos.x += sin(fs_Pos.y * u_HairTwisties + u_Time * 0.01f)/15.f;   
        fs_Pos.y /= 1.5;             
    }
    else {
        fs_Pos.y *= 1.2;
    }

    float randomNoise = valueNoise2D(vec2(fs_Pos.x, fs_Pos.y + u_Time * 0.1f)); 

    float upwardForce = 0.2;
    float detachmentThreshold = 0.6;

    if (fs_Pos.y >= 1.1 && fs_Pos.y <= 1.6) {
        float detachmentIntensity = upwardForce * (randomNoise - detachmentThreshold); 
        if (detachmentIntensity > 0.0) {
            fs_Pos.y += detachmentIntensity; // Only positive values will cause detachment
        fs_Pos.y += sin(u_Time * 0.5) * 0.01; 
        }
    }

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          
    vec4 modelposition = u_Model * vs_Pos; 

    fs_LightVec = lightPos - fs_Pos;
    gl_Position = u_ViewProj * fs_Pos;
}
