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

uniform highp int u_Time;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

//FBM NOISE FIRST VARIANT
float random3D(vec3 p) {
    return sin(length(vec3(fract(dot(p, vec3(161.1, 121.8, 160.2))), 
                            fract(dot(p, vec3(120.5, 161.3, 160.4))),
                            fract(dot(p, vec3(161.4, 161.2, 122.5))))) * 435.90906);
}

float interpolateNoise3D(float x, float y, float z)
{
    int intX = int(floor(x));
    float fractX = fract(x);
    int intY = int(floor(y));
    float fractY = fract(y);
    int intZ = int(floor(z));
    float fractZ = fract(z);

    float v1 = random3D(vec3(intX, intY, intZ));
    float v2 = random3D(vec3(intX + 1, intY, intZ));
    float v3 = random3D(vec3(intX, intY + 1, intZ));
    float v4 = random3D(vec3(intX + 1, intY + 1, intZ));

    float v5 = random3D(vec3(intX, intY, intZ + 1));
    float v6 = random3D(vec3(intX + 1, intY, intZ + 1));
    float v7 = random3D(vec3(intX, intY + 1, intZ + 1));
    float v8 = random3D(vec3(intX + 1, intY + 1, intZ + 1));


    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);

    //mix between i1 and i2
    float i3 = mix(i1, i2, fractY);

    float i4 = mix(v5, v6, fractX);
    float i5 = mix(v7, v8, fractX);

    //mix between i3 and i4
    float i6 = mix(i4, i5, fractY);

    //mix between i3 and i6
    float i7 = mix(i3, i6, fractZ);

    return i7;
}

float fbmNoise(vec3 v)
{
    float total = 0.0;
    float persistence = 0.3;
    float frequency = 4.0;
    float amplitude = 3.0;
    int octaves = 4;

    for (int i = 1; i <= octaves; i++) {
        total += amplitude * interpolateNoise3D(frequency * v.x, frequency * v.y, frequency * v.z);
        frequency *= 2.0;
        amplitude *= persistence;
    }
    return total;
}

//FBM NOISE 2ND VARIANT
float random3D2(vec3 p) {
    return sin(length(vec3(fract(dot(p, vec3(6.1, 2.8, 6.2))), 
                            fract(dot(p, vec3(2.5, 6.3, 6.4))),
                            fract(dot(p, vec3(6.4, 6.2, 2.5))))) * 45.90906);
}

float interpolateNoise3D2(float x, float y, float z)
{
    int intX = int(floor(x));
    float fractX = fract(x);
    int intY = int(floor(y));
    float fractY = fract(y);
    int intZ = int(floor(z));
    float fractZ = fract(z);

    float v1 = random3D2(vec3(intX, intY, intZ));
    float v2 = random3D2(vec3(intX + 1, intY, intZ));
    float v3 = random3D2(vec3(intX, intY + 1, intZ));
    float v4 = random3D2(vec3(intX + 1, intY + 1, intZ));

    float v5 = random3D2(vec3(intX, intY, intZ + 1));
    float v6 = random3D2(vec3(intX + 1, intY, intZ + 1));
    float v7 = random3D2(vec3(intX, intY + 1, intZ + 1));
    float v8 = random3D2(vec3(intX + 1, intY + 1, intZ + 1));


    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);

    //mix between i1 and i2
    float i3 = mix(i1, i2, fractY);

    float i4 = mix(v5, v6, fractX);
    float i5 = mix(v7, v8, fractX);

    //mix between i3 and i4
    float i6 = mix(i4, i5, fractY);

    //mix between i3 and i6
    float i7 = mix(i3, i6, fractZ);

    return i7;
}

float fbmNoise2(vec3 v) {
    float total = 0.0;
    float persistence = 0.5;
    float frequency = 2.0;
    float amplitude = 5.0;
    int octaves = 5;

    for (int i = 1; i <= octaves; i++) {
        total += amplitude * interpolateNoise3D2(frequency * v.x, frequency * v.y, frequency * v.z);
        frequency *= 3.6;
        amplitude *= persistence;
    }
    return total;
}

//FBM NOISE 3RD VARIANT

float random3D3(vec3 p) {
    return sin(length(vec3(fract(dot(p, vec3(36.1, 32.8, 36.2))), 
                            fract(dot(p, vec3(32.5, 36.3, 36.4))),
                            fract(dot(p, vec3(36.4, 36.2, 32.5))))) * 45.90906);
}

float interpolateNoise3D3(float x, float y, float z)
{
    int intX = int(floor(x));
    float fractX = fract(x);
    int intY = int(floor(y));
    float fractY = fract(y);
    int intZ = int(floor(z));
    float fractZ = fract(z);

    float v1 = random3D3(vec3(intX, intY, intZ));
    float v2 = random3D3(vec3(intX + 1, intY, intZ));
    float v3 = random3D3(vec3(intX, intY + 1, intZ));
    float v4 = random3D3(vec3(intX + 1, intY + 1, intZ));

    float v5 = random3D3(vec3(intX, intY, intZ + 1));
    float v6 = random3D3(vec3(intX + 1, intY, intZ + 1));
    float v7 = random3D3(vec3(intX, intY + 1, intZ + 1));
    float v8 = random3D3(vec3(intX + 1, intY + 1, intZ + 1));


    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);

    //mix between i1 and i2
    float i3 = mix(i1, i2, fractY);

    float i4 = mix(v5, v6, fractX);
    float i5 = mix(v7, v8, fractX);

    //mix between i3 and i4
    float i6 = mix(i4, i5, fractY);

    //mix between i3 and i6
    float i7 = mix(i3, i6, fractZ);

    return i7;
}

float fbmNoise3(vec3 v) {
    float total = 0.0;
    float persistence = 0.5;
    float frequency = 3.0;
    float amplitude = 4.0;
    int octaves = 4;

    for (int i = 1; i <= octaves; i++) {
        total += amplitude * interpolateNoise3D3(frequency * v.x, frequency * v.y, frequency * v.z);
        frequency *= 3.6;
        amplitude *= persistence;
    }
    return total;
}

//MORE FUNCTIONS
float getBias(float time, float bias)
{
  return (time / ((((1.0/bias) - 2.0)*(1.0 - time))+1.0));
}

float getGain(float time, float gain)
{
    if(time < 0.5) {
        return getBias(time * 2.0, gain) / 2.0;
    } else {
        return getBias(time * 2.0 - 1.0,1.0 - gain)/2.0 + 0.5;
    }
}


vec3 convertRGB(float r, float g, float b)
{
    return vec3(r,g,b) / 255.0;
}

float getAnimation() {
    return sin(float(u_Time) * 0.001) * 0.7;
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
    //begin tinkering

    vec3 noiseInput = modelposition.xyz;
    noiseInput += getAnimation();

    vec3 noise = fbmNoise(noiseInput) * noiseInput;
    
    float noiseScale = noise.r;

    bool isLand = false;
    if (noise.r < 0.5) {
        noiseScale = 0.5;
    } else {
        isLand = true;
    }


    vec3 offsetAmount = vec3(vs_Nor) * noiseScale;
    vec3 noisyModelPosition = modelposition.xyz + 0.1 * offsetAmount;

    if (isLand) {
        vec3 noiseInput2 = fs_Pos.xyz;
        noiseInput2 += getAnimation();
        float noiseScale2 =  fbmNoise2(noiseInput2);
        offsetAmount = vec3(vs_Nor) * noiseScale2;
        // if (noiseScale2 > 0.6) {
        //     noisyModelPosition += 0.075 * offsetAmount;
        // } 
    }

    //CALCULATE NEW NORMAL
    // float epsilon = 0.0001;
    
    // vec3 tangent = normalize(cross(vec3(0.0, 1.0, 0.0), vec3(vs_Nor)));

    // vec3 bitangent = normalize(cross(vec3(vs_Nor), tangent));

    // vec3 tangentPosition = vec3(vs_Pos) + (tangent * epsilon);
    // float fbmT = fbmNoise(tangentPosition);
    // vec3 tangentNorm = normalize(tangentPosition);
    // vec3 noiseTangent = tangentNorm * fbmT * tangentNorm;

    // vec3 bitangentPosition = vec3(vs_Pos) + (bitangent * epsilon);
    // float fbmB = fbmNoise(bitangentPosition);
    // vec3 bitangentNorm = normalize(bitangentPosition);
    // vec3 noiseBitangent = bitangentNorm * fbmB * bitangentNorm;

    // fs_Nor = vec4(normalize(cross(normalize(noisyModelPosition - noiseTangent),
    //                                 normalize(noisyModelPosition - noiseBitangent))),
    //                                 0.0);
    fs_Nor = vs_Nor;
    //fs_Nor = getNewNormal(vs_Nor);

    gl_Position = u_ViewProj * vec4(noisyModelPosition, 1.0);

    fs_Pos = vs_Pos;

}