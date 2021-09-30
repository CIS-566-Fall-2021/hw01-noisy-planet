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
uniform vec4 u_Camera;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

vec3 noise3D(vec3 p) {
    float val1 = fract(sin((dot(p, vec3(127.1, 311.7, 191.999)))) * 43758.5453);

    float val2 = fract(sin((dot(p, vec3(191.999, 127.1, 311.7)))) * 3758.5453);

    float val3 = fract(sin((dot(p, vec3(311.7, 191.999, 127.1)))) * 758.5453);

    return vec3(val1, val2, val3);
}

vec3 interpNoise3D(float x, float y, float z) {
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
    int octaves = 6;

    for(int i = 1; i <= octaves; i++)
    {
        float freq = pow(2.f, float(i));
        float amp = pow(persistence, float(i));

        total += interpNoise3D(x * freq, y * freq, z * freq) * amp;
    }

    return total;
}

float bias(float time, float bias) {
    return (time / ((((1.0 / bias) - 2.0) * (1.0 - time)) + 1.0));
}

float gain(float time, float gain) {
    if (time < 0.5) {
        return bias(time * 2.0, gain) / 2.0;
    } else {
        return bias(time * 2.0 - 1.0, 1.0 - gain) / 2.0 + 0.5;
    }
}

vec3 rgb(float r, float g, float b) {
    return vec3(r / 255.f, g / 255.f, b / 255.f);
}

// Cosine palette variables
const vec3 a = vec3(1.0, 0.5, 0.5);
const vec3 b = vec3(0.5, 0.5, 0.5);
const vec3 c = vec3(1.0, 1.0, 1.0);
const vec3 d = vec3(0.0, 0.1, 0.2);

vec3 cosinePalette(float t) {
    return a + b * cos(6.2831 * (c * t + d));
}

vec4 when_eq(vec4 x, vec4 y) {
  return 1.0 - abs(sign(x - y));
}

vec4 when_neq(vec4 x, vec4 y) {
  return abs(sign(x - y));
}

vec4 when_gt(vec4 x, vec4 y) {
  return max(sign(x - y), 0.0);
}

float when_gt(float x, float y) {
  return max(sign(x - y), 0.0);
}

vec4 when_lt(vec4 x, vec4 y) {
  return max(sign(y - x), 0.0);
}

float when_lt(float x, float y) {
  return max(sign(y - x), 0.0);
}

vec4 when_ge(vec4 x, vec4 y) {
  return 1.0 - when_lt(x, y);
}

float when_ge(float x, float y) {
  return 1.0 - when_lt(x, y);
}

vec4 when_le(vec4 x, vec4 y) {
  return 1.0 - when_gt(x, y);
}

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // BEGIN TINKERING

        vec3 noiseInput = fs_Pos.xyz;
        // Adjust this to change continent size
        noiseInput *= 1.0f;

        // Animation!
        //noiseInput += float(u_Time) * 0.001;

        vec3 noise = fbm(noiseInput.x, noiseInput.y, noiseInput.z);

        vec3 water = rgb(80.f, 80.f, 180.f);
        vec3 sand = rgb(237.f, 234.f, 149.f);
        vec3 grass = rgb(73.f, 166.f, 63.f);
        vec3 mountain = rgb(130.f, 130.f, 130.f);
        vec3 snow = rgb(220.f, 220.f, 220.f);

        float t = noise.r;
        float t2 = gain(t, 0.02f);
        float t3 = bias(t, 0.2f);
        float t4 = bias(t, 0.9f);

        vec3 waterSand = mix(water, sand, t2);
        vec3 grassSand = mix(grass, sand, t3);
        vec3 mountainSnow = mix(mountain, snow, t4);

        vec3 resultColor = snow * when_ge(t2, 0.985f) +
                           mountainSnow * when_ge(t2, 0.978f) * when_lt(t2, 0.985f) +
                           mountain * when_ge(t2, 0.96f) * when_lt(t2, 0.978f) +
                           grass * when_ge(t2, 0.9f) * when_lt(t2, 0.96f) +
                           grassSand * when_ge(t2, 0.8f) * when_lt(t2, 0.9f) +
                           sand * when_ge(t2, 0.7f) * when_lt(t2, 0.8f) +
                           waterSand * when_lt(t2, 0.7f);

        // BLINN-PHONG CALCULATIONS //
        vec3 view = normalize(u_Camera.xyz - fs_Pos.xyz);
        vec3 lightDirection = normalize(fs_LightVec.xyz - fs_Pos.xyz);
        vec3 h = (lightDirection + view) / 2.f;
        float shininess = 5.f;
        vec3 specularColor = rgb(55.f, 55.f, 55.f);
        vec3 blinnPhong = max(pow(dot(h, fs_Nor.xyz), shininess), 0.f) * specularColor;
        // BLINN-PHONG CALCULATIONS END //

        out_Col = vec4(resultColor * lightIntensity + blinnPhong, diffuseColor.a);
}