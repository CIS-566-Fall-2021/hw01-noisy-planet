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
uniform vec3 u_CameraPos;
uniform vec3 u_LightPos;
uniform float u_CityDensity;
uniform float u_MountainGlow;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;
in vec4 sphere_Nor;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

vec4 hill_col = vec4(0.0, 0.7, 0.3, 1.0);
vec4 grass_col = vec4(40.0, 247.0, 130.0, 255.0) / 255.0;

vec4 snow_col = vec4(1.0);
vec4 mountain_purple = vec4(140.0, 104.0, 183.0, 255.0) / 255.0;
vec4 mountain_lumin = vec4(0.5, 1.0, 1.0, 1.0);

vec4 ocean_col1 = vec4(43.0, 85.0, 252.0, 255.0) / 255.0;
vec4 ocean_col2 = vec4(43.0, 231.0, 252.0, 255.0) / 255.0;

vec3 dayColor = vec3(191.0, 143.0, 0.0) / 255.0;
vec3 nightColor = vec3(1.0, 8.0, 38.0) / 255.0;

/* ----------------------------- Random Functions --------------------------- */

vec3 random3( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1, 311.7, 191.999)),
                          dot(p,vec3(269.5, 183.3, 765.54)),
                          dot(p, vec3(420.69, 631.2,109.21))))
                 *43758.5453);
}

float random1( vec3 p ) {
    return fract(sin(dot(p,vec3(127.1, 311.7, 183.3))) *43758.5453);
}

/* ----------------------------- Ease functions ----------------------------- */
float easeOutQuad(float x){
    return 1.0 - (1.0 - x) * (1.0 - x);
}

float easeInQuad(float x){
    return x*x;
}

float easeInCubic(float x){
    return x*x*x;
}

float easeInQuart(float x){
    return x*x*x*x;
}

float easeOutCubic(float x){
    return 1.0 - pow(1.0 - x, 3.0);
}

/* ------------------------------ Noise ------------------------------------ */
float mountainWorley(vec3 p) {
    // Tile the space
    vec3 pointInt = floor(p);
    vec3 pointFract = fract(p);

    float minDist = 1.0; // Minimum distance initialized to max.

    // Search all neighboring cells and this cell for their point
    for(int z = -1; z <= 1; z++){
        for(int y = -1; y <= 1; y++){
            for(int x = -1; x <= 1; x++){
                vec3 neighbor = vec3(float(x), float(y), float(z));

                // Random point inside current neighboring cell
                vec3 point = random3(pointInt + neighbor);

                // Compute the distance b/t the point and the fragment
                // Store the min dist thus far
                vec3 diff = neighbor + point - pointFract;
                float dist = length(diff);
                minDist = min(minDist, dist);
            }
        }
    }
    return minDist;
}

float surflet(vec3 p, vec3 gridPoint) {
    // Compute the distance between p and the grid point along each axis, and warp it with a
    // quintic function so we can smooth our cells
    vec3 t2 = abs(p - gridPoint);
    vec3 t = vec3(1.0) - 6.0 * vec3(pow(t2.x, 5.0), pow(t2.y, 5.0), pow(t2.z, 5.0)) + 15.0 * vec3(pow(t2.x, 4.0), pow(t2.y, 4.0), pow(t2.z, 4.0)) - 10.0 * vec3(pow(t2.x, 3.0), pow(t2.y, 3.0), pow(t2.z, 3.0));

    vec3 gradient = random3(gridPoint) * 2.0 - vec3(1.0);
    // Get the vector from the grid point to P
    vec3 diff = p - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * t.x * t.y * t.z;
}

float perlinNoise3D(vec3 p) {
	float surfletSum = 0.0;
	// Iterate over the four integer corners surrounding uv
	for(int dx = 0; dx <= 1; ++dx) {
		for(int dy = 0; dy <= 1; ++dy) {
			for(int dz = 0; dz <= 1; ++dz) {
				surfletSum += surflet(p, floor(p) + vec3(dx, dy, dz));
			}
		}
	}
	return surfletSum;
}

/* ---------------------------- Shading Models ------------------------------ */
vec4 lambert(vec4 col, float lightIntensity){
    return vec4(col.rgb * lightIntensity, col.a);
}

vec4 blinnPhong(vec4 diffuseCol, float lightIntensity){
    float shininess = 45.0;                      // exp
    vec4 V = vec4(u_CameraPos,1.0) - fs_Pos;     // view vector
    vec4 H = normalize((normalize(fs_LightVec) + V) / 2.0); // halfway vector
    vec3 lightColor = lightIntensity * vec3(2.f, 2.f, 2.f);     // white light

    vec3 specular = max(pow(dot(H, fs_Nor), shininess), 0.0) * lightColor * diffuseCol.rgb;

    return vec4(specular,0.0) + lambert(diffuseCol, lightIntensity);
}

/* ----------------------------- Biomes ------------------------------------- */
vec4 getShallowWater(float h, float lightIntensity){
    float x = (h+0.2) / (0.201 - 0.0001);
    vec4 colorOffset = vec4(0.15, 0.15, 0.1, 0.0);
    vec4 color = mix(ocean_col1 - colorOffset, ocean_col1, x);
    return blinnPhong(color, lightIntensity);
}

vec4 getSnow(float h, float lightIntensity, bool isDay, vec3 p){
    h = mix(0.28*h, 0.25*mountainWorley(8.0*p), h);  
    return isDay ? lambert(snow_col, lightIntensity) : 
                   mix(lambert(snow_col, lightIntensity), snow_col, u_MountainGlow / 100.0);
}

vec4 getMidToDeepWater(float h, float lightIntensity){
    float x = h / (0.02 - 0.001);
    vec4 color = mix(ocean_col1, ocean_col2, 1.0 - (1.0 - x) * (1.0 - x));
    return blinnPhong(color, lightIntensity);
}

vec4 getDeepWater(float lightIntensity){
    vec4 colorOffset = vec4(0.15, 0.15, 0.1, 0.0);
    vec4 color = (ocean_col1 - colorOffset);
    return blinnPhong(color, lightIntensity);
}

float pcurve( float x, float a, float b){
    float k = pow(a+b, a+b) / (pow(a,a)*pow(b,b));
    return k * pow(x, a) * pow(1.0-x,b);
}
float bias(float b, float t){
    return pow(t, log(b) / log(0.5));
}

float gain (float g, float t){
    if (t < 0.5){
        return bias(1.0-g, 2.0*t) / 2.0;
    }
    else{
        return 1.0 - bias(1.0-g, 2.0 - 2.0*t) / 2.0;
    }
}
vec4 getMidGrass(float h, bool isDay, bool isHill, float lightIntensity, 
                 float poleFactor, vec3 p){
    float remapped = (h - 0.001) / (0.1 - 0.001);
    float worleyFactor = 0.8*mountainWorley(1.5*p) + 0.2*mountainWorley(2.7*p);
    vec4 mappedGrass = mix(grass_col - vec4(0.1, 0.35, 0.25, 0.0), grass_col, gain(0.96, worleyFactor));
    vec4 midGrass = lambert(mappedGrass, lightIntensity);
    vec4 mountain_col = isDay ? midGrass : mix(midGrass, mountain_lumin, u_MountainGlow / 100.0);
    // interpolate between illuminated mountain color and nighttime grass color
    if (!isDay && poleFactor >= 0.0 && poleFactor <= 0.2){
        mountain_col = mix(midGrass, mountain_col, poleFactor / 0.2);
    }
    if (isHill){
        mountain_col = midGrass;
    }
    return mix(midGrass, mountain_col, remapped*remapped);
}

vec4 getPoppyColor(vec3 p, float t){
    float rand = random1(p);
    if (rand < 0.75){
        return hill_col - vec4(0.06, 0.06, 0.06, 0.0);
    }
    return hill_col + vec4(0.04, 0.04, 0.04, 0.0);
}
vec4 getMountainToHill(float t, float lightIntensity, bool isDay, vec3 p){
      float worleyFactor = 0.6*mountainWorley(1.1*p) + 0.4*mountainWorley(2.7*p);
    vec4 mappedGrass = mix(getPoppyColor(p, worleyFactor), hill_col, gain(0.94, worleyFactor));

    vec4 mountain_col = isDay ? lambert(mountain_purple, lightIntensity) : 
                                mix(lambert(mountain_purple, lightIntensity), mountain_lumin, u_MountainGlow / 100.0);
    vec4 hill_lambert = lambert(mappedGrass, lightIntensity);

    // interpolate so that color shift b/w mountains and hills isn't sharp
    float x = 1.0 - abs(t / 0.2);
    return mix(mountain_col, hill_lambert, x);
}

vec4 getMountainOrHill(float lightIntensity, bool isDay, bool isHill, float dayFactor, vec3 p){
      float worleyFactor = 0.6*mountainWorley(1.1*p) + 0.4*mountainWorley(2.7*p);
    vec4 mappedGrass = mix(getPoppyColor(p, worleyFactor), hill_col, gain(0.94, worleyFactor));

    vec4 mountain_col = isDay ? lambert(mountain_purple, lightIntensity) : 
                                mix(lambert(mountain_purple, lightIntensity), mountain_lumin, u_MountainGlow / 100.0);
    return isHill ? lambert(mappedGrass, lightIntensity) : mountain_col;
}

/* ------------------------ World Creation -----------------------------------*/
vec4 createBiomes(vec3 pos, vec3 sphere_nor, vec3 nor, float dayFactor, 
                  float lightIntensity, out bool isOcean)
{
    float perlinScale = 1.8;
    float h = (perlinNoise3D(perlinScale*pos.xyz) + 0.5*perlinNoise3D(perlinScale*2.0 * pos.xyz)) + 0.05;
    float poleFactor = sphere_nor.z;
    bool isHillBiome = poleFactor <= 0.0;
    bool isDay = dayFactor > 0.0;
    isOcean = false;
    if (h < 0.1){
        h = -0.01*abs(sin(0.015*u_Time)) + h;
    }
    // increase the perlin noise height by 0.2 to find the lighter water areas
    if (h+0.2 > 0.0001 && h+0.2 < 0.201){
        isOcean = true;
        return getShallowWater(h, lightIntensity);
    }
    if (h > 0.001 && h < 0.02){
        isOcean = true;
        return getMidToDeepWater(h, lightIntensity);
    }
    if (h <= 0.001){
        isOcean = true;
        return getDeepWater(lightIntensity);
    }
    if (h < 0.1){
        return getMidGrass(h, isDay, isHillBiome, lightIntensity, poleFactor, pos);
    }
    if (h > 0.45 && !isHillBiome){
        return getSnow(h, lightIntensity, isDay, pos);
    }
    // interpolate so that color shift b/w mountains and hills isn't sharp
    if (poleFactor >= 0.0 && poleFactor <= 0.2){
        return getMountainToHill(poleFactor, lightIntensity, isDay, pos);
    }
    return getMountainOrHill(lightIntensity, isDay, isHillBiome, dayFactor, pos);
}

float getHeight(vec3 pos, vec3 nor){
    float perlinScale = 1.8;
    float t = perlinNoise3D(perlinScale*pos.xyz) + 0.5*perlinNoise3D(perlinScale*2.0 * pos.xyz);
    if (t > 0.04){
        float hill_t = 0.28*t;
        float mountain_t = 0.25*mountainWorley(8.0*pos);
        mountain_t = mix(0.0, mountain_t, t / (0.37 - 0.04));
        float mount_hill_t = mix(hill_t, mountain_t, sin((t * 3.14159) / 2.0));

        float biome_t = (nor.z + 1.0) / 2.0;
        return mix(hill_t, mountain_t, biome_t*biome_t);
    }
    if (t <= 0.04){
        return 0.0;
    }
    return 0.28*t;
}

float sdSphere( vec3 p, float r, float h )
{
    // offset radius by height field
  return length(p)-(r + h);
}

/*vec4 specular(vec3 p, vec3 nor, bool isDay, float lightIntensity){
    vec3 camPos = u_CameraPos;
    vec3 rayDir = normalize(p - camPos);
    vec3 reflectedDir = reflect(rayDir, nor);
    // maybe negate the y?
    reflectedDir.y = -reflectedDir.y;
    //reflectedDir.z = -reflectedDir.z;
    //return vec4(abs(reflectedDir), 1.0);
    // march along reflectedDir 
    float steps = 1.0;
    float stepDelta = 0.1;
    while (steps < 51.0){
        vec3 marchPt = p + reflectedDir * (steps * stepDelta);

        // at each step, map to sphere
        vec3 spherePt = normalize(marchPt);
        // get height
        float h = getHeight(spherePt, nor);
        // offset sphere sdf by height
        float dist = sdSphere(marchPt, 1.0, h);

        if (dist <= 0.0){
            bool isOcean;
            return mix(createBiomes(spherePt, nor, nor, isDay, lightIntensity, isOcean), createBiomes(p, nor, nor, isDay, lightIntensity, isOcean), 0.8);
        }
        steps++;
    }
    bool isOcean;
    return *//*createBiomes(p, nor, nor, isDay, lightIntensity, isOcean)*/ /*vec4(1.0);
}*/

vec3 lightPalette(float t){
    vec3 a = vec3(0.758, 0.258, 0.608);
    vec3 b = vec3(0.478, 0.458, 1.218); 
    vec3 c = vec3(0.798, 0.678, 0.868);
    vec3 d = vec3(-2.226, -3.126, -2.563);
    vec3 lightColor = a + b * cos(2.0*3.14159*(c*(1.0-t) + d));
    return lightColor;
}

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);

        float ambientTerm = 0.1;

        // pick sky colors
        float palette_t = easeOutQuad(clamp(diffuseTerm + 0.11, 0.0, 1.0));
        vec3 lightColor = lightPalette(palette_t);
        //lightColor -= mix(vec3(0.4), vec3(0.0), palette_t);
        // make day color less yellow
        if (palette_t > 0.3){
            lightColor = mix(lightColor, vec3(0.9, 0.9, 0.5), (palette_t - 0.3) / 0.7);
        }
        // make night color darker

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        bool isOcean = false;
        vec4 col = createBiomes(fs_Pos.xyz, sphere_Nor.xyz, fs_Nor.xyz, diffuseTerm, lightIntensity, isOcean);
        /*if (isOcean){
            col = specular(fs_Pos.xyz, fs_Nor.xyz, diffuseTerm > 0.0, lightIntensity);
        }*/
        // create city
        float normalSimilarity = clamp(dot(sphere_Nor, fs_Nor), 0.0, 1.0);
        if (normalSimilarity > 0.97 && !isOcean && diffuseTerm <= 0.0 && sphere_Nor.z <= 0.0){
            float t = (normalSimilarity - 0.97) / 0.03;
            float cityDensity = t > 0.85 ? u_CityDensity : 35.0;
            float lightScale = mix(0.08, 0.25, (cityDensity - 35.0) / (80.0 - 35.0));
            float distToLight = mountainWorley(cityDensity*fs_Pos.xyz);
            if (distToLight < lightScale){
                col =  mix(vec4(1.0), vec4(1.0, 1.0, 0.0, 1.0), t*t*t);
            }   
        }
        out_Col = vec4((col.rgb) + 0.2*lightColor.rgb, col.a);
}
