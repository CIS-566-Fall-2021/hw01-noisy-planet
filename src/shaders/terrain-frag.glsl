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
uniform highp float u_LightSpeed;

uniform highp float u_MountainHeight;

uniform vec4 u_CamPos;
// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;
in vec4 modelposition;
in float biome_type;
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

float GetBias(float time, float bias)
{
    // float time = (sin(float(u_Time) * 0.01) + 1.0) / 2.0;
  return (float(time) / ((((1.0/bias) - 2.0)*(1.0 - float(time)))+1.0));
}

float ease_in_quadratic(float t){
    return t*t;
}

float ease_in_out_quadratic(float t) {
    if (t<0.5)
        return ease_in_quadratic(t*2.0)/2.0;
    else  
        return 1.0 - ease_in_quadratic((1.0-t)*2.0);
}


// Takes in a position vec3, returns a vec3, to be used below as a color
vec3 noise3D( vec3 p ) 
{
    float val1 = fract(sin((dot(p, vec3(127.1, 311.7, 191.999)))) * 43758.5453);

    float val2 = fract(sin((dot(p, vec3(191.999, 127.1, 311.7)))) * 3758.5453);

    float val3 = fract(sin((dot(p, vec3(311.7, 191.999, 127.1)))) * 758.5453);

    return vec3(val1, val2, val3);
}


// Interpolate in 3 dimensions
vec3 interpNoise3D(float x, float y, float z) 
{
    int intX = int(floor(x));
    float fractX = fract(x);
    int intY = int(floor(y));
    float fractY = fract(y);
    int intZ = int(floor(z));
    float fractZ = fract(z);

    vec3 v1 = noise3D(vec3(intX, intY, intZ));
    vec3 v2 = noise3D(vec3(intX + 1, intY, intZ));
    vec3 v3 = noise3D(vec3(intX, intY + 1, intZ));
    vec3 v4 = noise3D(vec3(intX + 1, intY + 1, intZ));

    vec3 v5 = noise3D(vec3(intX, intY, intZ + 1));
    vec3 v6 = noise3D(vec3(intX + 1, intY, intZ + 1));
    vec3 v7 = noise3D(vec3(intX, intY + 1, intZ + 1));
    vec3 v8 = noise3D(vec3(intX + 1, intY + 1, intZ + 1));

    vec3 i1 = mix(v1, v2, fractX);
    vec3 i2 = mix(v3, v4, fractX);

    vec3 i3 = mix(i1, i2, fractY);

    vec3 i4 = mix(v5, v6, fractX);
    vec3 i5 = mix(v7, v8, fractX);

    vec3 i6 = mix(i4, i5, fractY);

    vec3 i7 = mix(i3, i6, fractZ);

    return i7;
}


// 3D Fractal Brownian Motion
vec3 fbm3D(float x, float y, float z) 
{
    vec3 total = vec3(0.f, 0.f, 0.f);

    float persistence = 0.5f;
    int octaves = 6;

    for(int i = 1; i <= octaves; i++) 
    {
        float freq = pow(2.f, float(i));
        float amp = pow(persistence, float(i));

        total += interpNoise3D(x * freq, y * freq, z * freq) * amp;
    }
    
    return total;
}

// FBM returns a flaot
float random1( vec3 p ) {
  return fract(sin((dot(p, vec3(127.1,
  311.7,
  191.999)))) *
  18.5453);
}


float smootherStep(float a, float b, float t) {
    t = t*t*t*(t*(t*6.0 - 15.0) + 10.0);
    return mix(a, b, t);
}

float interpNoise(float x, float y, float z) {
  x *= 2.;
  y *= 2.;
  z *= 2.;
  float intX = floor(x);
  float fractX = fract(x);
  float intY = floor(y);
  float fractY = fract(y);
  float intZ = floor(z);
  float fractZ = fract(z);
  float v1 = random1(vec3(intX, intY, intZ));
  float v2 = random1(vec3(intX + 1., intY, intZ));
  float v3 = random1(vec3(intX, intY + 1., intZ));
  float v4 = random1(vec3(intX + 1., intY + 1., intZ));

  float v5 = random1(vec3(intX, intY, intZ + 1.));
  float v6 = random1(vec3(intX + 1., intY, intZ + 1.));
  float v7 = random1(vec3(intX, intY + 1., intZ + 1.));
  float v8 = random1(vec3(intX + 1., intY + 1., intZ + 1.));

  float i1 = smootherStep(v1, v2, fractX);
  float i2 = smootherStep(v3, v4, fractX);
  float result1 = smootherStep(i1, i2, fractY);
  float i3 = smootherStep(v5, v6, fractX);
  float i4 = smootherStep(v7, v8, fractX);
  float result2 = smootherStep(i3, i4, fractY);
  return smootherStep(result1, result2, fractZ);
}

float fbm(float x, float y, float z, float octaves) {
  float total = 0.;
  float persistence = 0.5f;
  for(float i = 1.; i <= octaves; i++) {
    float freq = pow(2., i);
    float amp = pow(persistence, i);
    total += interpNoise(x * freq, y * freq, z * freq) * amp;
  }
  return total;
}

float worley(vec3 p) {
  vec3 pInt = floor(p);
  vec3 pFract = fract(p);
  float minDist = 1.0;
  for (int x = -1; x <= 1; x++) {
    for (int y = -1; y <= 1; y++) {
      for (int z = -1; z <= 1; z++) {
        vec3 neighbor = vec3(float(x), float(y), float(z));
        vec3 voronoi = random3(pInt + neighbor);
        //voronoi = 0.5 + 0.5 * sin(0.1 * float(u_Time) + 13.2831 * voronoi);
        vec3 diff = neighbor + voronoi - pFract;
        float dist = length(diff);
        minDist = min(minDist, dist);
      }
    }
  }
  return 1.0 - minDist;
}


float GetGain(float time, float gain)
{
  if(time < 0.5)
    return GetBias(time * 2.0,gain)/2.0;
  else
    return GetBias(time * 2.0 - 1.0,1.0 - gain)/2.0 + 0.5;
}

vec3 rgb(float r, float g, float b) {
    return vec3(r / 255.0, g / 255.0, b / 255.0);
}


vec3 waterSlime() {
    float f = fbm(fs_Pos.x, fs_Pos.y, fs_Pos.z, 6.);
    vec4 f2 =  fs_Pos + f; 
    f = fbm(f2.x, f2.y  + .008*float(u_Time), f2.z, 6.);
    vec3 a = vec3(0.35, 1.84, 0.35);
    vec3 b = vec3(0.4 , -0.41, 0.5);
    vec3 c = vec3(-0.46 , 0.333, 0.5);
    vec3 d = vec3(0. , 0.66, 0.5);
    vec3 color = a + b * cos(6.28 * (f * c + d));
    return color;
}

vec3 grassPurple() {

    float f = fbm(fs_Pos.x*1.5, fs_Pos.y*1.5, fs_Pos.z*1.5, 16.);
    vec3 a = vec3(0.6, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.66, 0.5);
    vec3 c = vec3(0.1, 0.66, 0.5);
    vec3 d = vec3(-0.34, 0.06, 0.5);
    vec3 color = a + b * cos(6.28 * (f * c + d));
    return color;
}


vec3 desertPink() {

    float f = fbm(fs_Pos.x * 2., fs_Pos.y * 2., fs_Pos.z * 2., 16.);
    vec3 a = vec3(1.13, 0.4, 0.56);
    vec3 b = vec3(0.21, 0.27, 0.19);
    vec3 c = vec3(1.0, 0.7, 0.8);
    vec3 d = vec3(1.8, 3.3, 4.3);
    vec3 color = a + b * cos(6.28 * (f * c + d));  
    return color;
}


vec3 mountainLilac() {

    float f = fbm(fs_Pos.x * 2., fs_Pos.y * 2., fs_Pos.z * 2., 16.);
    vec3 a = vec3(0.68, .66, .6);
    vec3 b = vec3(0.250);
    vec3 c = vec3(1.000);
    vec3 d = vec3(0);
    vec3 color = a + b * cos(6.28 * (f * c + d));  
    return color;
}

vec3 iceBlue() {

    float f = fbm(fs_Pos.x * 2., fs_Pos.y * 2., fs_Pos.z * 2., 16.);
    vec3 a = vec3(0.11, 1.07, 1.09);
    vec3 b = vec3(0.92, 0.13, 0.04);
    vec3 c = vec3(0.11, 0.30, 0.24);
    vec3 d = vec3(3.0, 5.28, 2.69);
    vec3 color = a + b * cos(6.28 * (f * c + d));  
    return color;
}

void main()
{

    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);
        float ambientTerm = 0.3;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.
                                                            
        // Compute final shaded color

        // TINKERING

        // palette
        vec3 grassPurple = grassPurple();
        vec3 mountainLilac = mountainLilac();
        vec3 iceBlue = iceBlue();
        vec3 desertPink = desertPink();
        vec3 waterSlime = waterSlime();

        vec3 color;
        if (biome_type <= 0.0) { // water
            color = waterSlime;
        } else if (biome_type <= 1.0) { // grass
            color = mix(waterSlime, grassPurple, 0.9);
        } else if (biome_type <= 2.0) { // desert
            color = mix(grassPurple, desertPink, 0.3);
        } else if (biome_type <= 3.0) { // mountain
            color = mix(desertPink, mountainLilac, 0.3);
        } else if (biome_type <= 4.0){ // ice
            color = mix(mountainLilac, iceBlue, 0.99);
        } else {
            color = mountainLilac;
        }


        vec4 view = normalize(u_CamPos - fs_Pos);
        vec4 H = normalize(view + normalize(fs_LightVec));
        vec3 specularIntensity = pow(max(dot(H, normalize(fs_Nor)), 0.), 50.) * rgb(240., 243., 220.);

        out_Col = vec4(color * lightIntensity + specularIntensity, 1.0);
}


// Notes From Lab
// Start with a fbm noise; threshold between white and black to get islands?
// TRY using gain and bias to soften the edges
/*
  
    vec3noiseinput = fs_Pos.xyz;
    noiseInput *= 1.0f;
    noiseINput += u_Time *0.005;

    vec3 noise = fbm();
    vec3 surface colour = noise.rrr;

    vec3 colour1 = rgb(white);
    vec3 colour2 = rgb(black);
    float t = noise.r;
    t = GetGain(t, 0.5f);
    surfaceColour = mix(colour1, colour2, t);
    out_colour = vec4(surface.xyz, 1.0);

    Put the fbm into the vertex shader; to transform the vertices
    Use modelposition in the fbm function.
    
    in vertex shader: 

    vec3 noiseScaled = noise.r;
    // clamped to 0.5
    if (noise.r < 0.5) {
        noiseScale = 0.5;
    }
    ve3 offsetAmount = vec3(vs_Nor) * noiseScale;
    vec3 noisyPostiion = modelPosition.xyz + offsetAmount;
    gl_postiion = u_ViewProj * vec4(noisyModelPosition);

    ^ At this point the black areas are raised much higher
    but ocean isn't flat so we clamp it with noiseScaled

    cosine colour plaettes to map dirctly on planet
    instead of mix()

    surfaceCOlour = palette(t, a, b, c, d) // a,b,c,d are vec3s


normals

normal(xyz) = (noise(xyz + dx) - noise(xyz - dx),
                noise(xyz + dy) - noise(xyz - dy),
                noise(xyz + dz) - noise(xyz - dz));

correct normal: cartesian -> polar

normal(phi, theta) = (noise(pt + dp) - noise(pt - dp),
                        noise(pt + dt) - noise(pt - dt),
                        z???? )

locla surface normal for our point in polar coords :
lets say (for xample)
normal (phi, tehta) = (0,0,1) by default
compute a displaced normal using the difference sampling method

need to convert this normal from local space to world space

*/