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
uniform float u_ContinentSize;
uniform float u_Temp;
uniform float u_Shader;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

const vec4 lightPos = vec4(5, 5, 3, 1);

// Normal Earth Biome Functions==============================================================
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
// End: Normal Earth Biome Functions==============================================================
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
    int octaves = 6;

    for(int i = 1; i <= octaves; i++) {
        float freq = pow(2.f, float(i));
        float amp = pow(persistence, float(i));

        total += cliff_interpolateNoise3D(x * freq, y * freq, z * freq) * amp;
    }

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
    return total;
}
//End: Arctic Biome Functions=========================================================================
// Lava Biome Functions===============================================================================
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
    return total;
}
//End: Lava Biomr Function============================================================================
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

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
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
    noiseInput *= u_ContinentSize;//1.0f;
    noiseInput += u_Time * 0.2; 
    vec3 noise = vec3(0.0);
    if (u_Temp == 1.0) {
        noise = arctic_fbm(noiseInput.x, noiseInput.y, noiseInput.z);
    } else if (u_Temp == 2.0) {
        noise = earth_fbm(noiseInput.x, noiseInput.y, noiseInput.z);
    } else if (u_Temp == 3.0) {
        noise = cliff_fbm(noiseInput.x, noiseInput.y, noiseInput.z);
    } else {
        noise = lava_fbm(noiseInput.x, noiseInput.y, noiseInput.z);
    }

    vec3 surfaceColor = noise.rrr;

    vec3 color1 = rgb(40.0, 70.0, 125.0);
    vec3 color2 = rgb(40.0, 130.0, 20.0);
    float t = noise.r;

    //Earth Color=============================
    vec3 earth_a = vec3(0.53, 0.5, 0.89);
    vec3 earth_b = vec3(-0.6, 0.29, 0.55);
    vec3 earth_c = vec3(-0.3, 0.658, 0.8);
    vec3 earth_d = vec3(0.0, 0.33, 0.9);
    //========================================
    //Canyon Color============================
    vec3 canyon_a = vec3(0.64, 0.61, 0.71);
    vec3 canyon_b = vec3(0.37, 0.37, 0.5);
    vec3 canyon_c = vec3(1.0, 0.7, 0.4);
    vec3 canyon_d = vec3(0.0, 0.15, 0.31);
    //========================================
    //Arctic Color============================
    vec3 arctic_a = vec3(0.31, 0.76, 0.97);
    vec3 arctic_b = vec3(0.61, 0.57, 0.76);
    vec3 arctic_c = vec3(1.14, 1.15, 1.23);
    vec3 arctic_d = vec3(6.32, 6.31, 4.28);
    //========================================
    //Lava Color============================
    vec3 lava_a = vec3(0.55, 0.36, -0.02);
    vec3 lava_b = vec3(0.32, 0.21, 0.26);
    vec3 lava_c = vec3(0.63, 0.03, 0.75);
    vec3 lava_d = vec3(3.99, 5.63, 4.17);
    //========================================

    t = getGain(t, 0.2f);

    if (u_Temp == 1.0) {
        surfaceColor = palette(t, arctic_a, arctic_b, arctic_c, arctic_d);
    } else if (u_Temp == 2.0) {
        surfaceColor = palette(t, earth_a, earth_b, earth_c, earth_d);
    } else if (u_Temp == 3.0) {
        surfaceColor = palette(t, canyon_a, canyon_b, canyon_c, canyon_d);
    } else {
        surfaceColor = palette(t, lava_a, lava_b, lava_c, lava_d);
    }

    // vec3 surfaceColor = noise.rrr;
    out_Col = vec4(surfaceColor.xyz, 1.0);
    if (u_Shader == 0.0) { // lambert
        out_Col = vec4(surfaceColor.xyz * lightIntensity, 1.0);
    } else {               // blinn-phong
        vec4 avgViewLight = ((lightPos - fs_Pos) + fs_LightVec) / 2.0;
        float exp = 60.0f;
        float specularIntensity = max(pow(dot(normalize(avgViewLight), normalize(fs_Nor)), exp), 0.0);
        out_Col = vec4(surfaceColor.xyz * lightIntensity + specularIntensity, 1.0);
    }
}
