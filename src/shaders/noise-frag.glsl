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
uniform float u_Time;
uniform int u_Shader;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;
in vec4 fs_ViewVec;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

#define NUM_OCTAVES 5

float random1(vec2 p) {
  return fract(sin(dot(p, vec2(456.789, 20487145.123))) * 842478.5453);
}

float random1( vec3 p ) {
  return fract(sin(dot(p, vec3(127.1, 311.7, 191.999))) * 43758.5453);
}

float mySmootherStep(float a, float b, float t) {
  t = t*t*t*(t*(t*6.0 - 15.0) + 10.0);
  return mix(a, b, t);
}

float interpNoise3D1(vec3 p) {
  vec3 pFract = fract(p);
  float llb = random1(floor(p));
  float lrb = random1(floor(p) + vec3(1.0,0.0,0.0));
  float ulb = random1(floor(p) + vec3(0.0,1.0,0.0));
  float urb = random1(floor(p) + vec3(1.0,1.0,0.0));

  float llf = random1(floor(p) + vec3(0.0,0.0,1.0));
  float lrf = random1(floor(p) + vec3(1.0,0.0,1.0));
  float ulf = random1(floor(p) + vec3(0.0,1.0,1.0));
  float urf = random1(floor(p) + vec3(1.0,1.0,1.0));

  float lerpXLB = mySmootherStep(llb, lrb, pFract.x);
  float lerpXHB = mySmootherStep(ulb, urb, pFract.x);
  float lerpXLF = mySmootherStep(llf, lrf, pFract.x);
  float lerpXHF = mySmootherStep(ulf, urf, pFract.x);

  float lerpYB = mySmootherStep(lerpXLB, lerpXHB, pFract.y);
  float lerpYF = mySmootherStep(lerpXLF, lerpXHF, pFract.y);

  return mySmootherStep(lerpYB, lerpYF, pFract.z);
}

float fbm(vec3 p) {
  float amp = 0.5;
  float freq = 18.0;
  float sum = 0.0;
  float maxSum = 0.0;
  for(int i = 0; i < NUM_OCTAVES; ++i) {
    maxSum += amp;
    sum += interpNoise3D1(p * freq) * amp;
    amp *= 0.5;
    freq *= 2.0;
  }
  return sum / maxSum;
}

float pattern( vec3 p )
{
    vec3 q = vec3(fbm(p));
    q += 0.03*sin( vec3(0.27, 0.23, 0.11) * u_Time * 0.1); 

    return fbm( p + 2.0*q );
}

void main()
{
    // Material base color (before shading)
    vec4 diffuseColor = fs_Col;

    float ambientTerm = 0.2;

    vec3 specularTerm = vec3(0.0);
    vec3 SpecularColor = vec3(1.0, 1.0, 1.0);
    vec3 localNormal = normalize(fs_Pos.xyz);

    vec4 vertexPos = fs_Pos;
    vec3 normalVec = normalize(cross( dFdx(vertexPos.xyz), dFdy(vertexPos.xyz)));

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(vec4(normalVec,1.0)), normalize(fs_LightVec));
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

    //Blinn_Phong
    if(u_Shader == 1)
    {
         vec3 halfVec = fs_ViewVec.xyz + fs_LightVec.xyz;
         halfVec = normalize(halfVec);        
         //Intensity of the specular light
         float NoH = clamp(dot( normalVec, halfVec ), 0.0, 1.0);
         specularTerm = vec3(pow(NoH, 16.0)) * SpecularColor;
    }


    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.

    // Compute final shaded color
    out_Col = vec4( ( diffuseColor.rgb + specularTerm) * lightIntensity, 1.0);

    //out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}
