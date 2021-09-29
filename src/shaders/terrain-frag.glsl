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
in float flower_type;
out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


float ease_in_quadratic(float t){
    return t*t;
}

float ease_in_out_quadratic(float t) {
    if (t<0.5)
        return ease_in_quadratic(t*2.0)/2.0;
    else  
        return 1.0 - ease_in_quadratic((1.0-t)*2.0);
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

vec3 rgb(float r, float g, float b) {
    return vec3(r / 255.0, g / 255.0, b / 255.0);
}


vec3 waterSlime() {
    float f = fbm(fs_Pos.x, fs_Pos.y, fs_Pos.z, 6.);
    vec4 f2 =  fs_Pos + f; 
    f = fbm(f2.x  + .003 * float(u_Time), f2.y  + .003 * float(u_Time), f2.z, 6.);
    f = ease_in_out_quadratic(f);
    vec3 a = vec3(0.35, 1.84, 0.35);
    vec3 b = vec3(0.4 , -0.41, 0.5);
    vec3 c = vec3(-0.46 , 0.333, 0.5);
    vec3 d = vec3(0. , 0.66, 0.5);
    vec3 color = a + b * cos(6.28 * (f * c + d));
    return color;
}

vec3 grassPurple() {

    float f = fbm(fs_Pos.x * 1.5, fs_Pos.y * 1.5, fs_Pos.z * 1.5, 16.);
    vec3 a = vec3(0.6, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.66, 0.5);
    vec3 c = vec3(0.1, 0.66, 0.5);
    vec3 d = vec3(-0.34, 0.06, 0.5);
    vec3 color = a + b * cos(6.28 * (f * c + d));
    return color;
}


vec3 desertPink() {

    float f = fbm(fs_Pos.x * 1.3, fs_Pos.y * 1.5, fs_Pos.z * 1.4, 16.);
    vec3 a = vec3(1.13, 0.4, 0.56);
    vec3 b = vec3(0.21, 0.27, 0.19);
    vec3 c = vec3(1.0, 0.7, 0.8);
    vec3 d = vec3(1.8, 3.3, 4.3);
    vec3 color = a + b * cos(6.28 * (f * c + d));  
    return color;
}


vec3 mountainLilac() {

    float f = fbm(fs_Pos.x * 2.1, fs_Pos.y * 2.1, fs_Pos.z * 2.1, 16.);
    vec3 a = vec3(0.68, .66, .6);
    vec3 b = vec3(0.250);
    vec3 c = vec3(1.000);
    vec3 d = vec3(0);
    vec3 color = a + b * cos(6.28 * (f * c + d));  
    return color;
}

vec3 iceBlue() {

    float f = fbm(fs_Pos.x * 2.5, fs_Pos.y * 2.5, fs_Pos.z * 2.5, 16.);
    vec3 a = vec3(0.11, 1.07, 1.09);
    vec3 b = vec3(0.92, 0.13, 0.04);
    vec3 c = vec3(0.11, 0.30, 0.24);
    vec3 d = vec3(3.0, 5.28, 2.69);
    vec3 color = a + b * cos(6.28 * (f * c + d));  
    return color;
}

vec3 flowerYellow() {
    float f = fbm(fs_Pos.x * 10.5, fs_Pos.y * 10.5, fs_Pos.z * 10.5, 16.);
    vec3 a = vec3(0.731, 1.098, 0.192);
    vec3 b = vec3(0.358, 1.09, 0.65);
    vec3 c = vec3(1.077, 0.36, 0.328);
    vec3 d = vec3(0.965, 2.265, 0.837);
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
            color = iceBlue;
        }

        if (flower_type == 1.0) {
            color = flowerYellow();
        }
        vec4 view = vec4(normalize(u_CamPos.xyz - fs_Pos.xyz), 1.);
        vec4 H = normalize(view + vec4(normalize(fs_LightVec.xyz), 1.));
        vec3 specularIntensity = pow(max(dot(H, normalize(fs_Nor)), 0.), 100.) * rgb(240., 243., 220.);

        out_Col = vec4(color * lightIntensity + specularIntensity, 1.0);
}
