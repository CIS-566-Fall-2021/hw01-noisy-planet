#version 300 es

precision highp float;

int N_OCTAVES = 5;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec4 u_Color2;
uniform float u_Time;
uniform float u_Foaminess;
uniform float u_Aridity;
uniform float u_Fauna;
uniform float u_Snowiness;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;
in vec4 fs_CameraPos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float cubicEase(float x)
{
    return x * x * (3.0 - 2.0 * x);
}

vec3 noise3d(vec3 p)
{
    return fract(sin(vec3(dot(p, vec3(127.1, 311.7, 191.999)),
                          dot(p, vec3(127.1, 311.7, 191.999)),
                          dot(p, vec3(127.1, 311.7, 191.999)))
                    ) * 43758.5453);
}

vec3 interpNoise3D(vec3 p) {
    int intX = int(floor(p.x));
    float fractX = cubicEase(fract(p.x));
    int intY = int(floor(p.y));
    float fractY = cubicEase(fract(p.y));
    int intZ = int(floor(p.z));
    float fractZ = cubicEase(fract(p.z));

    vec3 v1 = noise3d(vec3(intX, intY, intZ));
    vec3 v2 = noise3d(vec3(intX + 1, intY, intZ));
    vec3 v3 = noise3d(vec3(intX, intY + 1, intZ));
    vec3 v4 = noise3d(vec3(intX + 1, intY + 1, intZ));

    vec3 v5 = noise3d(vec3(intX, intY, intZ + 1));
    vec3 v6 = noise3d(vec3(intX + 1, intY, intZ + 1));
    vec3 v7 = noise3d(vec3(intX, intY + 1, intZ + 1));
    vec3 v8 = noise3d(vec3(intX + 1, intY + 1, intZ + 1));

    vec3 i1 = mix(v1, v2, fractX);
    vec3 i2 = mix(v3, v4, fractX);
    vec3 iC1 = mix(i1, i2, fractY);
    vec3 i3 = mix(v5, v6, fractX);
    vec3 i4 = mix(v7, v8, fractX);
    vec3 iC2 = mix(i3, i4, fractY);
    return mix(iC1, iC2, fractZ);
}

vec3 sampleNoise(vec3 p)
{
    // can be expanded
    return interpNoise3D(p);
}

vec3 fbm(vec3 p)
{
    vec3 total = vec3(0.0);
    float persistence = 1.0 / 2.0;

    // loop over number of octaves
    for (int i = 0; i < N_OCTAVES; i++)
    {
        float frequency = pow(2.0, float(i));
        float amplitude = pow(persistence, float(i));

        total += sampleNoise(p * frequency) * amplitude;
    }
    return total;
}

float getBias(float time, float bias)
{
  return (time / ((((1.0/bias) - 2.0)*(1.0 - time))+1.0));
}

float getGain(float time, float gain)
{
  if(time < 0.5)
    return getBias(time * 2.0,gain)/2.0;
  else
    return getBias(time * 2.0 - 1.0,1.0 - gain)/2.0 + 0.5;
}

vec3 rgb(vec3 c)
{
    return c / 255.0;
}

float sawtoothWave(float x, float freq, float amplitude)
{
    return (x * freq - floor(x * freq)) * amplitude;
}

// conditionals
float when_gt(float x, float y) {
  return max(sign(x - y), 0.0);
}

float when_lt(float x, float y) {
  return max(sign(y - x), 0.0);
}

float when_ge(float x, float y) {
  return 1.0 - when_lt(x, y);
}

float when_le(float x, float y) {
  return 1.0 - when_gt(x, y);
}

float and(float a, float b) {
  return a * b;
}

float transformPos(vec3 pos)
{
    vec3 noiseInput = 2.0 * pos;
    vec3 noise = clamp(fbm(noiseInput) / 2.0, 0.0, 1.0);
    return noise.x;
}

vec3 calculateDeform(vec3 pos)
{
    float deform = transformPos(pos);
    if (deform < 0.5)
    {
        deform = 0.4 + 0.1 * clamp(fbm(pos + sin(u_Time * 0.5)).x, 0.0, 1.0);
    }
    return pos + deform * normalize(pos);
}

void main()
{
    // calculate biomes
    vec3 water = rgb(vec3(20.0, 70.0, 110.0));
    vec3 foam = rgb(vec3(166.0, 171.0, 190.0));
    vec3 sand = rgb(vec3(140.0, 120.0, 50.0));
    vec3 vegetation = rgb(vec3(24.0, 88.0, 16.0));
    vec3 snow = rgb(vec3(240.0, 240.0, 240.0));

    float noise = transformPos(fs_Pos.xyz);

    noise = getGain(noise, 0.03);

    vec3 finalColor = vec3(0.0);
        
    float foaminess = 1.0 - u_Foaminess;
    float aridity = u_Aridity;
    float fauna = u_Fauna;
    float snowiness = u_Snowiness / 4.0;

    float planetSum = foaminess + aridity + fauna + snowiness;
    foaminess = foaminess / planetSum;
    aridity = aridity / planetSum + foaminess;
    fauna = fauna / planetSum + aridity;
    snowiness = snowiness / planetSum + fauna;

    // equivalent to conditionals below
    finalColor = mix(water, foam, getBias(noise / foaminess, 0.1)) * when_lt(noise, foaminess)
                 + mix(foam, sand, (noise - foaminess) / (aridity - foaminess)) * and(when_ge(noise, foaminess), when_lt(noise, aridity))
                 + mix(sand, vegetation, (noise - aridity) / (fauna - aridity)) * and(when_ge(noise, aridity), when_lt(noise, fauna))
                 + mix(vegetation, snow, (noise - fauna) / (1.0 - fauna)) * when_ge(noise, fauna);
    // if (noise < foaminess)
    // {
    //     finalColor = mix(water, foam, getBias(noise / foaminess, 0.1));
    // }
    // if (noise >= foaminess && noise < aridity)
    // {
    //     finalColor = mix(foam, sand, (noise - foaminess) / (aridity - foaminess));
    // }
    // if (noise >= aridity && noise < fauna)
    // {
    //     finalColor = mix(sand, vegetation, (noise - aridity) / (fauna - aridity));
    // }
    // if (noise >= fauna)
    // {
    //     finalColor = mix(vegetation, snow, (noise - fauna) / (1.0 - fauna));
    // }

    // calculate normal
    vec3 tangent = cross(vec3(0.0, 1.0, 0.0), fs_Nor.xyz);
    vec3 bitangent = cross(fs_Nor.xyz, tangent);
    float dx = 0.00001;

    vec3 p1 = calculateDeform(fs_Pos.xyz + dx * tangent);
    vec3 p2 = calculateDeform(fs_Pos.xyz + dx * bitangent);
    vec3 p3 = calculateDeform(fs_Pos.xyz - dx * tangent);
    vec3 p4 = calculateDeform(fs_Pos.xyz - dx * bitangent);
    vec3 newNormal = cross(p2 - p4, p1 - p3);
    newNormal = normalize(newNormal);

    // calculate lighting
    vec4 lightVec = fs_LightVec;

    float diffuseTerm = clamp(dot(vec4(newNormal, 0.0), normalize(lightVec)), 0.0, 1.0);

    float ambientTerm = 0.2;

    float lambert = diffuseTerm + ambientTerm;

    vec4 halfVec = (vec4(normalize(lightVec.xyz), lightVec.w) + vec4(normalize(fs_CameraPos.xyz), fs_CameraPos.w)) / 2.0; 
    float specular = pow(max(dot(halfVec, vec4(newNormal, 0.0)), 0.0), 32.0);
    float blinn = lambert + 0.75 * specular;

    // Compute final shaded color

    // lambert shading
    //out_Col = vec4(finalColor * lambert, 1.0);

    // blinn-phong shading
    out_Col = vec4(finalColor * blinn, 1.0);
}
