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
//uniform vec3 u_CamPos;
// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_Pos;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 old;
in vec4 fs_CamPos;
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
    vec4 blue1 = vec4(-0.171, 0.688, 0.868, 1.f);
    vec4 blue2 = vec4(-0.072, .1584, -0.132, 1.f);
    vec4 blue3 =  vec4(0.748, 1.508, 1.578, 1.f);
    vec4 blue4 = vec4(-0.322, 0.498, 0.198, 1.f);
    float fbmBlue = perlinNoise3D(fs_Pos.xyz * 1.3) * cos(u_Time * .005);
    vec3 oceanCol = palette(fbmBlue, blue1.xyz, blue2.xyz, blue3.xyz, blue4.xyz);

    vec4 green1 = vec4(0.158, 0.508, -0.332, 1.f);
    vec4 green2 = vec4(0.478, 0.188, 0.638, 1.f);
    vec4 green3 = vec4(1.308, 0.948, 1.000, 1.f);
    vec4 green4 = vec4(-0.692, 0.328, 1.178, 1.f);

    float greenFBM = fbm(fs_Pos.xyz * .4, 3.0);
    float g = clamp(length(fs_Pos.xyz) / 1.2, 0.0, 1.0);

    //cosine color palette for green
    vec3 grassCol = palette(greenFBM, green1.xyz, green2.xyz, green3.xyz, green4.xyz);
    // Material base color (before shading)
    vec4 greenColor = vec4(grassCol, 1.f);
  
    vec4 blueColor = vec4(oceanCol, 1.f);
    vec4 greyMt = vec4(.3, .3, .3, 1.f);
    vec4 diffuseColor = blueColor;

   float diffuseTerm = 0.f;
    vec4 av = normalize(fs_LightVec) + normalize(fs_CamPos);
    vec4 avg = av / 2.0;
         float specularIntensity = 0.f;
        
        // diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
         vec4 cam = (fs_CamPos - fs_Pos);
         diffuseTerm = dot(normalize(fs_Nor), normalize(cam)); 
         diffuseTerm += dot(normalize(fs_Nor), normalize(fs_LightVec));
            //if(g > 1.18)
            if (g > 0.98)
            {
                diffuseColor = vec4(1.f, 1.f, 1.f, 1.f);
                vec4 cam = (fs_CamPos - fs_Pos);
                //diffuseTerm = dot(normalize(fs_Nor), normalize(cam));
                diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
                specularIntensity = 0.f;
                 specularIntensity = max(pow(dot(normalize(avg), normalize(fs_Nor)), 8.f), 0.f);
               
            }
            //else if(g > 1.08)
            else if (g > 0.92)
            {
                
             diffuseColor = greyMt;
             diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
             specularIntensity = 0.f;
            }
            //else if(g > 1.02)
            else if (g >= 0.89)
            {
               
                float newG = remapTo01(.89, .92, g);
        
                    vec4 green = vec4(0.0, 1.0, 0.0, 1.0);
                    vec4 white = vec4(1.0);
                    diffuseColor = mix(greyMt, greenColor, 1.0-newG);
  
                diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
                specularIntensity = 0.f;
            }
            else if(g > .855)
            {
                diffuseColor = greenColor;
        
                diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
                specularIntensity = 0.f;
            }
      
            else if (g > 0.845)
            {
                diffuseColor = vec4(207.f / 255.f, 182.f / 255.f, 70.f / 255.f, 1.f);
                diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
                specularIntensity = 0.f;
            }
        //change the light color in light and shadow
        if(diffuseTerm < 0.f)
        {
            diffuseColor = diffuseColor * u_Shadow;
        }
        else
        {
            diffuseColor = diffuseColor * u_Light;
        }
        
        vec3 diffuse3 = vec3(fs_Pos.x, fs_Pos.y, fs_Pos.z);
      
        // Avoid negative lighting values

        float ambientTerm = 0.2;
        diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);
        float lightIntensity = diffuseTerm + ambientTerm + specularIntensity;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}
