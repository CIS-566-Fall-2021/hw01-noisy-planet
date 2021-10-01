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
uniform vec4 u_Light;
uniform vec4 u_Shadow;
// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_Pos;
in vec4 fs_LightVec;
in vec4 fs_Col;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.
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

vec3 random3( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1, 311.7, 191.999)),
                          dot(p,vec3(269.5, 183.3, 765.54)),
                          dot(p, vec3(420.69, 631.2,109.21))))
                 *43758.5453);
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
  //* sin(u_Time * 0.04);
}


float fbm(vec3 newP, float octaves) {
  float amp = 0.5;
  float freq = 4.0;
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
vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d )
{
    return a + b * cos( 6.28318*(c*t+d) );
}

 float remapTo01(float min, float max, float t)
  {
      float difference = max - min;
      float scaleFactor = 1.0 / difference;
      t *= scaleFactor;
      t -= (min * scaleFactor);
      return t;
 }
void main()
{
    //color options 
    vec3 purple1 = vec3(0.308, 0.390, 0.390);
    vec3 purple2 = vec3(0.588, 0.398, 0.688);
    vec3 purple3 = vec3(0.458, 0.948, 0.538);
    vec3 purple4 = vec3(-1.332, 0.333, 0.667);

  vec3 pos = vec3(fs_Pos);
        pos.x = remapTo01(0.f, .2, pos.x);
        pos.y = remapTo01(0.f, .2, pos.y);
        pos.z = remapTo01(0.f, .2, pos.z);
     
        float G = perlinNoise3D(pos * 1.1);
        //float G = fbm(pos * .85, 2.0);
        G = G / 2.0 + 1.0;
        vec4 col = vec4(palette(G, purple1, purple2, purple3, purple4), 1.f);
        
       
        // Calculate the diffuse term for Lambert shading
        //vec3 newColor = mix(newColorA, newColorB, .8);
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
         if(diffuseTerm < 0.f)
        {
            col = col * u_Shadow;
        }
        else
        {
            col = col * u_Light;
        }
        float ambientTerm = 0.2;
        diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);
        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                          //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        out_Col = vec4(col.rgb * lightIntensity, 1.f);
}
