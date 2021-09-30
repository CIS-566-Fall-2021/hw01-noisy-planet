#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform highp int u_Time;
uniform mat4 u_Model;

uniform vec4 u_Camera;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

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

vec3 vertexHeightNoise(vec3 position) {
    vec4 modelposition = u_Model * vec4(position, 1.0);   // Temporarily store the transformed vertex positions for use below

    vec3 noiseInput = modelposition.xyz;
    //noiseInput += getAnimation();

    vec3 noise = fbmNoise(noiseInput) * noiseInput;
    
    float noiseScale = noise.r;

    if (noise.r < 0.5) {
        noiseScale = 0.5;
    }


    vec3 offsetAmount = vec3(fs_Nor) * noiseScale;
    vec3 noisyModelPosition = modelposition.xyz + 0.075 * offsetAmount;
    return noisyModelPosition;
}

vec4 getNewNormal(vec4 norm) {
    float epsilon = 0.001;
    
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

    // return vec4(normalize(cross(normalize(noisyModelPosition - noiseTangent),
    //                                 normalize(noisyModelPosition - noiseBitangent))),
    //                                 0.0);

    vec3 tangent = normalize(cross(vec3(0.0, 1.0, 0.0), vec3(norm)));
    vec3 bitangent = cross(vec3(norm), tangent);

    vec3 point1 = vertexHeightNoise(fs_Pos.xyz + epsilon * tangent);
    vec3 point2 = vertexHeightNoise(fs_Pos.xyz + epsilon * bitangent);
    vec3 point3 = vertexHeightNoise(fs_Pos.xyz - epsilon * tangent);
    vec3 point4 = vertexHeightNoise(fs_Pos.xyz - epsilon * bitangent);

    // vec3 point1 = fs_Pos.xyz + epsilon * tangent + posX * norm.xyz;
    // vec3 point2 = fs_Pos.xyz + epsilon * bitangent + posY * norm.xyz;
    // vec3 point3 = fs_Pos.xyz - epsilon * tangent + negX * norm.xyz;
    // vec3 point4 = fs_Pos.xyz - epsilon * bitangent + negY * norm.xyz;
    //return vec4(point1, 1.0);
    return vec4(normalize(cross(normalize(point1 - point3), normalize(point2 - point4))), 1.0);
    //return vec4(normalize(cross(normalize(pos))))
} 

vec4 getFinalColor(vec3 noiseInput, vec4 diffuseColor, float diffuseTerm, float lightIntensity) {

    //noiseInput += getAnimation();
    vec3 noise = fbmNoise(noiseInput) * noiseInput;

    bool isBlinn = false;
    bool isLand = true;
    bool isDeepSea = false;
    bool isNight = false;
    
    //float noiseScale = oceanDeterminantNoise.r / 5.0;
    float noiseScale = noise.r;

    if (noiseScale < 0.7) {
        if (noiseScale < 0.01) {
            isDeepSea = true;
        }
        noiseScale = mix(0.4, noiseScale, 0.3);
        isBlinn = true;
        isLand = false;
    } 

    vec3 surfaceColor = vec3(noise);

    //DETERMINE IF ITS NIGHT

    //QUARTZ PALETTE
    vec3 ia = vec3(-0.152, 1.938, 1.448); 
    vec3 ib = vec3(-2.112, -1.442, -0.642); 
    vec3 ic = vec3(0.807, 0.879, 0.879); 
    vec3 id = vec3(-0.843, -0.550, -0.217);

    float t = noiseScale;

    float rt = getGain(t, 0.35);

    //SHORE COLOR
    vec3 shoreColor = convertRGB(196.0, 181.0, 255.0);

    //ICE color made from the quartz Palette
    vec3 iceColor = ia + ib * cos(6.3 * (ic * rt + id));

    vec3 belowWaterColor = mix(shoreColor, iceColor, 0.15);

    surfaceColor = belowWaterColor;

    if (isLand) {
        //LAND COLOR
        //vec3 waterColor = convertRGB(133.0, 249.0, 237.0);
        vec3 landColor = convertRGB(131.0, 68.0, 255.0);
        // noiseInput += sin(float(u_Time) * 0.001) * 0.7;
        // vec3 secondaryOffset = vec3(1,0,0) * noiseScale2;
        // surfaceColor = secondaryOffset;
        surfaceColor = mix(landColor, surfaceColor, 0.5);

        vec3 noiseInput2 = fs_Pos.xyz;
        //noiseInput2 += getAnimation();
        float noiseScale2 =  fbmNoise2(noiseInput2);
        if (noiseScale2 > 0.6) {
            surfaceColor += vec3(0.5,0.0,0.4);
        } 
    } else if (isDeepSea){
        vec3 deepSeaColor = convertRGB(0.0, 18.0, 14.0);

        vec3 noiseInput2 = fs_Pos.xyz;
        //noiseInput2 += getAnimation();
        float noiseScale2 = fbmNoise3(noiseInput2);
        if (noiseScale2 > 0.4) {
            surfaceColor = mix(deepSeaColor, surfaceColor, 0.9);
        }
    }

    vec4 newNorm = getNewNormal(fs_Nor);
    // out_Col = newNorm;
    // return newNorm;

    diffuseColor = vec4(surfaceColor, 1.0);

    if (!isBlinn) {
        return vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
    } else {
        //BLINN PHONG SHADING
        vec4 camVec = normalize(vec4(vec3(u_Camera) - vec3(fs_Pos), 0.0));
        vec4 lightVec = normalize(vec4(vec3(u_Camera) - vec3(fs_LightVec), 0.0));
        vec4 avg_h = vec4((camVec + lightVec) / 2.0);
        float specIntensity = (pow(max(dot(normalize(avg_h), normalize(fs_Nor)), 0.0), 20.0));
        
        // Compute final shaded colo2
        return vec4(diffuseColor.rgb * (lightIntensity + specIntensity), diffuseColor.a);
    } 

}

void main()
{
    // Material base color (before shading)
    vec4 diffuseColor = u_Color;

    vec4 newNorm = getNewNormal(fs_Nor);
    //out_Col = newNorm;
    //return;

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(newNorm), normalize(fs_LightVec));
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

    float ambientTerm = 0.2;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.

    //begin tinkering

    vec3 noiseInput = vec3(fs_Pos);

    //noiseInput += getAnimation();

    // vec3 noise = fbmNoise(noiseInput.x, noiseInput.y, noiseInput.z) * noiseInput;

    // //determine is ocean

    // //USES THE EXACT SAME DETEMRINANTS FORM VERTEX SHADER TO KNOW IF OCEAN
    // // vec4 modelposition = u_Model * fs_Pos;
    // // modelposition += getAnimation();
    // // vec3 oceanDeterminantNoise = fbmNoise(modelposition.x, modelposition.y, modelposition.z) * modelposition.xyz;

    // bool isBlinn = false;
    // bool isLand = true;
    // bool isDeepSea = false;
    // bool isNight = false;
    
    // //float noiseScale = oceanDeterminantNoise.r / 5.0;
    // float noiseScale = noise.r;

    // if (noiseScale < 0.7) {
    //     if (noiseScale < 0.01) {
    //         isDeepSea = true;
    //     }
    //     noiseScale = mix(0.4, noiseScale, 0.3);
    //     isBlinn = true;
    //     isLand = false;
    // } 
    // vec3 surfaceColor = vec3(noise);

    // //DETERMINE IF ITS NIGHT

    // //QUARTZ PALETTE
    // vec3 ia = vec3(-0.152, 1.938, 1.448); 
    // vec3 ib = vec3(-2.112, -1.442, -0.642); 
    // vec3 ic = vec3(0.807, 0.879, 0.879); 
    // vec3 id = vec3(-0.843, -0.550, -0.217);

    // float t = noiseScale;

    // float rt = getGain(t, 0.35);

    // //SHORE COLOR
    // vec3 shoreColor = convertRGB(196.0, 181.0, 255.0);

    // //ICE color made from the quartz Palette
    // vec3 iceColor = ia + ib * cos(6.3 * (ic * rt + id));

    // vec3 belowWaterColor = mix(shoreColor, iceColor, 0.15);

    // surfaceColor = belowWaterColor;

    // if (isLand) {
    //     //LAND COLOR
    //     //vec3 waterColor = convertRGB(133.0, 249.0, 237.0);
    //     vec3 landColor = convertRGB(131.0, 68.0, 255.0);
    //     // noiseInput += sin(float(u_Time) * 0.001) * 0.7;
    //     // vec3 secondaryOffset = vec3(1,0,0) * noiseScale2;
    //     // surfaceColor = secondaryOffset;
    //     surfaceColor = mix(landColor, surfaceColor, 0.5);

    //     vec3 noiseInput2 = fs_Pos.xyz;
    //     //noiseInput2 += getAnimation();
    //     float noiseScale2 =  fbmNoise2(noiseInput2);
    //     if (noiseScale2 > 0.6) {
    //         surfaceColor += vec3(0.5,0.0,0.4);
    //     } 
    // } else if (isDeepSea){
    //     vec3 deepSeaColor = convertRGB(0.0, 18.0, 14.0);

    //     vec3 noiseInput2 = fs_Pos.xyz;
    //     //noiseInput2 += getAnimation();
    //     float noiseScale2 = fbmNoise3(noiseInput2);
    //     if (noiseScale2 > 0.4) {
    //         surfaceColor = mix(deepSeaColor, surfaceColor, 0.9);
    //     }
    // }

    out_Col = getFinalColor(noiseInput, diffuseColor, diffuseTerm, lightIntensity);


    // LAMBERTIAN COLOR
    // if (!isBlinn) {
    //     out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
    // } else {
    //     //BLINN PHONG SHADING
    //     vec4 camVec = normalize(vec4(vec3(u_Camera) - vec3(fs_Pos), 0.0));
    //     vec4 lightVec = normalize(vec4(vec3(u_Camera) - vec3(fs_LightVec), 0.0));
    //     vec4 avg_h = vec4((camVec + lightVec) / 2.0);
    //     float specIntensity = (pow(max(dot(normalize(avg_h), normalize(fs_Nor)), 0.0), 20.0));
        
    //     // Compute final shaded colo2
    //     out_Col = vec4(diffuseColor.rgb * (lightIntensity + specIntensity), diffuseColor.a);
    // } 

    
}
