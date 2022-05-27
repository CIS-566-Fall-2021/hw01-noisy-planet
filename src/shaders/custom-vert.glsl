#version 300 es

// Written by Nathan Devlin, based on reference by Adam Mally

uniform mat4 u_Model;       // Model matrix

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.

uniform float u_Time;   // deci-seconds since 09/29/2021 7PM

uniform vec4 u_LightPos;    // Position of the light

uniform float u_bpm;       // User input Beats Per Minute Value

uniform float u_AltitudeMult;   // User input altitude multiplier

uniform float u_TerrainSeed;    // User input offset for terrain noise

in vec4 vs_Pos;             // The array of vertex positions passed to the shader
in vec4 vs_Nor;             // The array of vertex normals passed to the shader
in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. 
out vec4 fs_Col;            // The color of each vertex. 
out vec4 fs_Pos;            // The position of this fragment
out vec4 fs_UnalteredPos;   // The position this fragment had prior to modification in vertex shader


// Takes in spherical coordinates and returns a corresponding vec4 in cartesian coordinates
vec4 convertSphericalToCartesian(vec4 sphericalVecIn)
{
  float r = sphericalVecIn[0];
  float theta = sphericalVecIn[1];
  float phi = sphericalVecIn[2];

  float z = r * sin(phi) * cos(theta);
  float x = r * sin(phi) * sin(theta);
  float y = r * cos(phi);

  return vec4(x, y, z, 0.0);
}

// Takes in cartesian coordinates and returns a correpsonding vector in spherical coordinates
vec4 convertCartesianToSpherical(vec4 cartesianVecIn)
{
    float x = cartesianVecIn[0];
    float y = cartesianVecIn[1];
    float z = cartesianVecIn[2];

    float r = sqrt(x * x + y * y + z * z);

    float theta = atan(x, z);

    float phi = acos(y / sqrt(x * x + y * y + z * z));

    return vec4(r, theta, phi, 0.0f);
}

// Takes in a position vec3, returns a vec3, to be used below as a color
vec3 noise3D( vec3 p ) 
{
    float val1 = fract(sin((dot(p, vec3(127.1, 311.7, 191.999)))) * 43758.5453);

    float val2 = fract(sin((dot(p, vec3(191.999, 127.1, 311.7)))) * 3758.5453);

    float val3 = fract(sin((dot(p, vec3(311.7, 191.999, 127.1)))) * 758.5453);

    return vec3(val1, val2, val3);
}

// Interpolate in 3 dimensions
vec3 interpNoise3D(float x, float y, float z) 
{
    int intX = int(floor(x));
    float fractX = fract(x);
    int intY = int(floor(y));
    float fractY = fract(y);
    int intZ = int(floor(z));
    float fractZ = fract(z);

    vec3 v1 = noise3D(vec3(intX, intY, intZ));
    vec3 v2 = noise3D(vec3(intX + 1, intY, intZ));
    vec3 v3 = noise3D(vec3(intX, intY + 1, intZ));
    vec3 v4 = noise3D(vec3(intX + 1, intY + 1, intZ));

    vec3 v5 = noise3D(vec3(intX, intY, intZ + 1));
    vec3 v6 = noise3D(vec3(intX + 1, intY, intZ + 1));
    vec3 v7 = noise3D(vec3(intX, intY + 1, intZ + 1));
    vec3 v8 = noise3D(vec3(intX + 1, intY + 1, intZ + 1));

    vec3 i1 = mix(v1, v2, fractX);
    vec3 i2 = mix(v3, v4, fractX);

    vec3 i3 = mix(i1, i2, fractY);

    vec3 i4 = mix(v5, v6, fractX);
    vec3 i5 = mix(v7, v8, fractX);

    vec3 i6 = mix(i4, i5, fractY);

    vec3 i7 = mix(i3, i6, fractZ);

    return i7;
}

// 3D Fractal Brownian Motion
vec3 fbm(float x, float y, float z) 
{
    vec3 total = vec3(0.f, 0.f, 0.f);

    float persistence = 0.5f;
    int octaves = 8;

    for(int i = 1; i <= octaves; i++) 
    {
        float freq = pow(2.f, float(i));
        float amp = pow(persistence, float(i));

        total += interpNoise3D(x * freq, y * freq, z * freq) * amp;
    }
    
    return total;
}

// Takes in a position and an offset("seed"), returns a noise-based float
float calculateNoiseOffset(vec4 worldPos, float seed)
{
    // Add fbm noise
    vec3 fbmVal = fbm(worldPos[0] + seed, worldPos[1] + seed, worldPos[2] + seed);

    vec4 originalNormal = worldPos;
    originalNormal[3] = 0.0f;

    float multiplier = 0.001f;

    float height = fbmVal[0] * 1.25f;

    height *= (1.0f + abs(vs_Pos[1]) / 3.0f);

    height = (1.0f + height) * height - 1.0f;

    height /= 50.0f;
    float landMultiplier = (1.0f + height) * (1.0f + height) * (1.0f + height) * (1.0f + height) - 1.0f;
    float isLand = float(height > 0.0001f);
    multiplier += isLand * landMultiplier;

    return multiplier;
}

// Overload to allow single parameter calling of this function
float calculateNoiseOffset(vec4 worldPos)
{
    return calculateNoiseOffset(worldPos, 0.0f);
}

// Toolbox impulse function
float impulse(float k, float x)
{
    float h = k * x;
    return h * exp(1.0f - h);
}

// Re-aligns the normals to more accurately reflect the noisy terrain
void transformNormals()
{
    // Don't compute new normals near pole, since cant cross with
    // (0, 1, 0) near poles
    if(abs(vs_Nor[1]) < 0.999)
    {
        float delta = 0.001f;

        vec4 normalSpherical = convertCartesianToSpherical(vs_Nor);

        vec4 normalJitterSpherical1 = normalize(normalSpherical + vec4(0, delta, 0, 0));
        vec4 normalJitterSpherical2 = normalize(normalSpherical + vec4(0, -delta, 0, 0));

        vec4 normalJitterSpherical3 = normalize(normalSpherical + vec4(0, 0, delta, 0));
        vec4 normalJitterSpherical4 = normalize(normalSpherical + vec4(0, 0, -delta, 0));

        vec4 normalJitteredCartesian1 = convertSphericalToCartesian(normalJitterSpherical1);
        vec4 normalJitteredCartesian2 = convertSphericalToCartesian(normalJitterSpherical2);
        
        vec4 normalJitteredCartesian3 = convertSphericalToCartesian(normalJitterSpherical3);
        vec4 normalJitteredCartesian4 = convertSphericalToCartesian(normalJitterSpherical4);

        float thetaDiff = calculateNoiseOffset(normalJitteredCartesian1) - calculateNoiseOffset(normalJitteredCartesian2);
        
        float phiDiff = calculateNoiseOffset(normalJitteredCartesian3) - calculateNoiseOffset(normalJitteredCartesian4);

        float normalHighlightingMultiplier = 50.0f;

        thetaDiff *= normalHighlightingMultiplier;
        phiDiff *= normalHighlightingMultiplier;

        float z = sqrt(1.0 - thetaDiff * thetaDiff - phiDiff * phiDiff);

        vec4 localNormal = vec4(thetaDiff, phiDiff, z, 0);

        // Create tangent space to normal space matrix
        vec3 tangent = normalize(cross(vec3(0, 1, 0), vec3(vs_Nor)));
        vec3 bitangent = normalize(cross(vec3(vs_Nor), tangent));

        mat4 tangentToWorld = mat4(tangent.x, tangent.y, tangent.z, 0,
                                bitangent.x, bitangent.y, bitangent.z, 0,
                                vs_Nor.x, vs_Nor.y, vs_Nor.z, 0,
                                0,         0,           0,        1);
        
        vec4 transformedNormal = tangentToWorld * localNormal;

        transformedNormal = normalize(transformedNormal);

        /*
        float isNearPole = float(abs(vs_Nor[1]) > 0.8);

        transformedNormal += isNearPole * (vs_Nor - transformedNormal);    

        transformedNormal[3] = 0.0;   
        */

        fs_Nor = transformedNormal;
    }
    else
    {
        fs_Nor = vs_Nor;
    }
}


void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. 

    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = u_LightPos - modelposition;  // Compute the direction in which the light source lies

    vec4 worldPos = modelposition;

    vec4 originalNormal = worldPos;
    originalNormal[3] = 0.0f;

    float noiseMultiplier = calculateNoiseOffset(worldPos, u_TerrainSeed) * u_AltitudeMult;

    float extraOffset = -1.f;
    float amplitude = 1.0f;
    // frequency in Hz (cycles / second) - u_bpm is deci-seconds since 09/28/2021 7PM
    // Divided by 2 to have a high point on the beat
    float frequency = ((u_bpm * 10.0f) / 60.0f) / 2.0f; 

    float timeBPM_Multiplier = extraOffset + amplitude * 
        (sin(2.0f * 3.14159f * (frequency * fract(u_Time))) + 1.0f);

    clamp(timeBPM_Multiplier, 0.0f, 2.0f);

    timeBPM_Multiplier = pow(timeBPM_Multiplier, 4.0f);

    noiseMultiplier -= 0.005f;

    vec4 alteredPos = worldPos + originalNormal * (noiseMultiplier * (1.0f + timeBPM_Multiplier));
    
    gl_Position = u_ViewProj * alteredPos; // Final positions of the geometry's vertices

    fs_Pos = alteredPos;

    fs_UnalteredPos = worldPos;

    transformNormals();
}

