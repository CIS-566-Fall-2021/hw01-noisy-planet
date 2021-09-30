#version 300 es
precision highp float;

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform float u_Tick;
uniform float u_Temp;
uniform float u_Moist;

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;
out float heightIn;
out vec4 vs_Pos2;

const vec4 lightPos = vec4(10., 10., 3., 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

// // STRIPES TEXTURE (GOOD FOR MAKING MARBLE)

// float stripes(float x, float f) {
//   float t = .5 + .5 * sin(f * 2.*3.14159 * x);
//   return t * t - .5;
// }


// // TURBULENCE TEXTURE

// float turbulence(float x, float y, float z, float f) {
//   float t = -.5;
//   for ( ; f <= W/12. ; f *= 2.) // W = Image width in pixels
//     t += abs(perlin(x,y,z,f) / f);
//   return t;
// }

float random(vec2 p){
 	return abs(fract(184.421631 * sin(dot(p, vec2(1932.1902, 6247.4617)))));
}


float random(vec3 p){
 	return abs(fract(184.421631 * sin(dot(p, vec3(1932.1902, 324.012, 6247.4617)))));
  // vec3 k = vec3( 3.1415926, 2.71828,6.62607015);
 	// p = p*k + p.yzx;
 	// return fract( 131.673910 * fract( p.x*p.y*(p.x+p.y)) );
}

float dot(ivec3 a, ivec3 b) {
    return float(a.x * b.x + a.y * b.y + a.z * b.z);
}

float random(ivec3 p){
 	return abs(fract(184.421631 * sin(dot(p, ivec3(1932, 324, 6247)))));
  // vec3 k = vec3( 3.1415926, 2.71828,6.62607015);
 	// p = p*k + p.yzx;
 	// return fract( 131.673910 * fract( p.x*p.y*(p.x+p.y)) );
}

float smoothStep(float a, float b, float t) {
    //t = t*(t*(t * 5.0 - .23));
    //t = clamp(t, 0.0, 1.0);
    return mix(a,b,t);
}


vec3 rand(vec3 p){
 	const vec3 k = vec3( 3.1415926, 2.71828,6.62607015);
 	p = p*k + p.yzx;
 	return -1.0 + 2.0*fract( 2.0 * k * fract( p.x*p.y*(p.x+p.y)) );
}

float interpNoise2D(vec2 p)
{
  vec2 i = floor( p );
  vec2 f = fract( p );

  vec2 u = f*f*(3.0-2.0*f);

  return mix( mix( random( i + vec2(0.0,0.0) ), 
                    random( i + vec2(1.0,0.0) ), u.x),
              mix( random( i + vec2(0.0,1.0) ), 
                    random( i + vec2(1.0,1.0) ), u.x), u.y);
}

float perlinNoise(vec3 p){
  vec3 i = floor(p);
  vec3 f = fract(p);
  vec3 u = f*f*f*(f*(f*6.0-15.0)+10.0);
  
  vec3 g1 = rand(i+vec3(0.0,0.0,0.0));
  vec3 g2 = rand(i+vec3(1.0,0.0,0.0));
  vec3 g3 = rand(i+vec3(0.0,1.0,0.0));
  vec3 g4 = rand(i+vec3(1.0,1.0,0.0));
  vec3 g5 = rand(i+vec3(0.0,0.0,1.0));
  vec3 g6 = rand(i+vec3(1.0,0.0,1.0));
  vec3 g7 = rand(i+vec3(0.0,1.0,1.0));
  vec3 g8 = rand(i+vec3(1.0,1.0,1.0));
  
  vec3 d1 = f - vec3(0.0,0.0,0.0);
  vec3 d2 = f - vec3(1.0,0.0,0.0);
  vec3 d3 = f - vec3(0.0,1.0,0.0);
  vec3 d4 = f - vec3(1.0,1.0,0.0);
  vec3 d5 = f - vec3(0.0,0.0,1.0);
  vec3 d6 = f - vec3(1.0,0.0,1.0);
  vec3 d7 = f - vec3(0.0,1.0,1.0);
  vec3 d8 = f - vec3(1.0,1.0,1.0);
  
  float n1 = dot(g1, d1);
  float n2 = dot(g2, d2);
  float n3 = dot(g3, d3);
  float n4 = dot(g4, d4);
  float n5 = dot(g5, d5);
  float n6 = dot(g6, d6);
  float n7 = dot(g7, d7);
  float n8 = dot(g8, d8);
  
  float a = mix(n1,n2,u.x);
  float b = mix(n3,n4,u.x);
  float c1 = mix(a,b,u.y);
  a = mix(n5,n6,u.x);
  b = mix(n7,n8,u.x);
  float c2 = mix(a,b,u.y);
  float c = mix(c1,c2,u.z);
      
  return c;
}

float smootherStep(float a, float b, float t) {
    t = t*t*t*(t*(t*6.0 - 15.0) + 10.0);
    return mix(a, b, t);
}

float interpNoise3D(vec3 p) {
  int intX = int(floor(p.x));
  float fractX = fract(p.x);
  int intY = int(floor(p.y));
  float fractY = fract(p.y);
  int intZ = int(floor(p.z));
  float fractZ = fract(p.z);

  float v1 = random(ivec3(intX, intY, intZ));
  float v2 = random(ivec3(intX + 1, intY, intZ));
  float v3 = random(ivec3(intX, intY + 1, intZ));
  float v4 = random(ivec3(intX + 1, intY + 1, intZ));

  float v5 = random(ivec3(intX, intY, intZ + 1));
  float v6 = random(ivec3(intX + 1, intY, intZ + 1));
  float v7 = random(ivec3(intX, intY + 1, intZ + 1));
  float v8 = random(ivec3(intX + 1, intY + 1, intZ + 1));

  float i1 = smootherStep(v1, v2, fractX);
  float i2 = smootherStep(v3, v4, fractX);
  float result1 = smootherStep(i1, i2, fractY);

  float i3 = smootherStep(v5, v6, fractX);
  float i4 = smootherStep(v7, v8, fractX);
  float result2 = smootherStep(i3, i4, fractY);

  return smootherStep(result1, result2, fractZ);
}

float stepping(float t, int steps) {
  float dist = 1. / float(steps);
  for (int i = 0 ; i < steps; i ++) {
    if (t < dist * float(i)) {
      return dist * float(i);
    }
  }
}

float getBias(float bias, float t)
{
	return (t / ((( (1.0/bias) - 2.0 ) * (1.0 - t)) + 1.0));
}

float getGain(float gain, float t)
{
  if(t < 0.5){
    return getBias(t * 2.0, gain)/2.0;
  } else {
    return getBias(t * 2.0 - 1.0,1.0 - gain)/2.0 + 0.5;
  }
}

float perlin(vec3 v) {
    //v /= 10000.0;
  int octave = 4;
	float a = 0.5;
  float n = 0.;
	for (int i = 0; i < octave; ++i) {
    float frequency = pow(2.0, float(i));
		n += a * abs(perlinNoise(vec3(v.x * frequency, v.y * frequency, v.z * frequency)));
		a *= 0.5;
	}
  //n = (clamp(getBias(n, .1), 0., 1.));
	return n;
  //return vec3(0.,0.,0.);
}

float perlin(vec3 v, int octave, float a, float zoom) {
  //v /= 10000.0;
  v *= zoom;
  float n = 0.;
	for (int i = 0; i < octave; ++i) {
    float frequency = pow(2.0, float(i));
		n += a * abs(perlinNoise(vec3(v.x * frequency, v.y * frequency, v.z * frequency)));
		a *= a;
	}
  //n = (clamp(getBias(n, .1), 0., 1.));
	return n;
  //return vec3(0.,0.,0.);
}

float fbm(vec3 v, int octave, float a, float zoom) {
  v *= zoom;
  float total = 0.;
  float frequency = 2.0;
	for (int i = 0; i < octave; ++i) {
		total += a * interpNoise3D(frequency * v);
    frequency *= 2.0f;
		a *= a;
	}
  //n = (clamp(getBias(n, .1), ., 1.));
	return total;
}

float fbm(vec4 v) {
  v*= 1.2;
  int octave = 4;
	float a = 1.0;
  float val = 0.0;
	for (int i = 0; i < octave; ++i) {
		val += a * abs(interpNoise3D(vec3(v.x, v.y, v.z)));
    v *= 2.;
		a *= 0.5;
	}
	return val;
}

float fbm2d(vec2 v) {
  v*= 1.2;
  int octave = 4;
	float a = 1.0;
  float val = 0.0;
	for (int i = 0; i < octave; ++i) {
		val += a * abs(interpNoise2D(vec2(v.x, v.y)));
    v *= 2.;
		a *= 0.5;
	}
	return val;
}


vec4 cartesian(float r, float theta, float phi) {
  return vec4(r * sin(phi) * cos(theta), 
              r * sin(phi) * sin(theta),
              r * cos(phi), 1.);
}

// output is vec3(radius, theta, phi)
vec3 polar(vec4 p) {
  float r = sqrt(p.x * p.x + p.y * p.y + p.z * p.z);
  float theta = atan(p.y / p.x);
  // float phi = atan(sqrt(p.x * p.x + p.y * p.y) / p.z);
  float phi = acos(p.z / sqrt(p.x * p.x + p.y * p.y + p.z * p.z));
  return vec3(r, theta, phi);
}

// vec3 adjustNorm() {
//   return vec3(vs_Nor);
//   float offset = .0001;
//   vec3 tangent = cross(vec3(vs_Nor), vec3(0.,1.,0.));
//   vec3 bitangent = cross(vec3(vs_Nor), tangent);
//   vec4 norXSub = vec4(vs_Nor.x - offset, vs_Nor.y, vs_Nor.z, 1.);
//   vec4 norXAdd = vec4(vs_Nor.x + offset, vs_Nor.y, vs_Nor.z, 1.);
//   vec4 norYSub = vec4(vs_Nor.x, vs_Nor.y - offset, vs_Nor.z, 1.);
//   vec4 norYAdd = vec4(vs_Nor.x, vs_Nor.y + offset, vs_Nor.z, 1.);
//   vec4 norZSub = vec4(vs_Nor.x, vs_Nor.y, vs_Nor.z - offset, 1.);
//   vec4 norZAdd = vec4(vs_Nor.x, vs_Nor.y, vs_Nor.z + offset, 1.);
//   vec3 norm = vec3(fbm(norXAdd) - fbm(norXSub), fbm(norYAdd) - fbm(norYSub), fbm(norZAdd) - fbm(norZSub));
//   if (dot(norm, vec3(fs_Nor)) < 0.) {
//     norm *= -1.;
//   }
//   return cross(tangent, bitangent);
// }

  

float mountainMode(vec4 pos) {
  pos += 27.6;
  //float val = clamp(fbm(vec3(pos), 3, .5, 1.)* 2., 0., 1.)* 3.;
  float val = 1. - getBias(clamp(perlin(vec3(pos), 5, .5, 5.), 0., 1.)* 2., .6);
  //float val = perlin(vec3(pos));
  return val;
  if (val > .35) {
    return 1.;
  }
  return 0.;

}

float oceanMode(vec4 pos) {
  //float val = clamp(fbm(vec3(pos), 3, .5, 1.)* 2., 0., 1.)* 3.;
  
  float val = getBias(clamp(fbm(pos.xyz, 5, .5, 1.), 0., 1.), .3);
  //float val = perlin(vec3(pos));
  return val;
  if (val > .25) {
    return 0.;
  }
  return 1.;

}

float temperatureMode(vec4 pos) {
  float newY = 1. - (abs(pos.y) + (fbm2d(vec2(pos.x, pos.z))/ 10.) - .4);
  return newY;
}

float moistureMode(vec4 pos) {
  pos += 10.6;
  //float val = clamp(fbm(vec3(pos), 3, .5, 1.)* 2., 0., 1.)* 3.;
  float val = getGain(clamp(fbm(vec3(pos), 3, .5, .5), 0., 1.), .3);
  
  return val;
}

vec3 paletteTemp(float t)
{
    vec3 a = vec3(0.980, 0.880, 1.000);
    vec3 b = vec3(0.495, 0.302, 0.496);
    vec3 c = vec3(0.279, 0.430, 0.279);
    vec3 d = vec3(-0.153, -0.145, 0.194);
    vec3 ret = a + b*cos( 6.28318*(c*t+d) );
    ret.xyz = vec3(stepping(ret.x, 5), stepping(ret.y, 5), stepping (ret.z, 5));
    return ret;
}

vec3 paletteHeight(float t)
{
    vec3 a = vec3(0.498, 0.500, 0.558);
    vec3 b = vec3(0.500, 0.198, 0.468);
    vec3 c = vec3(-0.442, 1.278, 0.558);
    vec3 d = vec3(1.698, 0.358, 2.088);
    vec3 ret = a + b*cos( 6.28318*(c*t+d) );
    ret.xyz = vec3(stepping(ret.x, 5), stepping(ret.y, 5), stepping (ret.z, 5));
    return ret;
}

vec3 paletteMoist(float t)
{
    vec3 a = vec3(0.498, 0.500, 0.218);
    vec3 b = vec3(0.500, 0.500, 0.500);
    vec3 c = vec3(0.668, 0.338, -0.392);
    vec3 d = vec3(0.418, -0.142, 0.968);
    vec3 ret = a + b*cos( 6.28318*(c*t+d) );
    ret.xyz = vec3(stepping(ret.x, 5), stepping(ret.y, 5), stepping (ret.z, 5));
    return ret;
}

//Ocean is 1
//

float totalNoise(vec4 pos) {
  float val = oceanMode(pos) * 2.;
  if (val < .5) {
    val = .5;
  } else {
    if (val > .62) {
      val += clamp(mountainMode(pos) / 8., 0., 1.);
    }
  }
  return val;
}

vec4 setBiome(vec4 pos, float heightWeight, float tempWeight, float moistWeight) {
  float height = totalNoise(pos);
  float temp = temperatureMode(pos);
  float moist = moistureMode(pos);

  vec4 heightCol = vec4(paletteHeight((height) / .8 -.3), 1.);
  vec4 tempCol = vec4(paletteTemp((temp)), 1.);
  vec4 moistCol = vec4(paletteMoist((moist)), 1.);
  if (height > .25 && height < .3) {
    //heightCol = vec4(9., .8, 0., 1.);
  }
  float totalWeight = heightWeight + tempWeight + moistWeight;
  vec4 retCol = vec4(0.);
  if (height > .5) {
    retCol += (heightCol * heightWeight + tempCol * tempWeight + moistCol * moistWeight) / totalWeight;
  } else {
    retCol = heightCol;
  }
  return retCol;
}

vec4 adjustNorm() {
  vec4 p = vs_Pos;
  vec3 polars = polar(p);
  float offset = .01;
  vec4 xNeg = cartesian(polars.x, polars.y - offset, polars.z);
  vec4 xPos = cartesian(polars.x, polars.y + offset, polars.z);
  vec4 yNeg = cartesian(polars.x, polars.y, polars.z - offset);
  vec4 yPos = cartesian(polars.x, polars.y, polars.z + offset);
  float xNegNoise = totalNoise(xNeg);
  float xPosNoise = totalNoise(xPos);
  float yNegNoise = totalNoise(yNeg);
  float yPosNoise = totalNoise(yPos);

  float xDiff = (xPosNoise - xNegNoise) * 10.;
  float yDiff = (yPosNoise - yNegNoise) * 10.;
  p.z = sqrt(1. - xDiff * xDiff - yDiff * yDiff);

  fs_Nor = vec4(vec3(xDiff, yDiff, p.z), 0);

  vec3 normal = normalize(vec3(vs_Nor));
  vec3 tangent = normalize(cross(vec3(0.0, 1.0, 0.0), normal));
  vec3 bitangent = normalize(cross(normal, tangent));
  mat4 transform;
  transform[0] = vec4(tangent, 0.0);
  transform[1] = vec4(bitangent, 0.0);
  transform[2] = vec4(normal, 0.0);
  transform[3] = vec4(0.0, 0.0, 0.0, 1.0);
  return vec4(normalize(vec3(transform * fs_Nor)), 0.0); 
}

vec4 adjustAlongNorm() {
  //vec3 vs_Pos3 = vec3(vs_Pos.x, vs_Pos.y, vs_Pos.z);
  //return vs_Pos;
  return vs_Pos + vs_Nor*totalNoise(vs_Pos);
}

void main()
{
    //fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation



    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0.);   // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    vec4 newPos = adjustAlongNorm();
    vec4 modelposition = u_Model * newPos;   // Temporarily store the transformed vertex positions for use below

    heightIn = totalNoise(vs_Pos);
    fs_Col = setBiome(vs_Pos, 6., 0., 0.);
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
    vs_Pos2 = vs_Pos;

    //fs_Col = vec4(vec3(oceanMode(vs_Pos)), 1.);
    //fs_Col = vec4(1., 1., 1., 1.);
    vec4 sc_Pos = u_ViewProj * modelposition;

    gl_Position = vec4(sc_Pos.x, sc_Pos.y, sc_Pos.z, sc_Pos.w);  
    //gl_Position = vec4(fs_Pos.x, fs_Pos.y+cos(u_Tick + fs_Pos.x + fs_Pos.z), fs_Pos.z, fs_Pos.w);                    
    // gl_Position is a built-in variable of OpenGL which is
    // used to render the final positions of the geometry's vertice
}
