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
uniform float u_Time;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

// Noise FBM Functions==============================================================
vec3 noise3D(vec3 p) {
    float val1 = fract(sin((dot(p, vec3(378.1, 31.7, 137.999)))) * 38958.5453);
    float val2 = fract(sin((dot(p, vec3(129.967, 131.1, 37.7)))) * 3193.5453);
    float val3 = fract(sin((dot(p, vec3(171.7, 191.979, 127.1)))) * 758.5413);

    return vec3(val1, val2, val3);
}

vec3 interpolateNoise3D(float x, float y, float z) {
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

vec3 fbm(float x, float y, float z) {
    vec3 total = vec3(0.f, 0.f, 0.f);
    float persistence = 0.5f;
    int octaves = 7;

    for(int i = 1; i <= octaves; i++) {
        float freq = pow(2.f, float(i));
        float amp = pow(persistence, float(i));

        total += interpolateNoise3D(x * freq, y * freq, z * freq) * amp;
    }

    return total;
}

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

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d)
{
    return a + b * cos(6.28318*(c*t+d));
}

void main()
{
    // Material base color (before shading)
    vec4 diffuseColor = u_Color;

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    // diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

    float ambientTerm = 0.3;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.
    // Compute final shaded color
    // out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
    out_Col = vec4(diffuseColor.rrr * lightIntensity, diffuseColor.a);

    // Begin Tinkering====================
    vec3 noiseInput = fs_Pos.xyz;
    noiseInput *= 4.0f;
    // noiseInput += u_Time * 0.5; 
    // vec3 noise = earth_fbm(noiseInput.x, noiseInput.y, noiseInput.z);
    vec3 noise = fbm(noiseInput.x, noiseInput.y, noiseInput.z);
    // vec3 noise = vec3(noiseInput.x, perlinNoise3D(noiseInput), noiseInput.z);

    vec3 surfaceColor = noise.rrr;
    // if (noise.r > 0.5) {
    //     surfaceColor = rgb(255.0, 255.0, 255.0);
    // } else {
    //     surfaceColor = rgb(0.0, 0.0, 0.0);
    // }

    vec3 color1 = rgb(223.0, 255.0, 254.0);
    vec3 color2 = rgb(56.0, 102.0, 121.0);
    float t = noise.r;

    vec3 a = vec3(0.53, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 0.7, 0.4);
    vec3 d = vec3(0.0, 0.15, 0.2);

    t = getGain(t, 0.2f);

    surfaceColor = mix(color1, color2, t);
    // surfaceColor = palette(t, a, b, c, d);

    // vec3 surfaceColor = noise.rrr;
    out_Col = vec4(surfaceColor.xyz, 1.0);
    // out_Col = vec4(surfaceColor.xyz * lightIntensity, 1.0);
}
