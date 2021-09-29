#version 300 es

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


in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Pos;
out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

float scaleFactor(float y) {
    float scaleFactor = pow(y, 2.0) *.05;
    return scaleFactor;
}

void main()
{

mat3 invTranspose = mat3(u_ModelInvTr);
fs_Nor = normalize(vec4(invTranspose * vec3(vs_Nor), 0.f));     
fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

vec4 interp;
    // normalize position to get circle value
    vec4 normPos = vec4(vec3(normalize(vs_Pos)), 1.f);
if (sin(u_Time * .01) > 0.0) {
    if (vs_Pos[1] < 0.0) {
        interp = u_Model * mix(vs_Pos, 1.5 * normPos, cos(u_Time * 0.01));
    }
    else {
        interp = u_Model * mix(vs_Pos, .25 * normPos, cos(u_Time * 0.01));

    }
} else {
    if (vs_Pos[1] > 0.0) {
        interp = u_Model * mix(vs_Pos, .25 * normPos, cos(u_Time * 0.01));
    }
    else {
        interp = u_Model * mix(vs_Pos, 1.5 * normPos, cos(u_Time * 0.01));
    }
}

   // vec4 interp = u_Model * mix(vs_Pos, normPos, cos(u_Time * 0.01));
    fs_Pos = interp;
    gl_Position = u_ViewProj * interp;

    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
}
