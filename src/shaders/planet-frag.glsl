#version 300 es

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec4 u_Color2;
uniform vec4 u_Color3;
uniform vec4 u_Color4;
uniform vec4 u_Color5;


// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

uniform float u_Time;
uniform float u_Speed;
uniform float u_Warming;
uniform vec4 u_CameraEye;


out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

vec3 random3( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1,311.7,457.3)),dot(p,vec3(269.5,183.3,271.5)), dot(p, vec3(119.3, 257.1, 361.7))))*43758.5453);
}


float WorleyNoise(vec2 uv)
{
    // Tile the space
    vec2 uvInt = floor(uv);
    vec2 uvFract = fract(uv);

    float minDist = 1.0; // Minimum distance initialized to max.

    // Search all neighboring cells and this cell for their point
    for(int y = -1; y <= 1; y++)
    {
        for(int x = -1; x <= 1; x++)
        {
            vec2 neighbor = vec2(float(x), float(y));

            // Random point inside current neighboring cell
            vec2 point = random2(uvInt + neighbor);

            // Animate the point
            //point = 0.5 + 0.5 * sin(iTime + 6.2831 * point); // 0 to 1 range

            // Compute the distance b/t the point and the fragment
            // Store the min dist thus far
            vec2 diff = neighbor + point - uvFract;
            float dist = length(diff);
            minDist = min(minDist, dist);
        }
    }
    return minDist;
}

float WorleyNoise(vec3 uv)
{
    // Tile the space
    vec3 uvInt = floor(uv);
    vec3 uvFract = fract(uv);

    float minDist = 1.0; // Minimum distance initialized to max.

    // Search all neighboring cells and this cell for their point
    for(int z=-1; z <=1; z++) {
    for(int y = -1; y <= 1; y++)
    {
        for(int x = -1; x <= 1; x++)
        {
            vec3 neighbor = vec3(float(x), float(y),float(z));

            // Random point inside current neighboring cell
            vec3 point = random3(uvInt + neighbor);

            // Animate the point
            //point = 0.5 + 0.5 * sin(iTime + 6.2831 * point); // 0 to 1 range

            // Compute the distance b/t the point and the fragment
            // Store the min dist thus far
            vec3 diff = neighbor + point - uvFract;
            float dist = length(diff);
            minDist = min(minDist, dist);
        }
    }
    }
    return minDist;
}

vec2 fbm(vec2 uv) {
    float amp = 0.5;
    float freq = 1.0;
    vec2 sum = vec2(0.0);
    float maxSum = 0.0;
    for(int i = 0; i < 4; i++) {
        sum += WorleyNoise(uv * freq) * amp;
        maxSum += amp;
        amp *= 0.5;
        freq *= 2.0;
    }
    return sum / maxSum;
}

vec3 fbm(vec3 uv) {
    float amp = 0.5;
    float freq = 1.0;
    vec3 sum = vec3(0.0);
    float maxSum = 0.0;
    for(int i = 0; i < 4; i++) {
        sum += WorleyNoise(uv * freq) * amp;
        maxSum += amp;
        amp *= 0.5;
        freq *= 2.0;
    }
    return sum / maxSum;
}

vec4 applyPalette(vec3 color) {
    float PI = 3.1415926535;
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(2.f, 1.f, 0.f);
    vec3 d = vec3(0.50, 0.20, 0.25);

    vec3 appliedCol = a + (b * cos(2.0 * PI * ((c * color) + d)));

    return vec4(appliedCol[0], appliedCol[1], appliedCol[2], 1.f);
}

float GetBias(float t, float bias)
{
  return (t / ((((1.0/bias) - 2.0)*(1.0 - t))+1.0));
}


float GetGain(float t, float gain)
{
  if(t < 0.5)
    return GetBias(t * 2.0,gain)/2.0;
  else
    return GetBias(t * 2.0 - 1.0,1.0 - gain)/2.0 + 0.5;
}
// from https://www.iquilezles.org/www/articles/functions/functions.htm
float expImpulse( float x, float k )
{
    float h = k*x;
    return h*exp(1.0-h);
}

float h(vec3 noiseinput) {
    noiseinput *= 1.75;

    // animate the noise
    noiseinput += .0025 * u_Time * u_Speed;
    vec3 offset = fbm(noiseinput);
    noiseinput = noiseinput + offset * 0.5;

    // Worley cells, invert for higher land masses
    float noiseScale = 1.0 - WorleyNoise(noiseinput);
    noiseScale += offset.r - 0.65f;
    
    noiseScale *= expImpulse(sin(u_Time * .005 * u_Warming) + 1.0, 1.0);
    return noiseScale;

}

float pcurve( float x, float a, float b )
{
    float k = pow(a+b,a+b)/(pow(a,a)*pow(b,b));
    return k*pow(x,a)*pow(1.0-x,b);
}

vec4 applyPalette(vec3 color, vec3 a, vec3 b, vec3 c, vec3 d) {
    float PI = 3.1415926535;

    vec3 appliedCol = a + (b * cos(2.0 * PI * ((c * color) + d)));

    return vec4(appliedCol[0], appliedCol[1], appliedCol[2], 1.f);
}

vec3 deform(vec3 p) {
    float noiseScale = h(p);
    // to make oceans not bumpy
    if (noiseScale < 0.5) {
        noiseScale = 0.5;
    }

    return (1.f + noiseScale) * p;
}

void main()
{
    vec3 noiseInput = vec3(fs_Pos[0], fs_Pos[1], fs_Pos[2]);
    // to add normals:
    vec3 dp = deform(noiseInput);
    float epsilon = .0001;
    vec3 noiseH = dp;

    vec3 tangent = normalize(cross(vec3(0.0, 1.0, 0.0), vec3(fs_Nor)));
    vec3 tangentPos = vec3(fs_Pos) + (tangent * epsilon);
    //float floatT = h(tangentPos);
    vec3 noiseT = deform(tangentPos);

    vec3 bitangent = normalize(cross(vec3(fs_Nor), tangent));
    vec3 bitangentPos = vec3(fs_Pos) + (bitangent * epsilon);
    //float floatB = h(bitangentPos);
    vec3 noiseB = deform(bitangentPos);

    vec4 newNormal = vec4( normalize(cross((noiseH - noiseT), (noiseH - noiseB))), 0.0);


    // Material base color (before shading)
    vec4 diffuseColor = vec4(0.f, 1.f, 0.f, 1.f);

    // Worley cells
    float h = 1.0 - h(noiseInput);

    // Output to screen, apply noise function everywhere
    diffuseColor = vec4(h);//applyPalette(vec3(h, h, h));

    bool isOcean = false;
    vec4 color1 = vec4(vec3(u_Color), 1.0); // ocean
    vec4 color2 = vec4(vec3(u_Color3), 1.0); // green
    vec4 color3 = vec4(vec3(u_Color4), 1.0); // gray
    vec4 color4 = vec4(vec3(u_Color5), 1.0); // snow
    vec4 color5 = vec4(vec3(u_Color2), 1.0); // sand
    vec4 color6 = vec4(.918, .494, .365, 1.0); // burnt sienna
    // if the noise is greater than threshold, use color 1, otherwise, use color 2
    float transition = 0.5;
    // seasonal transition
    float seasonTransition = pcurve(0.5 * sin(u_Time * .0015) + 0.5, 1.0, 2.0);
    vec4 baseBiomeColor = mix(color6, color2, seasonTransition);
    // ocean noise
    noiseInput += .0025 * u_Time;
    vec3 oceanNoise = fbm(vec3(noiseInput.x * 0.1, noiseInput.y, noiseInput.z * 0.1)); 
    float oceanH = 1.0 - oceanNoise.r + sin(noiseInput.y * 7.0) * 0.1;
    vec4 oceanBase = vec4(oceanH * 1.5 * vec3(color1), 1.0);
    if (h > .5f) {
        isOcean = true;
        // oceans        
        diffuseColor = oceanBase;
       
        // transition between ocean and beach biome
        if (h < .75f) {
            transition = GetGain(h, 0.35f);
            diffuseColor = mix(color5, oceanBase, transition);
        }
    } 
    if (h < 0.55) {
        // beaches  
        diffuseColor = color5;     
        
        // transition between beach and green biome
        if (h < 0.52) {
            transition = GetBias(h, 0.15f);
            diffuseColor = mix(color5, baseBiomeColor, transition);
        }
    }
    if (h < 0.5) { 

        // transition between green and mountain biome
        if (h < .37) {
            transition = GetGain(h, 0.35f);
            diffuseColor = mix(baseBiomeColor, color3, transition);
        }
    }
    if (h < 0.30) {
        diffuseColor = color3;     // mountain

        // transition between mountain and snow biome
        if(h < .20f) {
            transition = GetGain(h, 0.15f);
            diffuseColor = mix(color3, color4, transition);
        }
    }
    if (h < .15) { 
        diffuseColor = color4;     // snow
    }

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(newNormal), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        float spec;
        vec3 h_vec;

        if (isOcean) {   
            vec3 v_vec = normalize(vec3(u_CameraEye) - vec3(fs_Pos));
            vec3 l_vec = normalize(vec3(fs_LightVec) - vec3(fs_Pos));
            h_vec = (v_vec + l_vec) / 2.0;


            float shininess = 5.0;
            spec = 5.0 * max(pow(dot(normalize(h_vec), vec3(newNormal)), shininess), 0.0);

            lightIntensity += spec;
        }
        
        // Compute final shaded color
        out_Col = vec4(diffuseColor.rgb * lightIntensity, 1.0f);

}
