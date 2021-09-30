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

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_WorldPos;
in vec4 fs_LightPos;
in vec4 fs_Pos;

uniform vec2 u_MousePos;

uniform float u_Time;
out vec4 out_Col; // This is the final output color that you will see on your
// screen for the pixel that is currently being processed.


float hash3(vec3 v)
{
    return fract(sin(dot(v, vec3(24.51853, 4815.44774, 32555.33333))) * 3942185.3);
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

float getBias(float t, float bias)
{
    return t / ((((1.f / bias) - 2.f * (1.f - t)) + 1.f));
}

void main()
{
    // Material base color (before shading)
    vec4 diffuseColor = u_SecondaryColor;
    vec3 offset = vec3(20.f); //sin(u_Time * 0.002) * (1.f + 3.f * fs_Nor.xyz);
    vec4 fbm_col = fbm3(fs_Pos.xyz, 4, 0.8f, 1.6f, 0.8f, 2.f);
    vec4 fbm_norm = fbm3(fs_Pos.xyz, 6, 0.8f, 2.0f, 0.8f, 2.f);
    vec4 fbm_spec = fbm3(fs_Pos.xyz + offset, 6, 0.8f, 4.5f, 0.8f, 1.6f);
    
    fbm_spec.x = getBias(fbm_spec.x * 0.5f + 0.5f, 0.3f) * 1.4f + 0.2f;
    fbm_spec.x =clamp(fbm_spec.x, 0.f, 4.f);
    
    vec4 norm = normalize(vec4(fbm_norm.yzw, 0.f));
    float light_dist = distance(fs_LightPos, fs_WorldPos);
    float pointlightIntensity = 23.f / (light_dist * light_dist);
    float fbm_lerp = 0.04f;
    if(fbm_norm.x > 0.45)
        fbm_lerp = fbm_norm.x;
    norm = normalize(mix(fs_Nor, norm, fbm_lerp));
    
    vec4 lightVec = normalize(fs_LightPos - fs_WorldPos);
    diffuseColor.xyz = mix(u_SecondaryColor.xyz, u_Color.xyz, clamp((fbm_col.x + 1.0) * 0.5, 0.0, 1.f));
    float diffuseTerm = pointlightIntensity * dot(normalize(norm), normalize(lightVec));
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);
    float ambientTerm = 0.7;
    vec4 viewVec = normalize(fs_WorldPos - u_CameraPos);
    vec4 h = normalize(lightVec - viewVec);
    float specularIntensity = pointlightIntensity * max(pow(max(dot(h, norm), 0.f), 1024.f), 0.f);
    
    float lightIntensity = clamp((diffuseTerm + ambientTerm + specularIntensity * fbm_spec.x), 0.f, 3.f);
    vec4 lightColor = vec4(255.f, 245.f, 228.f, 255.f) / 255.f;
    out_Col = vec4(diffuseColor.xyz * lightIntensity * lightColor.xyz, diffuseColor.a);
    
}
