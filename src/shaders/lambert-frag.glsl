#version 300 es
precision highp float;

#define RADIUS = 1.0;

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Tick;
uniform float u_Temp;
uniform float u_Moist;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in float heightIn;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;
in vec4 vs_Pos2;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

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
//   return vec3(fs_Nor);
//   float offset = .0001;
//   vec3 tangent = cross(vec3(fs_Nor), vec3(0.,1.,0.));
//   vec3 bitangent = cross(vec3(fs_Nor), tangent);
//   vec4 norXSub = vec4(fs_Nor.x - offset, fs_Nor.y, fs_Nor.z, 1.);
//   vec4 norXAdd = vec4(fs_Nor.x + offset, fs_Nor.y, fs_Nor.z, 1.);
//   vec4 norYSub = vec4(fs_Nor.x, fs_Nor.y - offset, fs_Nor.z, 1.);
//   vec4 norYAdd = vec4(fs_Nor.x, fs_Nor.y + offset, fs_Nor.z, 1.);
//   vec4 norZSub = vec4(fs_Nor.x, fs_Nor.y, fs_Nor.z - offset, 1.);
//   vec4 norZAdd = vec4(fs_Nor.x, fs_Nor.y, fs_Nor.z + offset, 1.);
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
    t = stepping(t, 10) - .1;
    vec3 a = vec3(0.800, 0.838, 0.888);
    vec3 b = vec3(0.418, 0.468, 0.808);
    vec3 c = vec3(0.718, 1.000, 1.000);
    vec3 d = vec3(0.308, 0.078, 1.028);
    vec3 ret = a + b*cos( 6.28318*(c*t+d) );
    //ret.xyz = vec3(stepping(ret.x, 5), stepping(ret.y, 5), stepping (ret.z, 5));
    return ret;
}

vec3 paletteHeight(float t)
{
    t = stepping(t, 10) - .1;
    vec3 a = vec3(0.448, 0.500, -0.282);
    vec3 b = vec3(-0.472, 0.500, 0.600);
    vec3 c = vec3(-0.672, 0.498, 0.278);
    vec3 d = vec3(-0.472, -0.142, 0.748);
    vec3 ret = a + b*cos( 6.28318*(c*t+d) );
    //ret.xyz = vec3(stepping(ret.x, 5), stepping(ret.y, 5), stepping (ret.z, 5));
    return ret;
}

vec3 paletteMoist(float t)
{
    t = stepping(t, 10) - .1;
    vec3 a = vec3(0.821, 0.328, 0.242);
    vec3 b = vec3(0.659, 0.481, 0.896);
    vec3 c = vec3(0.233, 0.129, 0.112);
    vec3 d = vec3(2.820, 3.026, -0.273);
    vec3 ret = a + b*cos( 6.28318*(c*t+d) );
    //ret.xyz = vec3(stepping(ret.x, 5), stepping(ret.y, 5), stepping (ret.z, 5));
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

  vec4 retCol = vec4(0.);
  vec4 heightCol = vec4(paletteHeight((height / 1.0 - 0.6) * 1.6), 1.);
  vec4 tempCol = vec4(paletteTemp((height / 1.0 - 0.35) * 1.6), 1.);
  vec4 moistCol = vec4(paletteMoist((height / 1.0 - 0.6) * 1.6), 1.);
  
  float totalWeight = heightWeight + tempWeight + moistWeight;
  
  if (height > .5) {
    retCol += (heightCol * heightWeight + tempCol * tempWeight + moistCol * moistWeight) / totalWeight;
  } else {
    retCol = heightCol;
  }
  if (height < .505) {
    retCol = vec4(0., .3, .5, 1.);
  }
  if (moist < u_Moist / 3.) {
      retCol = moistCol;     
      if (height < .505) {
        retCol = vec4(0., .5, .7, 1.);
      }
  } else if (moist < u_Moist / 3. + .1) {
      
      if (height < .505) {
        retCol = mix(vec4(0., .3, .5, 1.), vec4(0., .5, .7, 1.), 1.+(u_Moist / 3. - moist) * 10.);
      } else {
        retCol = mix(retCol, moistCol, 1.+(u_Moist / 3. - moist) * 10.);
      }
  }

  float check = 1.;
  if (temp < u_Temp) {
      retCol = tempCol;
      if (height > .75) {
          check = -1.;
      }
  } else if (temp < u_Temp + .1) {
      retCol = mix(retCol, tempCol, 1.+(u_Temp - temp) * 10.);
  }
  
  if (height < .505) {
    retCol = retCol + ((getGain(clamp(fbm(pos.xyz, 5, .5, 5.), 0., 1.), .1)) / 3.);
  }

  
  retCol.w = check;
  return retCol;
}

#define DELTA 1e-4

vec4 adjustNorm() {
    vec4 p = vs_Pos2;
    vec3 tangent = normalize(cross(vec3(0,1,0), fs_Nor.xyz));
    vec3 bitangent = cross(fs_Nor.xyz, tangent);

    vec3 xNeg = p.xyz - tangent * DELTA;
    vec3 yNeg = p.xyz - bitangent * DELTA;
    vec3 xPos = p.xyz + tangent * DELTA;
    vec3 yPos = p.xyz + bitangent * DELTA;

    xNeg += fs_Nor.xyz * totalNoise(vec4(xNeg, 1.));
    yNeg += fs_Nor.xyz * totalNoise(vec4(yNeg, 1.));
    xPos += fs_Nor.xyz * totalNoise(vec4(xPos, 1.));
    yPos += fs_Nor.xyz * totalNoise(vec4(yPos, 1.));

    vec3 newTan = xPos - xNeg;
    vec3 newBit = yPos - yNeg;

    return vec4(normalize(cross(newTan, newBit)), 0.);
}

vec4 adjustNormOLD() {
  vec4 p = vs_Pos2;
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

  vec4 nor = vec4(vec3(xDiff, yDiff, p.z), 0);

  vec3 normal = normalize(vec3(nor));
  vec3 tangent = normalize(cross(vec3(0.0, 1.0, 0.0), normal));
  vec3 bitangent = normalize(cross(normal, tangent));
  mat4 transform;
  transform[0] = vec4(tangent, 0.0);
  transform[1] = vec4(bitangent, 0.0);
  transform[2] = vec4(normal, 0.0);
  transform[3] = vec4(0.0, 0.0, 0.0, 1.0);
  return vec4(normalize(vec3(transform * nor)), 0.0); 
}
void main()
{
    // Material base color (before shading)
    vec4 diffuseColor = u_Color;

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = clamp(dot(normalize(adjustNorm().xyz), normalize(fs_LightVec.xyz)), 0., 1.);
    // Avoid negative lighting values
    // diffuseTerm = clamp(diffuseTerm, 0, 1);

    float ambientTerm = 0.3;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.
    // Compute final shaded color
    //out_Col = vec4((vec3(diffuseColor)) * lightIntensity, diffuseColor.a);
    //out_Col = vec4(vec3(mod(u_Tick, 255.0) / 255.0) * lightIntensity, diffuseColor.a);

    vec4 v = vec4(0., 0., 20., 1.);
    vec4 h = (v + fs_LightVec) / 2.;
    float specularIntensity = max(pow(dot(normalize(h),normalize(fs_Nor)),.5),2.f);
    vec3 timeAdj = vec3((mod(u_Tick, 255.0) / 255.0));
    vec4 col = setBiome(vs_Pos2, 1., 0., 0.);
    if (col.w < 0.) {
        out_Col = vec4(vec3(clamp(col * lightIntensity * specularIntensity, 0.0, 1.0)), 1.);
    } else {
        out_Col = vec4(vec3(clamp(col * lightIntensity, 0.0, 1.0)), 1.);
    }
    //out_Col = vec4(clamp(vec3(fs_Pos)   * lightIntensity, 0.0, 1.0), diffuseColor.a);

    // out_Col = vec4(diffuseTerm, diffuseTerm, diffuseTerm, 1.);

}
