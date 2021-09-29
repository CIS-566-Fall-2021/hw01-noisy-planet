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
uniform float u_CityThreshold;
// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_WorldPos;
in vec4 fs_LightPos;
in vec4 fs_Pos;
in mat3 fs_TBN;
uniform float u_OceanThreshold;

uniform vec2 u_MousePos;

uniform float u_Time;
out vec4 out_Col; // This is the final output color that you will see on your
// screen for the pixel that is currently being processed.

vec3 hash3Vec3(vec3 v) {
    return fract(sin(vec3(v.x * 10235.124, v.y * 38119.333333, v.z * 9199.2)));

}
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

vec3 randomColor(vec3 p, float freq)
{
    return hash3Vec3(floor(freq * p));
}

void main()
{
    
    // Material base color (before shading)
    vec4 diffuseColor = vec4(1.0,1.0,1.0,1.0);
    vec3 offset = vec3(20.f); //sin(u_Time * 0.002) * (1.f + 3.f * fs_Nor.xyz);
    vec4 fbm = fbm3(fs_Pos.xyz * 0.4, 4, 0.8f, 1.4f, 0.8f, 2.f);
    vec4 fbm_color = fbm3(fs_Pos.xyz * 2.0, 4, 0.8f, 1.9f, 0.8f, 2.f);
    fbm_color.x = clamp(0.5 * fbm_color.x + 0.5,0.0,1.0);
    vec4 norm = vec4(fs_TBN * fs_Nor.xyz, 0.0);
     norm = fs_Nor;
    float light_dist = 1.0 ;//distance(fs_LightPos, fs_WorldPos);
    float pointlightIntensity = 1.f / (light_dist * light_dist);
    float fbm_lerp = 0.04f;
    vec4 lightVec = normalize(fs_LightPos - fs_WorldPos);
    
    
//    diffuseColor.xyz = mix(u_SecondaryColor.xyz, u_Color.xyz, clamp((fbm_col.x + 1.0) * 0.5, 0.0, 1.f));

    vec3 pole1 = vec3(0.0, 0.5, 0.0);
    vec3 pole2 = vec3(0.0, -0.5, 0.0);

    float ks = 0.0;
    float kd = 1.0;

    float cosPow = 0.f;
    float fbm_norm = (fbm.x + 1.0) * 0.5;
    
    vec3 mountainColor = mix(vec3(0.8f, 0.8f, 0.75f), vec3(0.4f, 0.4f, 0.5f), fbm_color.x);
    vec3 beachColor = vec3(0.4f, 0.6f, 0.f);
    vec3 vegColor = vec3(0.73, 0.9f, 0.72f);
    vec3 seaColor = vec3(0.4f, 0.79f, 0.9f);
    vec3 snowColor = vec3(1.0f, 1.0f, 1.0f);

    // Colors of each biome.
    float thresholds[5] = float[5](u_OceanThreshold - 0.8, u_OceanThreshold - 0.1, u_OceanThreshold, u_OceanThreshold + 1.0, u_OceanThreshold + 1.0);

    float height = length(fs_WorldPos);
    

    if(fbm_norm < thresholds[1]) {
        // land
        float a = (fbm_norm - thresholds[0])
        / (thresholds[1] - thresholds[0]);
        vec4 streetColor = vec4(0.0,0.0,0.0,1.0);
        vec4 fbm_land_biomes = fbm3(fs_WorldPos.xyz * 0.3 + vec3(0.4, 0.1, -20.0), 3, 0.8f, 1.6f, 0.8f, 2.f);
        fbm_land_biomes.x = 0.5 + 0.5 * fbm_land_biomes.x;
        if(fbm_land_biomes.x < u_CityThreshold) {
            float city_col = cubeWave(fs_WorldPos.xyz + sin(fs_WorldPos.xyz), 7.0, 0.9, 6.0, 0.0, 1.45);
            float building_col = cubeWave(fs_WorldPos.xyz + sin(fs_WorldPos.xyz), 50.0, 5.0, 6.0, 1.0, 2.0);
            ks = 0.1;
            float lit = city_col > 0.1 ? 1.0 : 0.0;
            vec3 col = lit * building_col * city_col * randomColor(fs_WorldPos.xyz + sin(fs_WorldPos.xyz), 8.9) + vec3(0.2);
          //  vec3 randCol = city_col
            //city_col = city_col > 0.0 ? 1.0 : 0.0;
            diffuseColor.xyz = col;
            cosPow = 120.f;

            //city
        } else {
            //nature
            vec4 fbm_hills = fbm3(fs_Pos.xyz * 0.6 + 0.5, 3, 0.8f, 1.6f, 0.8f, 2.f);
            fbm_hills.x = 0.5 + 0.5 * fbm_hills.x;
            diffuseColor.xyz = vegColor;

            if(height > 1.44)
            {
                diffuseColor.xyz = mountainColor;
            }
            
        }
        
        if(fbm_norm > thresholds[1] - 0.01){
            diffuseColor.xyz = vec3(1.0);
        }
       // diffuseColor.xyz = mix(diffuseColor.xyz, beachColor.xyz, a);


    }
    
    if (fbm_norm >= thresholds[1] && fbm_norm < thresholds[2])
    {
        // beaches
        float a = (fbm_norm - thresholds[1])
        / (thresholds[2] - thresholds[1]);
        //a = getBias(a, 0.2);
        diffuseColor.xyz = mix(diffuseColor.xyz, beachColor, a + 0.4);
        //ks = 0.1f;
        kd = 0.7;
        
        // Snow
        float poledist = 1.f - (min(distance(fs_Pos.xyz, pole1), distance(fs_Pos.xyz, pole2)))
        + 0.05 * sin(fs_Pos.x) + 0.025 * sin(4.0 * fs_Pos.x);
        float mixterm = clamp(poledist * 2.0, 0.f, 1.f);
        diffuseColor.xyz = mix(diffuseColor.xyz, snowColor, mixterm);
        ks = mix(0.2f, 0.5f,  mixterm);
        kd = 0.6;
        cosPow = mix(3.f, 129.f,  mixterm);


    }
    
    if (fbm_norm >= thresholds[2] && fbm_norm < thresholds[3]) {
        // water
        float a = (fbm_norm - thresholds[2])
        / (thresholds[3] - thresholds[2]);
        a = clamp(a * 2.0, 0.0, 1.0);
        //a = clamp(a + 0.5, 0.0, 1.0);
        //a = getBias(a * 5.0, 0.99);
        diffuseColor.xyz = mix(diffuseColor.xyz, seaColor, a * 2.0);
        //diffuseColor.xyz = vec3(a);
        cosPow = 128.f;
        ks = 0.9f;
        //norm.xyz += 0.06 * sin(u_Time * 0.01) * norm.xyz;
    } else if (fbm_norm >= thresholds[3] && fbm_norm < thresholds[4]) {
        float a = (fbm_norm - thresholds[4])
        / (thresholds[4] - thresholds[3]);
        // polar
        diffuseColor.xyz = vec3(0.9f, 0.9f, 0.9f);
    }

    float diffuseTerm = pointlightIntensity * dot(normalize(norm), normalize(lightVec));
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);
    float ambientTerm = 0.3;
    vec4 viewVec = normalize(fs_WorldPos - u_CameraPos);
    vec4 h = normalize(lightVec - viewVec);
    
    float specularIntensity = pointlightIntensity * max(pow(max(dot(h, norm), 0.f), cosPow), 0.f);

    float lightIntensity = clamp((diffuseTerm * kd + ambientTerm + specularIntensity * ks), 0.f, 3.f);
    vec4 lightColor = vec4(255.f, 245.f, 228.f, 255.f) / 255.f;
    out_Col = vec4(diffuseColor.xyz * lightIntensity * lightColor.xyz, diffuseColor.a);
    //out_Col = vec4(norm.xyz, 1.0);
}
