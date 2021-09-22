#version 300 es

int N_OCTAVES = 4;

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform float u_Time;       // Incrementing value drives vertex translation

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;            // Position of each vertex

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

float cubicEase(float x)
{
    return x * x * (3.0 - 2.0 * x);
}

float noise3d(vec3 p)
{
    return fract(sin((dot(p, vec3(127.1,
                                  311.7,
                                  191.999)))) *         
                 43758.5453);
}

float interpNoise3D(vec3 p) {
    int intX = int(floor(p.x));
    float fractX = cubicEase(fract(p.x));
    int intY = int(floor(p.y));
    float fractY = cubicEase(fract(p.y));
    int intZ = int(floor(p.z));
    float fractZ = cubicEase(fract(p.z));

    float v1 = noise3d(vec3(intX, intY, intZ));
    float v2 = noise3d(vec3(intX + 1, intY, intZ));
    float v3 = noise3d(vec3(intX, intY + 1, intZ));
    float v4 = noise3d(vec3(intX + 1, intY + 1, intZ));

    float v5 = noise3d(vec3(intX, intY, intZ + 1));
    float v6 = noise3d(vec3(intX + 1, intY, intZ + 1));
    float v7 = noise3d(vec3(intX, intY + 1, intZ + 1));
    float v8 = noise3d(vec3(intX + 1, intY + 1, intZ + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    float iC1 = mix(i1, i2, fractY);
    float i3 = mix(v5, v6, fractX);
    float i4 = mix(v7, v8, fractX);
    float iC2 = mix(i3, i4, fractY);
    return mix(iC1, iC2, fractZ);
    return 1.0;
}

float sampleNoise(vec3 p)
{
    // can be expanded
    return interpNoise3D(p);
}

float fbm(vec3 p)
{
    float total = 0.0;
    float persistence = 1.0 / 2.0;

    // loop over number of octaves
    for (int i = 0; i < N_OCTAVES; i++)
    {
        float frequency = pow(2.0, float(i));
        float amplitude = pow(persistence, float(i));

        total += sampleNoise(p * frequency) * amplitude;
    }
    return total;
}

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    vec4 newPos = vs_Pos + 0.1 * sin(u_Time) * vec4(fbm(vs_Pos.xyz), fbm(vs_Pos.yzx), fbm(vs_Pos.zxy), 1.0);

    fs_Pos = vs_Pos;                        // Pass vertex positions to drive fragment shader noise

    vec4 modelposition = u_Model * newPos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
