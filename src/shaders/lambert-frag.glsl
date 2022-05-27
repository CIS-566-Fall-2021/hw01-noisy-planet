#version 300 es

// Original code by Adam Mally, additions by Nathan Devlin

precision highp float;

uniform vec4 u_LightPos;

in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col;


float smootherstep(float edge0, float edge1, float x)
{
    x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);

    return x * x * x * (x * (x * 6.0f - 15.0f) + 10.0f);
}


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


void main()
{
    // Material base color
    vec4 diffuseColor = vec4(1.0f, 0.0f, 0.0f, 1.0f);
    
    float radiusNoise = sqrt(fs_Pos[0] * fs_Pos[0] * 0.0694 + fs_Pos[2] * fs_Pos[2] * 0.0694);
    vec3 colorVal = fbm(fs_Pos[1] * 10.04923, radiusNoise, radiusNoise, 2);

    diffuseColor = vec4(vec3(colorVal[0] - 0.1f * colorVal[1], 
                             colorVal[0] - 0.3f * colorVal[2], 
                            colorVal[0] - 0.3f * (colorVal[1] + colorVal[2])), 1.0f);

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(u_LightPos));
    
    diffuseTerm = clamp(diffuseTerm, 0.0f, 1.0f);

    float ambientTerm = 0.1;

    float lightIntensity = diffuseTerm + ambientTerm;  

    // Compute final shaded color
    out_Col = vec4(diffuseColor.rgb * lightIntensity, 1.0f);
}

