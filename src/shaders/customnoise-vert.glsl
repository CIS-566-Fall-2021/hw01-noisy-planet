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
out vec4 fs_CameraPos;

const vec4 lightPos = vec4(-5, -5, -5, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

float cubicEase(float x)
{
    return x * x * (3.0 - 2.0 * x);
}

vec3 noise3d(vec3 p)
{
    return fract(sin(vec3(dot(p, vec3(127.1, 311.7, 191.999)),
                          dot(p, vec3(127.1, 311.7, 191.999)),
                          dot(p, vec3(127.1, 311.7, 191.999)))
                    ) * 43758.5453);
}

vec3 interpNoise3D(vec3 p) {
    int intX = int(floor(p.x));
    float fractX = cubicEase(fract(p.x));
    int intY = int(floor(p.y));
    float fractY = cubicEase(fract(p.y));
    int intZ = int(floor(p.z));
    float fractZ = cubicEase(fract(p.z));

    vec3 v1 = noise3d(vec3(intX, intY, intZ));
    vec3 v2 = noise3d(vec3(intX + 1, intY, intZ));
    vec3 v3 = noise3d(vec3(intX, intY + 1, intZ));
    vec3 v4 = noise3d(vec3(intX + 1, intY + 1, intZ));

    vec3 v5 = noise3d(vec3(intX, intY, intZ + 1));
    vec3 v6 = noise3d(vec3(intX + 1, intY, intZ + 1));
    vec3 v7 = noise3d(vec3(intX, intY + 1, intZ + 1));
    vec3 v8 = noise3d(vec3(intX + 1, intY + 1, intZ + 1));

    vec3 i1 = mix(v1, v2, fractX);
    vec3 i2 = mix(v3, v4, fractX);
    vec3 iC1 = mix(i1, i2, fractY);
    vec3 i3 = mix(v5, v6, fractX);
    vec3 i4 = mix(v7, v8, fractX);
    vec3 iC2 = mix(i3, i4, fractY);
    return mix(iC1, iC2, fractZ);
}

vec3 sampleNoise(vec3 p)
{
    // can be expanded
    return interpNoise3D(p);
}

vec3 fbm(vec3 p)
{
    vec3 total = vec3(0.0);
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

float getBias(float time, float bias)
{
  return (time / ((((1.0/bias) - 2.0)*(1.0 - time))+1.0));
}

float getGain(float time, float gain)
{
  if(time < 0.5)
    return getBias(time * 2.0,gain)/2.0;
  else
    return getBias(time * 2.0 - 1.0,1.0 - gain)/2.0 + 0.5;
}

float sawtoothWave(float x, float freq, float amplitude)
{
    return (x * freq - floor(x * freq)) * amplitude;
}

vec4 calculateDeform(vec4 pos)
{
    vec3 noiseInput = 2.0 * pos.xyz;
    vec3 noise = clamp(fbm(noiseInput) / 2.0, 0.0, 1.0);
    if (noise.x < 0.5)
    {
        noise.x = 0.4 + 0.1 * clamp(fbm(pos.xyz + sin(u_Time)).x, 0.0, 1.0);
    }
    return pos + noise.x * vs_Nor;
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

    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_Pos = vs_Pos;

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    fs_CameraPos = inverse(u_ViewProj) * vec4(0.0,0.0,1.0,1.0);

    // custom code
    vec4 newModelPosition = calculateDeform(modelposition);

    fs_Pos = vs_Pos;

    gl_Position = u_ViewProj * newModelPosition;
    // custom code
}
