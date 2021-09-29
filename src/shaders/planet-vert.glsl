#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform float u_Time;
uniform float u_CityThreshold;
uniform float u_OceanThreshold;

uniform vec2 u_MousePos;
uniform vec4 u_CameraPos;

uniform mat4 u_Model;       // The matrix that defines the transformation of the
// object we're rendering. In this assignment,
// this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
// This allows us to transform the object's normals properly
// if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
// We've written a static matrix for you to use for HW2,
// but in HW3 you'll have to generate one yourself

uniform mat4 u_ViewProjInv;    // The matrix that defines the camera's transformation.
// We've written a static matrix for you to use for HW2,
// but in HW3 you'll have to generate one yourself

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_WorldPos;
out vec4 fs_Pos;

out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_LightPos;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.

out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

out mat3 fs_TBN;

const vec4 lightPos = vec4(0.0, 5.0, 3.0, 1); //The position of our virtual light, which is used to compute the shading of
//the geometry in the fragment shader.


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


float squareWave(float x, float freq, float amplitude, float modVal) {
    return abs(mod(floor(x * freq), modVal) * amplitude);
}

float cubeWave(vec3 p, float freq, float amplitude, float freqJitter, float ampJitter, float modVal)
{
    vec3 floorP = floor(p);
    float jitter = hash3(floorP);
    float amp = amplitude + jitter * ampJitter;
    float f = freq + jitter * freqJitter;
    return squareWave(p.x, f, amp, modVal) * squareWave(p.y, f, amp, modVal) * squareWave(p.z, f, amp, modVal);
}


float getOffset(vec3 p)
{
    vec4 fbm = fbm3(p * 0.4, 4, 0.8f, 1.4f, 0.8f, 2.f);

    float fbm_norm = (fbm.x + 1.0) * 0.5;
    float height = 0.f;
    float offset = 0.f;
    float thresholds[5] = float[5](u_OceanThreshold - 0.6, u_OceanThreshold - 0.1, u_OceanThreshold, u_OceanThreshold + 1.0, u_OceanThreshold + 1.0);

    if(fbm_norm < thresholds[1]) {
        //  land
        vec4 fbm_land_biomes = fbm3(p * 0.3 + vec3(0.4, 0.1, -20.0), 3, 0.8f, 1.6f, 0.8f, 2.f);
        fbm_land_biomes.x = 0.5 + 0.5 * fbm_land_biomes.x;

        if(fbm_land_biomes.x < u_CityThreshold) {
            height =  0.12 * cubeWave(p.xyz + sin(p.xyz), 7.0, 0.9, 6.0, 0.2, 1.45);
            
            //city
        } else {
            //nature
            vec4 fbm_hills = fbm3(p * 0.9 + 0.5, 3, 0.8f, 1.6f, 0.8f, 2.f);
            fbm_hills.x = 0.5 + 0.5 * fbm_hills.x;
            height = fbm_hills.x * 0.3;
            
        }
        float pos = (fbm_norm - thresholds[0]) / (thresholds[2] - thresholds[0]);
        pos = clamp((pos - 0.5), 0.0, 1.0) / 0.5;
        height = mix(height, 0.0, pos);
        
    } else if (fbm_norm < thresholds[2]) {
        // beach
        float pos = (fbm_norm - thresholds[0]) / (thresholds[2] - thresholds[0]);
        height = 0.0;
    } else if (fbm_norm < thresholds[3]) {
        //water
        float pos = (fbm_norm - thresholds[2]) / (thresholds[3] - thresholds[2]);
        height = -0.06;
        vec3 freq = 2.0 * (p + vec3(abs(sin(u_Time * 0.001))));
        offset = 0.05 * fbm3(freq, 2, 0.8f, 1.6f, 0.3f, 2.f).x;
        freq = 3.0 * (p - vec3(abs(10.0 + cos(0.5 + u_Time * 0.0009))));
        offset += 0.05 * fbm3(freq, 2, 0.8f, 1.6f, 0.3f, 2.f).x;
    } else {
        // islands
        float pos = (fbm_norm - thresholds[3]) / (thresholds[4] - thresholds[3]);
        height = 0.01 * pos;
    }
    
    float polesize = 0.2;

//    if(abs(p.y) > 0.8)
//    {
//        float pole_closeness = (abs(p.y) - 0.8) / 0.2;
//        vec4 fbm_ice = fbm3(p * 0.4, 3, 0.8f, 1.6f, 0.8f, 2.f);
//        fbm_ice.x = (fbm_ice.x + 1.0) * 0.5;
//        return mix(height, fbm_ice.x * 0.3, pole_closeness * fbm_norm);
//    }
    
    return height - offset;
}

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    vec2 center_MousePos = 2.f * (u_MousePos - 0.5f);
    mat3 invTranspose = mat3(u_ModelInvTr);
    vec4 p = vec4(center_MousePos.xy, 1, 1) * abs(u_CameraPos.z);
    p = u_ViewProjInv * p;
    
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
    // Transform the geometry's normals by the inverse transpose of the
    // model matrix. This is necessary to ensure the normals remain
    // perpendicular to the surface after the surface is transformed by
    // the model matrix.
    
    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below
    
    float amp = 1.f - length(center_MousePos) + 1.f;
    amp = length(center_MousePos) + 1.f;
    vec2 dir = normalize(center_MousePos);
    vec3 camDir = normalize(u_CameraPos).xyz;
    vec3 perp_dir = cross(vec3(dir, 0), camDir);
    vec3 test = cross(vec3(0,0,1), vec3(0,1,0));
    float amt = dot(perp_dir.xy, modelposition.xy);
    vec2 center = center_MousePos;
    
    fs_Pos = modelposition;
    float height = getOffset(modelposition.xyz);

    float delta = 0.00001;
//    vec4 norm = vec4(getOffset(modelposition.xyz + vec3(delta,0.0,0.0)) - getOffset(modelposition.xyz + vec3(-delta,0.0,0.0)),
//    getOffset(modelposition.xyz + vec3(0.0,delta,0.0)) - getOffset(modelposition.xyz + vec3(0.0,-delta,0.0)), getOffset(modelposition.xyz + vec3(0.0,0.0,delta)) - getOffset(modelposition.xyz + vec3(0.0,0.0,-delta)), 0.0);
    
    
    vec3 tangent = normalize(cross(vec3(0,1,0),fs_Nor.xyz));
    vec3 bitangent = normalize(cross(fs_Nor.xyz, tangent));
    fs_TBN = mat3(tangent, bitangent, fs_Nor.xyz);

    // get points in delta direction
    vec3 p1 = modelposition.xyz + delta * tangent;
    vec3 p2 = modelposition.xyz + delta * bitangent;

    //estimate offset points at p1, p2
    vec3 v1 = getOffset(p1) * normalize(p1) + normalize(p1);
    vec3 v2 = getOffset(p2) * normalize(p2) + normalize(p2);
    
    //fs_Nor = vec4(fs_TBN *  norm.xyz, 1.0);
    fs_LightPos = lightPos;
    modelposition.xyz += height * fs_Nor.xyz;

    vec4 norm = vec4(0.0);
    norm.xyz = normalize(cross(v1 - modelposition.xyz, v2 - modelposition.xyz));
    
    fs_WorldPos = modelposition;
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
    
    //norm = normalize(norm + vec4(0.0,0.0,0.0,0.0));
    fs_Nor = norm;

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
    // used to render the final positions of the geometry's vertices
    
}
