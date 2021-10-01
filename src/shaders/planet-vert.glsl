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
uniform float u_ContinentSize;
uniform float u_Temp;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

// Noise Functions==============================================================
vec3 earth_noise3D(vec3 p) {
    float val1 = fract(sin((dot(p, vec3(127.1, 311.7, 191.999)))) * 43758.5453);
    float val2 = fract(sin((dot(p, vec3(191.999, 127.1, 311.7)))) * 3758.5453);
    float val3 = fract(sin((dot(p, vec3(311.7, 191.999, 127.1)))) * 758.5453);

    return vec3(val1, val2, val3);
}

vec3 earth_interpolateNoise3D(float x, float y, float z) {
    int intX = int(floor(x));
    float fractX = fract(x);
    int intY = int(floor(y));
    float fractY = fract(y);
    int intZ = int(floor(z));
    float fractZ = fract(z);

    vec3 v1 = earth_noise3D(vec3(intX, intY, intZ));
    vec3 v2 = earth_noise3D(vec3(intX + 1, intY, intZ));
    vec3 v3 = earth_noise3D(vec3(intX, intY + 1, intZ));
    vec3 v4 = earth_noise3D(vec3(intX + 1, intY + 1, intZ));

    vec3 v5 = earth_noise3D(vec3(intX, intY, intZ + 1));
    vec3 v6 = earth_noise3D(vec3(intX + 1, intY, intZ + 1));
    vec3 v7 = earth_noise3D(vec3(intX, intY + 1, intZ + 1));
    vec3 v8 = earth_noise3D(vec3(intX + 1, intY + 1, intZ + 1));

    vec3 i1 = mix(v1, v2, fractX);
    vec3 i2 = mix(v3, v4, fractX);

    vec3 i3 = mix(i1, i2, fractY);

    vec3 i4 = mix(v5, v6, fractX);
    vec3 i5 = mix(v7, v8, fractX);

    vec3 i6 = mix(i4, i5, fractY);

    vec3 i7 = mix(i3, i6, fractZ);

    return i7;
}

vec3 earth_fbm(float x, float y, float z) {
    x *= 1.5f;
    y *= 1.5f;
    z *= 1.5f;
    vec3 total = vec3(0.f, 0.f, 0.f);
    float persistence = 0.5f;
    int octaves = 6;

    for(int i = 1; i <= octaves; i++) {
        float freq = pow(2.f, float(i));
        float amp = pow(persistence, float(i));

        total += earth_interpolateNoise3D(x * freq, y * freq, z * freq) * amp;
    }

    return total;
}

// Cliff Biome Functions==========================================================================
vec3 cliff_noise3D(vec3 p) {
    p *= 2.0f;
    float val1 = fract(sin((dot(p, vec3(12.167, 432.7, 131.999)))) * 3718.5457);
    float val2 = fract(sin((dot(p, vec3(141.999, 127.1, 311.7)))) * 1758.5457);
    float val3 = fract(sin((dot(p, vec3(387.7, 191.997, 37.1)))) * 7518.5451);

    return vec3(val1, val2, val3);
}

vec3 cliff_interpolateNoise3D(float x, float y, float z) {
    int intX = int(floor(x));
    float fractX = fract(x);
    int intY = int(floor(y));
    float fractY = fract(y);
    int intZ = int(floor(z));
    float fractZ = fract(z);

    vec3 v1 = cliff_noise3D(vec3(intX, intY, intZ));
    vec3 v2 = cliff_noise3D(vec3(intX + 1, intY, intZ));
    vec3 v3 = cliff_noise3D(vec3(intX, intY + 1, intZ));
    vec3 v4 = cliff_noise3D(vec3(intX + 1, intY + 1, intZ));

    vec3 v5 = cliff_noise3D(vec3(intX, intY, intZ + 1));
    vec3 v6 = cliff_noise3D(vec3(intX + 1, intY, intZ + 1));
    vec3 v7 = cliff_noise3D(vec3(intX, intY + 1, intZ + 1));
    vec3 v8 = cliff_noise3D(vec3(intX + 1, intY + 1, intZ + 1));

    vec3 i1 = mix(v1, v2, fractX);
    vec3 i2 = mix(v3, v4, fractX);

    vec3 i3 = mix(i1, i2, fractY);

    vec3 i4 = mix(v5, v6, fractX);
    vec3 i5 = mix(v7, v8, fractX);

    vec3 i6 = mix(i4, i5, fractY);

    vec3 i7 = mix(i3, i6, fractZ);

    return i7;
}

vec3 cliff_fbm(float x, float y, float z) {
    x *= 3.f;
    y *= 3.f;
    z *= 3.f;
    vec3 total = vec3(0.f, 0.f, 0.f);
    float persistence = 0.5f;
    int octaves = 8;

    for(int i = 1; i <= octaves; i++) {
        float freq = pow(2.f, float(i));
        float amp = pow(persistence, float(i));

        total += cliff_interpolateNoise3D(x * freq, y * freq, z * freq) * amp;
    }
    // total = smoothstep(0.55f, 0.65f, total) * 0.4 + smoothstep(0.5f, 0.6f, total) * 0.1 + smoothstep(0.6f, 0.7f, total) * 0.4;
    return total;
}
// End: Cliff Biome Functions==========================================================================
// Arctic Biome Functions===================================================================
vec3 arctic_fbm(float x, float y, float z) {
    vec3 total = vec3(0.f, 0.f, 0.f);
    float persistence = 0.5f;
    int octaves = 8;

    for(int i = 1; i <= octaves; i++) {
        float freq = pow(2.f, float(i));
        float amp = pow(persistence, float(i));

        total += cliff_interpolateNoise3D(x * freq, y * freq, z * freq) * amp;
    }
    total = smoothstep(0.1f, 0.25f, total) * 0.2 + smoothstep(0.28f, 0.35f, total) * 0.3 + smoothstep(0.4f, 0.55f, total) * 0.2 + smoothstep(0.5f, 0.65f, total) * 0.2 + smoothstep(0.7f, 0.8f, total) * 0.2+ smoothstep(0.83f, 0.95f, total) * 0.3;
    return total;
}
//End: Arctic Biome Functions=========================================================================
// Lava Biome Functions===================================================================
vec3 lava_fbm(float x, float y, float z) {
    x *= 2.0;
    y *= 2.0;
    z *= 2.0;
    vec3 total = vec3(0.f, 0.f, 0.f);
    float persistence = 0.5f;
    int octaves = 8;

    for(int i = 1; i <= octaves; i++) {
        float freq = pow(2.f, float(i));
        float amp = pow(persistence, float(i));

        total += cliff_interpolateNoise3D(x * freq, y * freq, z * freq) * amp;
    }
    total = smoothstep(0.1f, 0.25f, total) * 0.3 + smoothstep(0.4f, 0.55f, total) * 0.5 + smoothstep(0.6f, 0.8f, total) * 0.4;
    return total;
}
//End: Lava Biome Functions=========================================================================

float getBias(float time, float bias) {
    return (time / ((((1.0 / bias) - 2.0) * (1.0 - time)) + 1.0));
}

float getGain(float time, float gain) {
    if (time < 0.5) {
        return getBias(time * 2.0, gain) / 2.0;
    } else {
        return getBias(time * 2.0 - 1.0, 1.0 - gain) / 2.0 + 0.5;
    }
}

vec3 rgb(float r, float g, float b) {
    return vec3(r / 255.0, g / 255.0, b / 255.0);
}

vec3 getHeight(float x, float y, float z) {
    if (u_Temp == 1.0) {
        return arctic_fbm(x, y, z);//arctic_fbm(x, y, z);
    } else if (u_Temp == 2.0) {
        return earth_fbm(x, y, z);
    } else if (u_Temp == 3.0) {
        return cliff_fbm(x, y, z);
    } else {
        return lava_fbm(x, y, z);
    }
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

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices   

    // Begin Tinkering=======================
    vec3 noiseInput = modelposition.xyz;
    noiseInput *= u_ContinentSize;//1.0f;
    noiseInput += u_Time * 0.2;

    vec3 noise = vec3(0.0);
    noise = getHeight(noiseInput.x, noiseInput.y, noiseInput.z);

    float noiseScale = noise.r;
    if (u_Temp != 1.0) {
        if (noise.r < 0.5) {
            noiseScale = 0.5f;
        }
    }
    vec3 offset = vec3(vs_Nor) * noiseScale;
    vec3 noisyModelPosition = modelposition.xyz + offset;
    gl_Position = u_ViewProj * vec4(noisyModelPosition, 1.0);
    // End Tinkering==========================
    // Computer Normal========================
    float d = 0.001f;

    vec3 tangent = normalize(cross(vec3(0, 1, 0), vec3(fs_Nor)));
    vec3 bitangent = normalize(cross(vec3(fs_Nor), tangent));

    vec3 p1 = vs_Pos.xyz + (tangent * d);
    vec3 p2 = vs_Pos.xyz + (bitangent * d);
    vec3 new1 = (getHeight(p1.x, p1.y, p1.z) * normalize(p1)) + normalize(p1);
    vec3 new2 = (getHeight(p2.x, p2.y, p2.z) * normalize(p2)) + normalize(p2);

    vec3 newNor = normalize(cross((new1 - vs_Pos.xyz), (new2 - vs_Pos.xyz)));
    // fs_Nor = vec4(newNor, 0.0);
    // mat4 tbn = mat4(vec4(tangent, 0.0), vec4(bitangent, 0.0), vs_Nor, vec4(0.0, 0.0, 0.0, 1.0));
    // vec3 globalNor = tbn * localNor;
    // fs_Nor = globalNor;
    //========================================

    fs_Pos = vs_Pos;                                     
}
