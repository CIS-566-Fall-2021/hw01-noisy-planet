uniform float u_ColorSeed;
uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform bool u_DeformTerrain;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec4 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_LightVec;
out vec4 fs_Col;

const vec4 lightPos = vec4(5, 5, 3, 1);

void main() {
    mat3 invTranspose = mat3(u_ModelInvTr);
    vec3 p = vs_Pos.xyz;
    vec3 normal = vs_Nor.xyz;
    fs_Pos = vec4(p, 1.f);

    if (u_DeformTerrain) {
        float mountain, forest, grass;
        int biome = getBiome(p, mountain, forest, grass);
        p = deformTerrain(p, biome);
    }

    fs_Nor = vec4(invTranspose * normal, 0);
    vec4 modelposition = u_Model * vec4(p, 1.f);
    fs_LightVec = lightPos - modelposition;
    gl_Position = u_ViewProj * modelposition;
}
