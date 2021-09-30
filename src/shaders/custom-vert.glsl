#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform int u_Octave;
uniform float u_Bias;
uniform float u_Freq;
uniform float u_Height;
uniform float u_Speed;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;
out vec4 fs_ViewVec;

const vec4 lightPos = vec4(3, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

uniform float u_Time;

uniform vec4 u_HeightsInfo;

uniform vec3 u_CamPos;

float bias(float b, float t) {
    return (t/((((1.0/b)-2.0)*(1.0-t))+1.0));
}

float gain(float g, float t){
    if (t < 0.5){
        return bias(1.0-g, 2.0*t)/2.0;
    }
    else{
        return 1.0 - bias(1.0-g, 2.0-2.0*t)/2.0;
    }
}

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
  float freq = u_Freq;
  float sum = 0.0;
  float maxSum = 0.0;
  for(int i = 0; i < u_Octave; ++i) {
    maxSum += amp;
    sum += interpNoise3D1(p * freq) * amp;
    amp *= 0.5;
    freq *= 2.0;
  }
  return sum / maxSum;
}

vec3 rgb(float r, float g, float b) {
  return vec3(r / 255.0, g / 255.0, b / 255.0);
}

void main()
{
    //fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation


    vec4 vertexPos = vs_Pos;
    vec3 localNormal = normalize(vertexPos.xyz);
    float oceneHeight = length(vertexPos.xyz); 
    float noiseResult = clamp((fbm(vertexPos.xyz + bias(u_Bias, sin(u_Time * 0.001 * u_Speed)) ) * 2.0) - 1.0, 0.0, 1.0) / u_Height;  
    vertexPos.xyz += localNormal * noiseResult;

    fs_Pos = vertexPos;
    float a;
    
    float snowHeight = mix(0.09, 0.35, gain(0.1, (sin(u_Time * 0.005) + 1.0) / 2.0));

    // snow 
    if(noiseResult > snowHeight) {
        fs_Col = vec4(1.0, 1.0, 1.0, 1.0);
    }
    // mountian
    else if (noiseResult > 0.1) {
        a = smoothstep(0.1, snowHeight, noiseResult);
        fs_Col = mix(vec4(1.0, 1.0, 0.0, 1.0), vec4(1.0, 1.0, 1.0, 1.0), a);
    }
    // forest
    else if (noiseResult > 0.03) {
        a = smoothstep(0.03, 0.1, noiseResult);
        fs_Col = mix(vec4(0.0, 1.0, 0.0, 1.0), vec4(1.0, 1.0, 0.0, 1.0), a);
    }
    // ocean
    else if (noiseResult == 0.0) {
        fs_Col = vec4(0.0, 0.412, 0.58, 1.0);
    }
    // shore
    else {
        a = smoothstep(0.0, 0.03, noiseResult);
        fs_Col = mix(vec4(54.0 / 255., 34.0 / 255., 4.0 / 255., 1.0), vec4(0.0, 1.0, 0.0, 1.0), a);
    }

    float height = length(vertexPos.xyz);

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * vertexPos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    mat3 invModel = mat3(inverse(u_Model));
    vec3 viewVec = u_CamPos.xyz - modelposition.xyz;
    fs_ViewVec = vec4( invModel * normalize(viewVec), length(u_CamPos.xyz));

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
