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
uniform float u_Time;                           // but in HW3 you'll have to generate one yourself
uniform vec3 u_CamPos;
in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.
out vec4 old;
out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col; 
out vec4 fs_Pos;           // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_CamPos;
const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.


float random1( vec3 p ) {
  return fract(sin(dot(p, vec3(127.1, 311.7, 191.999))) * 43758.5453);
}

vec3 random3( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1, 311.7, 191.999)),
                          dot(p,vec3(269.5, 183.3, 765.54)),
                          dot(p, vec3(420.69, 631.2,109.21))))
                 *43758.5453);
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
float fbm(vec3 newP, float octaves) {
  float amp = 0.5;
  float freq = 6.0;
  float sum = 0.0;
  float maxSum = 0.0;
  for(float i = 0.0; i < 10.0; ++i) {
    if(i == octaves)
    break;
    maxSum += amp;
    sum += interpNoise3D1(newP * freq) * amp;
    amp *= 0.5;
    freq *= 2.0;
  }
  return (sum / maxSum);
} 

//worley noise
float WorleyNoise(vec3 pos)
{
    pos *= 3.0;
   vec3 uvInt = floor(pos);
    vec3 uvFract = fract(pos);
    float minDist = 1.0;
    vec3 closeOne;
    for(int z = -1; z <= 1; z++)
    {
    for(int y = -1; y <= 1; ++y)
    {
        for(int x = -1; x <= 1; ++x)
        {
           vec3 neighbor = vec3(float(x), float(y), float(z));
          vec3 point = random3(uvInt + neighbor);
            vec3 diff = neighbor + point - uvFract;
            float dist = length(diff);
            //finding the point that is the closest random point
            if(dist < minDist)
            {
                //getting the point into the correct uv coordinate space
                minDist = dist;
                //closeOne = (uvInt + neighbor + point) / 8.0;
            }

        
        }
    }
    }
    return minDist;
   // return clamp(minDist, .1f, 1.f);
   //return vec3(0.0, 0.f, 0.f);
}

float surflet(vec3 p, vec3 gridPoint) {
    // Compute the distance between p and the grid point along each axis, and warp it with a
    // quintic function so we can smooth our cells
    vec3 t2 = abs(p - gridPoint);
    vec3 pow1 = vec3(pow(t2.x, 5.f), pow(t2.y, 5.f), pow(t2.z, 5.f));
    vec3 pow2 = vec3(pow(t2.x, 4.f), pow(t2.y, 4.f), pow(t2.z, 4.f)); 
    vec3 pow3 = vec3(pow(t2.x, 3.f), pow(t2.y, 3.f), pow(t2.z, 3.f));
    vec3 t = vec3(1.f) - 6.f * pow1
        + 15.f * pow2 
        - 10.f * pow3;
    // Get the random vector for the grid point (assume we wrote a function random2
    // that returns a vec2 in the range [0, 1])
    vec3 gradient = random3(gridPoint) * 2.f - vec3(1,1,1);
    // Get the vector from the grid point to P
    vec3 diff = p - gridPoint;
    
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * t.x * t.y * t.z;
}


//PERLIN NOISE

float perlinNoise3D(vec3 p) {
	float surfletSum = 0.f;
	// Iterate over the four integer corners surrounding uv
	for(int dx = 0; dx <= 1; ++dx) {
		for(int dy = 0; dy <= 1; ++dy) {
            for (int dz = 0; dz <= 1; ++dz) {
			surfletSum += surflet(p, floor(p) + vec3(dx, dy, dz));
            }
		}
	}
	return surfletSum;
}
float fbmMoutain(vec3 p){

        float total = 0.f;
         float persistence = 0.5f;
         int octaves = 2;
         float start = 1.f;
         float freq = 1.f;
         float max = 0.f;
         float amp = 0.7f;
        //increasing the layers of noise with every octave
         for(int i = 1; i <= octaves; i++) {
             //freq = pow(2.f, i);
             //float amp = pow(persistence, i);
             max += amp;
             vec3 vec = p * freq;
             total += (abs(perlinNoise3D(vec)));
             total = total * start;
             start = total;
             //total += n * amp;

             freq *= 2.f;
             amp *= 0.5;
         }
         return  total / max;

  }
vec3 IDF(vec3 vec){

        vec3 total = vec3(perlinNoise3D(vec), perlinNoise3D(vec + vec3(-1.2, 1.5, 1)), perlinNoise3D(vec + vec3(.2, -.5, 1.0)));

        vec3 totalSmall = (total + vec3(1.f)) * 0.5f;
      //smooth stepping so that the biomes blend smoothly
        totalSmall = smoothstep(0.f, 1.f, (smoothstep(0.25f, 0.75f, totalSmall)));
       // totalSmall = (glm::smoothstep(0.25f, 0.75f, totalSmall));
         return totalSmall;
  } 

float hills(vec3 p)
{
  float h = perlinNoise3D(p * 3.0);
   h = clamp(h, 0.f, .03);
   return h;
}

float moutains(vec3 p)
{
   float m = fbm(p * .8, 3.0);
    m = pow(m, 3.1);
    m -= .12;
    m = clamp(m, 0.f, 1.f);
    return m;
}

float plateau(vec3 pos)
{
    float p = fbmMoutain(pos * 4.50);
    p = pow(p, 1.3f);
    p = clamp(p, 0.f, .2);
    return p;
}

//float 
float bias(float b, float t)
{
  return pow(t, log(b) / log(0.5f));
}

float ocean(vec3 pos)
{
  float o = perlinNoise3D(pos * 3.8);
  //o = pow(o, 2.0f);
  o = bias(o, .4f);
  o -= .09;
  o = clamp(o, 0.f, .02f);
  return o;
}

float getHeight(vec3 pos)
{
   float h = hills(pos * .5);
    //float p = fbm(vs_Pos.xyz * .4, 4.0);
    //float p = fbmMoutain(vs_Pos.xyz * 6.50);


    float m = moutains(pos * .6);
    float p = plateau(pos * .4);
    float i = ocean(pos); 

    //p = mix(h, p, .2);
    //float a = abs(perlinNoise3D(vs_Pos.xyz * 3.0)) - .2;
    //a = clamp(a, -0.1f, .05f);
  
    //starting idf
    vec3 idf = IDF(pos * .5);
    float mixPlatReg = mix(p, i, idf.x);
    float mixMoutHill = mix(m, h, idf.x);
    float total = mix(mixMoutHill, mixPlatReg, idf.z);
    return total;
}


vec3 getNormal(float total)
{
  vec3 tangent = cross(vec3(0.f, 1.f, 0.f), fs_Nor.xyz);
  vec3 bitangent = cross(fs_Nor.xyz, tangent);

  vec3 newPt1 = vs_Pos.xyz + tangent * .1;
  vec3 newPt2 = vs_Pos.xyz + bitangent * .1;

  float a = total;
  float b = getHeight(newPt1);
  float c = getHeight(newPt2);

  vec3 aPt = vs_Pos.xyz + fs_Nor.xyz * a;
  vec3 bPt = newPt1 + fs_Nor.xyz * b;
  vec3 cPt = newPt2 + fs_Nor.xyz * c;

  vec3 final = cross(normalize(aPt - bPt), normalize(aPt - cPt));
  return final;

}
void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    fs_Pos = vs_Pos;
    old = vs_Pos;
    mat3 invTranspose = mat3(u_ModelInvTr);

    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                        // model matrix. This is necessary to ensure the normals remain
   
    float total = getHeight(vs_Pos.xyz);
    fs_Pos += fs_Nor * total;
   
    fs_Nor = vec4(getNormal(total), 0.f);
    //fs_Pos += fs_Nor * vec4(w, w, w, 1);
   // fs_Nor.x = WorleyNoise(fs_Pos.xyz + vec3(.0001, 0.f, 0.f)) - WorleyNoise(fs_Pos.xyz - vec3(.0001, 0.0, 0.0));
  //  fs_Nor.y = WorleyNoise(fs_Pos.xyz + vec3(0.f, .0001, 0.f)) - WorleyNoise(fs_Pos.xyz - vec3(0.0, .0001, 0.0));
  //  fs_Nor.z = WorleyNoise(fs_Pos.xyz + vec3(0.f, 0.f, .0001)) - WorleyNoise(fs_Pos.xyz - vec3(0.0, 0.0, .0001));
  
    //vs_Pos.x = vs_Pos.x * p;
    
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * (fs_Pos);   // Temporarily store the transformed vertex positions for use below

    vec4 modelposition2 = vec4(.5, 0, 0, 0);
  //  modelposition2.xyz = modelposition.xyz + (sin(modelposition.xyz) * 1.05) + (sin(modelposition.xyz) * .25);
    //modelposition2.yz = modelposition.yz + (cos(modelposition.yz) * .35);
    //modelposition2
    //modelposition2.y = modelposition2.y + (sin(modelposition2.y) * .20);
    //modelposition.xyz = mix(modelposition.xyz,  modelposition2.xyz, t);
    gl_Position = u_ViewProj * modelposition;
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
    fs_CamPos =  vec4(u_CamPos, 0.f);
    //gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
