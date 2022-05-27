#version 300 es

// Written by Nathan Devlin, based on reference by Adam Mally

// 3D Fractal Brownian Motion Fragment Shader

precision highp float;

uniform vec4 u_OceanColor; // User input color for Ocean

uniform vec4 u_LightColor; // User input color for Light

uniform vec4 u_CameraPos;

uniform float u_AltitudeMult;

uniform float u_TerrainSeed;

// Interpolated values out of the rasterizer
in vec4 fs_Pos;
in vec4 fs_UnalteredPos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

out vec4 out_Col; 


// Takes in a position vec3, returns a vec3, to be used below as a color
vec3 noise3D( vec3 p ) 
{
    float val1 = fract(sin((dot(p, vec3(127.1, 311.7, 191.999)))) * 4.5453);

    float val2 = fract(sin((dot(p, vec3(191.999, 127.1, 311.7)))) * 3.5453);

    float val3 = fract(sin((dot(p, vec3(311.7, 191.999, 127.1)))) * 7.5453);

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
vec3 fbm(float x, float y, float z, int octaves) 
{
    vec3 total = vec3(0.f, 0.f, 0.f);

    float persistence = 0.5f;

    for(int i = 1; i <= octaves; i++) 
    {
        float freq = pow(3.f, float(i));
        float amp = pow(persistence, float(i));

        total += interpNoise3D(x * freq, y * freq, z * freq) * amp;
    }
    
    return total;
}

// Cosine color pallete
vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d)
{
    return a + b * cos( 6.28318 * (c * t + d));
}

// Toolbox Bias function
float bias(float b, float t)
{
    return pow(t, log(b) / log(0.5f));
}

// Toolbox Gain function
float gain(float g, float t)
{
    if(t < 0.5f)
    {
        return bias(1.0f - g, 2.0f * t) / 2.0f;
    }
    else
    {
        return 1.0f - bias(1.0f - g, 2.0f - 2.0f * t) / 2.0f;
    }
}


void main()
{
    // Material base color (before shading)
    vec4 diffuseColor = u_OceanColor;

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));

    diffuseTerm = clamp(diffuseTerm, 0.0f, 1.0f);

    float ambientTerm = 0.0;    // No ambient lighting

    float lightIntensity = diffuseTerm + ambientTerm;   

    float isIceCap = 0.0;
    float surfaceDifference = length(fs_Pos) - length(fs_UnalteredPos);
    float isLand = float(surfaceDifference > 0.0001f);


    // Note: Emperically tested if/else statements to test whether branching
    // was worth the extra computation. Have kept if/else statements that
    // improve performance
    if(lightIntensity >= 0.00001)
    {
        vec3 latitudeCol = vec3(2.5, 3.0, 3.0); // Extra-bright white for Arctic Tundra
        
        if(isLand > 0.0)
        {
            float modifiedSurDiff = pow(surfaceDifference, 0.65f) / u_AltitudeMult;

            float normalizedSurDiff = modifiedSurDiff * 4.0f * u_AltitudeMult;

            // Inputs for Cosine color pallete
            vec3 a = vec3(0.378, 1.008, 0.468);
            vec3 b = vec3(-0.762, 0.228, 0.718);
            vec3 c = vec3(0.78, 0.608, 0.698);
            vec3 d = vec3(0.588, 0.228, 0.178);

            vec4 landColor = vec4(vec3(palette(normalizedSurDiff, a, b, c, d)), 1.0f);
            
            float mult = (normalizedSurDiff);
            landColor += vec4(vec3(mult * mult * mult), 0.0f);

            diffuseColor = clamp(landColor, 0.0f, 2.0f);
        }
        
        float latitude = abs(fs_Pos[1]);

        float t = (latitude - 0.9f) / 0.11f;
        t = clamp(t, 0.0f, 1.0f);
        vec4 iceCapColor = mix(diffuseColor, vec4(latitudeCol, 1.0f), gain(0.999, t));   
        iceCapColor -= diffuseColor;     

        isIceCap = float(latitude > 0.9);
        diffuseColor += isIceCap * iceCapColor;
        diffuseColor[3] = 1.0f;

        
        // Lambert shading
        out_Col = vec4(diffuseColor.rgb * u_LightColor.rgb * lightIntensity, 1.0f);
        
        
        // Blinn Phong Shading only for ocean
        vec4 viewVec = u_CameraPos - fs_Pos;

        vec4 posToLight = fs_LightVec - fs_Pos;

        vec4 surfaceNorm = fs_Nor;

        vec4 H = (viewVec + posToLight) / (length(viewVec) + length(posToLight));

        float intensity =  10.0f; // Relative intensity of highlight

        float sharpness = 50.0f; // How sharp or spread out the highlight is

        float specularIntensity = intensity * max(pow(dot(H, surfaceNorm), sharpness), 0.0f);

        float finalIntensity = lightIntensity + specularIntensity;

        vec4 blinnPhong = vec4(diffuseColor.rgb * u_LightColor.rgb * finalIntensity, 1.0f);

        blinnPhong = clamp(blinnPhong, 0.0f, 1.0f);

        // Below is same as out_Col = surfaceDifference <= 0.0001f ? blinnPhong : out_Col
        // without the branching
        float isOcean = float(surfaceDifference <= 0.0001f);
        
        out_Col += isOcean * (blinnPhong - out_Col);
    }
    else
    {
        // Dark Side of the Planet
        vec3 val = fbm(fs_Pos[0] + u_TerrainSeed, fs_Pos[1] + u_TerrainSeed, fs_Pos[2] + u_TerrainSeed, 8);

        float avg = (val[0] + val[1] + val[2]) / 2.0f;

        avg = avg * avg * avg * avg * avg * avg * avg * avg * avg * avg;

        float nightTime = float(avg > 0.2f) * isLand * (1.0f - isIceCap) * float(lightIntensity <= 0.00001f);

        vec4 sunLit = vec4(diffuseColor.rgb * u_LightColor.rgb * lightIntensity, 1.0f);
        
        out_Col = sunLit;

        out_Col += nightTime * (vec4(avg * 2.0f, avg * 2.0f, 0.0f, 1.0f) - sunLit);
    }

    out_Col[3] = 1.0f;
    out_Col = clamp(out_Col, 0.0f, 1.0f);

}

