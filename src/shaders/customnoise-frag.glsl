#version 300 es

precision highp float;

int N_OCTAVES = 5;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec4 u_Color2;
uniform float u_Time;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

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
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;
        vec4 diffuseColor2 = u_Color2;

        float noise = fbm(fs_Pos.xyz * sin(u_Time) * tan(u_Time / 2.0));
        // Compute final shaded color
        out_Col = vec4(mix(diffuseColor.rgb, diffuseColor2.rgb, noise), diffuseColor.a);
}
