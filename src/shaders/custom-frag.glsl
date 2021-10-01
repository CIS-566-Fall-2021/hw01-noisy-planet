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

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float random3D(vec3 p) {
    return cos(float(u_Time) * 0.005) * sin(length(vec3(
                            dot(p, vec3(126.1, 316.8, 106.2)), 
                            dot(p, vec3(266.5, 186.3, 206.4)),
                            dot(p, vec3(166.4, 246.2, 126.5))
                          ) * 0.01 ));
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
    float i2 = mix(v3, v4, fractY);
    float i3 = mix(v5, v6, fractY);
    float i4 = mix(v7, v8, fractZ);
    float i5 = mix(v1, v3, fractZ);
    float i6 = mix(v2, v4, fractX);
    float i7 = mix(v5, v7, fractZ);
    float i8 = mix(v6, v8, fractX);

    float mix1 = mix(mix(i1, i2, fractZ), mix(i3, i4, fractX), fractY);
    float mix2 = mix(mix(i5, i6, fractX), mix(i7, i8, fractY), fractZ);
    float finalMix = mix(mix1, mix2, fractX);
    return finalMix;
}

float fbmNoise(float x, float y, float z)
{
    float total = 0.0;
    float persistence = 0.5;
    float frequency = 1.0;
    float amplitude = 2.0;
    int octaves = 5;

    for (int i = 1; i <= octaves; i++) {
        total += amplitude * interpolateNoise3D(frequency * x, frequency * y, frequency * z);
        frequency *= 3.0;
        amplitude *= persistence;
    }
    return total;
}

void main()
{
    float noiseValue = fbmNoise(fs_Pos.x, fs_Pos.y, fs_Pos.z);

    vec4 a = vec4(0.5, 0.5, 0.5, 1.0);
    vec4 b = vec4(0.5, 0.5, 0.5, 1.0);
    vec4 c = vec4(2.0, 1.0, 0.0, 1.0);
    vec4 d = vec4(0.5, 0.2, 0.25, 1.0);

    vec4 diffuseColor = a + b * cos(6.3 * (c * noiseValue + u_Color + d));

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.3, 1.0);

    float ambientTerm = 0.2;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.

    // Compute final shaded color
    //out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
    out_Col = vec4(1.0);
}

