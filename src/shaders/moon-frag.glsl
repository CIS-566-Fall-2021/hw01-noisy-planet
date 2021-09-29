#version 300 es

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

uniform float u_Time;


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

void main()
{
    // Material base color (before shading)
    vec4 diffuseColor = vec4(0.f, 1.f, 0.f, 1.f);
    vec3 uv = 1.75f * vec3(fs_Pos[0], fs_Pos[1], fs_Pos[2]);

    // animate the noise 
    uv += u_Time * .0025;
    vec3 offset = fbm(uv);

    // Output to screen, apply noise function everywhere
    diffuseColor = vec4(vec3(offset.x * 1.65, offset.y * 1.15, offset.x) * 1.35, 1.0);//applyPalette(vec3(h, h, h));


        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);

}
