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


float sphere(vec3 p, float s) {
    return length(p) - s;
}

float twistSphere( vec3 p )
{
    const float k = 4.f; // or some other amount
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz,p.y);
    return sphere(q, 1.0);
}

//taken from http://iquilezles.org/www/articles/smin/smin.htm
//intersect
float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return a > b ? a + h*h*0.25/k : b + h*h*0.25/k;
}

float differenceCSG(float d1, float d2) {
    return max(-d1, d2);
}

float map(vec3 p, int octaves)
{
    if(abs(p.x) > 20.0 || abs(p.z) > 20.0 || abs(p.y) > 20.0) {
        return 9e10;
    }
    
    float time = abs(1.9 * sin(0.0001 * u_Time));
    float dist = 0.f;
    dist = sphere(p, 1.5);
    //dist += 0.5 * sin(4.f*p.x)*sin(4.f*p.y)*sin(2.f*p.z);
    vec4 fbm = fbm3(p.xyz * 0.4f + time, octaves, 0.8f, 2.2f, 0.8f, 2.f);
    float norm_fbm = 0.5 * (fbm.x + 1.0);
    dist = norm_fbm;
    dist = clamp(dist, 0.0,1.0);
    //dist =sphere(p, 1.2);
    float cloudSize = u_Clouds * 0.4;
    float s = sphere(p, cloudSize) + 0.1 * norm_fbm;
    dist = max(s, dist);
    //dist = max(-fbm.x, dist);
    return dist;
}
vec4 raycast(vec4 p, vec4 skyCol)
{
    float cloudSize = u_Clouds * 0.4 + 0.1;

    float s = sphere(u_CameraPos.xyz, cloudSize);
    float occDist = cloudSize - 0.11;
    vec4 noise = fbm3(100.f * u_CameraPos.xyz, 3, 0.8f, 2.2f, 0.8f, 2.f);

    float t = s; //s - 0.02 * noise.x;
    vec4 rayDir = normalize(p - u_CameraPos);
    float tmax = 5.f;
    vec4 col = vec4(0.0);
    for(int i = 0; i < 70; ++i)
    {
        vec3 pos = u_CameraPos.xyz + rayDir.xyz * t;
        float density = map(pos, 4);
        float occ = sphere(pos, 1.11);
        if (-occ > density || occ < 0.0)
        {
            return vec4(0.0);
        }
        
        if (occ > occDist || col.a > 0.9 || density < 0.005)
            return col;

        float densMax = 0.16;
        if(density < densMax) {
            //if (dist < 0.0) {
            // if density isn't accumulating properly, it's prob bc steps are too big
            float invDensity = (1.0 - density / densMax);
            //col += vec4(1.0,1.0,1.0, 0.3 * (1.0 - density * 1.f));
            vec3 lerpCol = mix(u_Color.xyz, u_SecondaryColor.xyz, max(invDensity, 0.0));
            col += vec4(invDensity * lerpCol * (1.0 - col.a), invDensity);
            //}
        }

        
        t += max(t * 0.001 + density * 0.1, 0.015);//+ 0.02 * abs(noise.x), 0.02);//max(0.02, 0.19 * (0.01 * noise3(pos).x));
        
        if(t > tmax) {
            //return vec4(0.0,0.0,0.0,0.0);
        }

    }

    return vec4(0.0);
}

vec4 skyCol(vec2 uv)
{
    return mix(vec4(0.1,0.1,0.1,1.0), vec4(0.1,0.8,0.1,1.0), uv.y);
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
    out_Col = skyCol(p.xy);
    p *= 200.f;
    out_Col = vec4(0.0);
    out_Col = raycast(p, out_Col).xyzw;
    out_Col.xyz *= 1.4;
    //out_Col.xy = u_Resolution.xy;

}
