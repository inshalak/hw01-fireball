#version 300 es

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform float u_Time;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec4 fs_Nor;
out vec4 fs_LightVec;
out vec4 fs_Col;
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1);

// Uniforms for the deformation


void main()
{
    fs_Col = vs_Col;
    fs_Pos = vs_Pos;
    fs_Pos.z /= 2.5f;

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);
    vec3 newPosition = vec3(vs_Pos);
    vec4 modelPosition = u_Model * vec4(newPosition, 1.0);
    fs_LightVec = lightPos - modelPosition;
    gl_Position = u_ViewProj * modelPosition;
}
