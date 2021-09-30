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
uniform vec4 u_SecondaryColor; // The color with which to render this instance of geometry.

uniform vec4 u_CameraPos; // The color with which to render this instance of geometry.
uniform int u_NumericalNorm;
uniform vec3 u_Resolution;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_WorldPos;
in vec4 fs_LightPos;
in vec4 fs_Pos;
uniform float u_Clouds;
uniform mat4 u_ViewProjInv;    // The matrix that defines the camera's transformation.

uniform vec2 u_MousePos;

uniform float u_Time;
out vec4 out_Col; // This is the final output color that you will see on your
// screen for the pixel that is currently being processed.

const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;


float hash3(vec3 v)
{
    return fract(sin(dot(v, vec3(24.51853, 4815.44774, 32555.33333))) * 3942185.3);
}

vec2 sphereToUV(vec3 p) {
    //gives the horizontal component of the ray along the viewing frustum
    float phi = atan(p.z, p.x);
    //if(phi < 0.f) {
        //make sure phi is in range of 0 to 2pi since atan can be negative
        phi += TWO_PI;
    
    //gives the vertical component of the ray along the viewing frustum
    float theta = acos(p.y);

    //return the uv coord of the fragment in uv range
    return vec2(1.f - phi / TWO_PI, 1.f - theta / PI);
}

vec4 noise3(vec3 v)
{
    //Adapted from IQ: https://www.iquilezles.org/www/articles/morenoise/morenoise.htm
    vec3 intV = floor(v);
    vec3 fractV = fract(v);
    vec3 u = fractV*fractV*fractV*(fractV*(fractV*6.0-15.0)+10.0);
    vec3 du = 30.0*fractV*fractV*(fractV*(fractV-2.0)+1.0);
    
    float a = hash3( intV+vec3(0.f,0.f,0.f) );
    float b = hash3( intV+vec3(1.f,0.f,0.f) );
    float c = hash3( intV+vec3(0.f,1.f,0.f) );
    float d = hash3( intV+vec3(1.f,1.f,0.f) );
    float e = hash3( intV+vec3(0.f,0.f,1.f) );
    float f = hash3( intV+vec3(1.f,0.f,1.f) );
    float g = hash3( intV+vec3(0.f,1.f,1.f) );
    float h = hash3( intV+vec3(1.f,1.f,1.f) );
    
    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;
    
    
    vec3 dv = 2.0* du * vec3( k1 + k4*u.y + k6*u.z + k7*u.y*u.z,
                             k2 + k5*u.z + k4*u.x + k7*u.z*u.x,
                             k3 + k6*u.x + k5*u.y + k7*u.x*u.y);
    
    return vec4(-1.f+2.f*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z), dv);
}

vec4 fbm3(vec3 v, int octaves, float amp, float freq, float pers, float freq_power)
{
    vec2 center_MousePos = 2.f * (u_MousePos - 0.5f);
    float sum = 0.f;
    vec3 dv = vec3(0.f,0.f,0.f);
    float speed = 0.01f;
    for(int i = 0; i < octaves; ++i)
    {
        amp *= pers;
        freq *= freq_power;
        vec4 noise = noise3((v) * freq);
        sum += amp * noise.x;
        dv += amp * noise.yzw;
    }
    return vec4(sum, dv);
}

float getBias(float time, float bias)
{
    return (time / ((((1.0/bias) - 2.0)*(1.0 - time))+1.0));
}

vec4 skyCol(vec2 uv)
{
    return mix(vec4(0.0,0.0,0.1,1.0), vec4(0.15,0.39,0.54,1.0), getBias(uv.y, 0.2));
}

void main()
{
    vec2 ndc = (gl_FragCoord.xy / u_Resolution.xy) * 2.0 - 1.0; // -1 to 1 NDC
    if(length(ndc) < 0.2f) {
        out_Col = vec4(0.1, 0.1, 0.6, 0.0);
    } else {
        out_Col = vec4(ndc.x, ndc.y, 0.5, 1.0);

    }
    
    vec4 p = u_ViewProjInv * vec4(ndc, 1, 1); // get viewing frustum point
    vec2 uv = sphereToUV(normalize(p.xyz));
    vec4 fbm = fbm3(uv.xyy, 5, 0.8f, 2.2f, 0.8f, 2.f);

    out_Col = skyCol(uv);
    //out_Col.xy = u_Resolution.xy;

}
