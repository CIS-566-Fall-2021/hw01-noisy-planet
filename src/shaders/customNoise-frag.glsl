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
uniform int u_Time;
// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

vec3 random3 ( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1, 311.7, 288.99)),
                          dot(p,vec3(303.1, 183.3, 800.2)),
                          dot(p, vec3(420.69, 655.0,109.21))))
                 *43758.5453);
}

float surflet(vec3  p, vec3 gridPoint) {
    vec3 t2 = abs(p - gridPoint);
    vec3 t;
    t.x = 1.f - 6.f * pow(t2.x, 5.f) + 15.f * pow(t2.x, 4.f) - 10.f * pow(t2.x, 3.f);
    t.y = 1.f - 6.f * pow(t2.y, 5.f) + 15.f * pow(t2.y, 4.f) - 10.f * pow(t2.y, 3.f);
    t.z = 1.f - 6.f * pow(t2.z, 5.f) + 15.f * pow(t2.z, 4.f) - 10.f * pow(t2.z, 3.f);

    vec3 gradient = random3(gridPoint) * 2. - vec3(1.);

    vec3 diff = p - gridPoint;
    float height = dot(diff, gradient);
    return height * t.x * t.y * t.z;
}


float summedPerlin(vec4 p)
{
    float sum = 0.0;
    for(int dx = 0; dx <= 1; ++dx) {
        for (int dy = 0; dy <= 1; ++dy) {
           for (int dz = 0; dz <= 1; ++dz) {
               sum += surflet(vec3(p), floor(vec3(p)) + vec3(dx, dy, dz));
           } 
        }
    }
    
    return sum;
}

const vec4 a = vec4(255.0, 136.0, 128.0, 255.0) / 255.0;
const vec4 b = vec4(214, 92, 11, 255.0) / 255.0;
const vec4 c = vec4(232, 168, 65, 255.0) / 255.0;
const vec4 d = vec4(84, 186, 173, 255.0) / 255.0;

vec4 palette(float t) {
    return clamp(a + b * cos(2.0 * 3.14159 * (c * t + d)), 0.0, 1.0);
}

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color + palette(summedPerlin(fs_Pos * 3.0));

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);

        float ambientTerm = 0.2;

        float lightIntensity = max(diffuseTerm, 0.0);   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.
        lightIntensity += ambientTerm;
        // Compute final shaded color
        out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}
