#version 300 es

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec4 fs_Nor;
out vec4 fs_LightVec;
out vec4 fs_Col;
out vec4 fs_Pos;

uniform vec2 u_Mouse; // mouse

const vec4 lightPos = vec4(5, 5, 3, 1);

// Uniforms for the deformation
const float minIrisX = -.3;
const float maxIrisX = .31;
const float minIrisY = -0.4;
const float maxIrisY = -0.2;

void main()
{
    fs_Col = vs_Col;
    fs_Pos = vs_Pos;

    // Define the eye position as an offset from vs_Pos 
   vec2 eyeOffset = vec2(u_Mouse.x * 0.05, u_Mouse.y* 0.05);
    vec4 eyePosition = vs_Pos + vec4(eyeOffset, 0.0, 0.0);

    eyePosition.x = clamp(eyePosition.x, minIrisX, maxIrisX);
    eyePosition.y = clamp(eyePosition.y, minIrisY, maxIrisY);



    // Adjust the z-coordinate of the eye position

    // Calculate the normal, light vector, and final position as before
    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);
    vec3 newPosition = vec3(eyePosition);
    vec4 modelPosition = u_Model * vec4(newPosition, 1.0);
    fs_LightVec = lightPos - modelPosition;
    gl_Position = u_ViewProj * modelPosition;
}
