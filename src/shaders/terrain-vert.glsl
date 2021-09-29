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
uniform highp int u_Time;

uniform highp float u_LightSpeed;

uniform highp float u_MountainHeight;

uniform highp float u_Flower;

uniform vec4 u_CamPos;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;
out float biome_type;
out vec4 modelposition;
out float flower_type;

vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.



float random1( vec3 p ) {
  return fract(sin((dot(p, vec3(127.1,
  311.7,
  191.999)))) *
  18.5453);
}

// Returns random vec3 in range [0, 1]
vec3 random3(vec3 p) {
 return fract(sin(vec3(dot(p,vec3(127.1, 311.7, 191.999)),
                        dot(p,vec3(269.5, 183.3, 765.54)),
                        dot(p, vec3(420.69, 631.2,109.21))))
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
    p = p * 2.5;
    float sum = 0.0;
    for(int dx = 0; dx <= 1; ++dx) {
        for (int dy = 0; dy <= 1; ++dy) {
           for (int dz = 0; dz <= 1; ++dz) {
               sum += surflet(vec3(p), floor(vec3(p)) + vec3(dx, dy, dz));
           } 
        }
    }
    
    return sum / 6.0;
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

float smootherStep(float a, float b, float t) {
    t = t*t*t*(t*(t*6.0 - 15.0) + 10.0);
    return mix(a, b, t);
}

float interpNoise3D(float x, float y, float z) {
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
    total += interpNoise3D(x * freq, y * freq, z * freq) * amp;
  }
  return total;
}



float GetBias(float time, float bias)
{
    return (float(time) / ((((1.0/bias) - 2.0)*(1.0 - float(time)))+1.0));
}

float GetGain(float time, float gain)
{
  if(time < 0.5)
    return GetBias(time * 2.0,gain)/2.0;
  else
    return GetBias(time * 2.0 - 1.0,1.0 - gain)/2.0 + 0.5;
}

vec4 transformToWorld(vec4 nor) {
  vec3 normal = normalize(vec3(vs_Nor));
  vec3 tangent = normalize(cross(vec3(0.0, 1.0, 0.0), normal));
  vec3 bitangent = normalize(cross(normal, tangent));
  mat4 transform;
  transform[0] = vec4(tangent, 0.0);
  transform[1] = vec4(bitangent, 0.0);
  transform[2] = vec4(normal, 0.0);
  transform[3] = vec4(0.0, 0.0, 0.0, 1.0);
  return vec4(normalize(vec3(transform * nor)), 0.0); 
} 


float mountainNoise(vec4 p, float factor) {
    return summedPerlin(p * factor);
}

vec4 cartesian(float r, float theta, float phi) {
  return vec4(r * sin(phi) * cos(theta), 
              r * sin(phi) * sin(theta),
              r * cos(phi), 1.);
}

vec3 polar(vec4 p) {
  float r = sqrt(p.x * p.x + p.y * p.y + p.z * p.z);
  float theta = atan(p.y / p.x);
  float phi = acos(p.z / sqrt(p.x * p.x + p.y * p.y + p.z * p.z));
  return vec3(r, theta, phi);
}

vec4 mountainNormals(vec4 p, float factor) {
  vec3 polars = polar(p);
  float offset = .01;
  vec4 xNeg = cartesian(polars.x, polars.y - offset, polars.z);
  vec4 xPos = cartesian(polars.x, polars.y + offset, polars.z);
  vec4 yNeg = cartesian(polars.x, polars.y, polars.z - offset);
  vec4 yPos = cartesian(polars.x, polars.y, polars.z + offset);
  float xNegNoise = mountainNoise(xNeg, factor);
  float xPosNoise = mountainNoise(xPos, factor);
  float yNegNoise = mountainNoise(yNeg, factor);
  float yPosNoise = mountainNoise(yPos, factor);

  float xDiff = (xPosNoise - xNegNoise) * 10.;
  float yDiff = (yPosNoise - yNegNoise) * 10.;
  p.z = sqrt(1. - xDiff * xDiff - yDiff * yDiff);
  return vec4(vec3(xDiff, yDiff, p.z), 0);
}



vec4 computeTerrain() {
    // use noise functions to create four biomes
    // land, water, ice, mountains
    vec3 tInput = vs_Pos.xyz * vec3(0.5 * u_MountainHeight);
    vec3 t = vec3(fbm(tInput.x, tInput.y, tInput.z, 6.0));
    float biomeMap = worley(vec3(fbm(tInput.x, tInput.y, tInput.z, 6.0)));
    biomeMap = GetGain(biomeMap, 0.4f);
    vec4 noisePos = vs_Pos;
    vec4 grassElevation = vs_Pos + max(vec4(0.), vs_Nor * summedPerlin(vs_Pos * 1.1));
    vec4 desertElevation = vs_Pos + max(vec4(0.), vs_Nor * summedPerlin(vs_Pos * 2.0));
    vec4 mountainElevation = vs_Pos + max(vec4(0.), vs_Nor * mountainNoise(vs_Pos, 3.0));
    vec4 iceElevation = vs_Pos + max(vec4(0.), vs_Nor * mountainNoise(vs_Pos, 4.0));
    

    if (biomeMap < 0.2) { // water
        fs_Nor = vs_Nor;
        biome_type = 0.0;
    } else if (biomeMap < 0.3) { // grass
        float x = GetBias((biomeMap - 0.2) / 0.1, 0.3);
        noisePos = mix(vs_Pos, grassElevation, x);
        fs_Nor = transformToWorld(normalize(mountainNormals(vs_Pos, 1.1)));
        biome_type = 1.0;
    } else if (biomeMap < 0.4) { // desert
        float x = GetBias((biomeMap - 0.3) / 0.1, 0.7);
        noisePos = mix(grassElevation, desertElevation, x);
        fs_Nor = transformToWorld(normalize(mountainNormals(vs_Pos, 2.0)));
        biome_type = 2.0;
    } else if (biomeMap < 0.5) { // mountain
        float x = GetBias((biomeMap - 0.4) / 0.1, 0.3);
        noisePos = mix(desertElevation, mountainElevation, x);
        fs_Nor = transformToWorld(normalize(mountainNormals(vs_Pos, 3.0)));
        biome_type = 3.0;
    } else { // ice
          float x = GetBias((biomeMap - 0.5) / 0.5, 0.3);
        noisePos = mix(mountainElevation, iceElevation, x);
        fs_Nor = transformToWorld(normalize(mountainNormals(vs_Pos, 4.0)));
        biome_type = 4.0;
    }

    float flowerMap = pow(fbm(tInput.x, tInput.y, tInput.z, 6.0),5.f) * u_Flower;
    if (flowerMap > 0.1) {
      flower_type = 1.0;
    }
    
    return noisePos;
}




void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.
    vec4 noisePos = computeTerrain();
    vec4 modelposition = u_Model * noisePos;   // Temporarily store the transformed vertex positions for use below
    fs_Pos = modelposition;

    //rotate the light source

    float a =  float(u_Time) * 0.002 * u_LightSpeed;
    vec4 c0 = vec4(cos(a), 0, -1.*sin(a), 0);
    vec4 c1 = vec4(0, 1, 0, 0);
    vec4 c2 = vec4(sin(a), 0, cos(a), 0);
    vec4 c3 = vec4(0, 0, 0, 1);
    mat4 rotate = mat4(c0, c1, c2, c3);
    lightPos = rotate * lightPos;


    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * fs_Pos;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
