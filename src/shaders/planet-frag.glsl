#version 300 es
#define PI 3.1415926535897932384626433832795

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

uniform highp float u_Time;
uniform vec4 u_Camera;

// Procedural Controls
uniform highp float terrainFreq;    // Sets the frequency of noise that outputs terrain elevations
uniform highp float earthToAlien;    // 0.0 -> earth color palette, 1.0 -> alien color palette
uniform highp float forestScale;    // 0.0 -> earth color palette, 1.0 -> alien color palette

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


// FBM Noise ------------------------------------
float noise3D(vec3 p)
{
	return fract(sin(dot(p ,vec3(12.9898,78.233,128.852))) * 43758.5453)*2.0-1.0;
}

float simplex3D(vec3 p)
{
	
	float f3 = 1.0/3.0;
	float s = (p.x+p.y+p.z)*f3;
	int i = int(floor(p.x+s));
	int j = int(floor(p.y+s));
	int k = int(floor(p.z+s));
	
	float g3 = 1.0/6.0;
	float t = float((i+j+k))*g3;
	float x0 = float(i)-t;
	float y0 = float(j)-t;
	float z0 = float(k)-t;
	x0 = p.x-x0;
	y0 = p.y-y0;
	z0 = p.z-z0;
	
	int i1,j1,k1;
	int i2,j2,k2;
	
	if(x0>=y0)
	{
		if(y0>=z0){ i1=1; j1=0; k1=0; i2=1; j2=1; k2=0; } // X Y Z order
		else if(x0>=z0){ i1=1; j1=0; k1=0; i2=1; j2=0; k2=1; } // X Z Y order
		else { i1=0; j1=0; k1=1; i2=1; j2=0; k2=1; }  // Z X Z order
	}
	else 
	{ 
		if(y0<z0) { i1=0; j1=0; k1=1; i2=0; j2=1; k2=1; } // Z Y X order
		else if(x0<z0) { i1=0; j1=1; k1=0; i2=0; j2=1; k2=1; } // Y Z X order
		else { i1=0; j1=1; k1=0; i2=1; j2=1; k2=0; } // Y X Z order
	}
	
	float x1 = x0 - float(i1) + g3; 
	float y1 = y0 - float(j1) + g3;
	float z1 = z0 - float(k1) + g3;
	float x2 = x0 - float(i2) + 2.0*g3; 
	float y2 = y0 - float(j2) + 2.0*g3;
	float z2 = z0 - float(k2) + 2.0*g3;
	float x3 = x0 - 1.0 + 3.0*g3; 
	float y3 = y0 - 1.0 + 3.0*g3;
	float z3 = z0 - 1.0 + 3.0*g3;	

	vec3 ijk0 = vec3(i,j,k);
	vec3 ijk1 = vec3(i+i1,j+j1,k+k1);	
	vec3 ijk2 = vec3(i+i2,j+j2,k+k2);
	vec3 ijk3 = vec3(i+1,j+1,k+1);	

	vec3 gr0 = normalize(vec3(noise3D(ijk0),noise3D(ijk0*2.01),noise3D(ijk0*2.02)));
	vec3 gr1 = normalize(vec3(noise3D(ijk1),noise3D(ijk1*2.01),noise3D(ijk1*2.02)));
	vec3 gr2 = normalize(vec3(noise3D(ijk2),noise3D(ijk2*2.01),noise3D(ijk2*2.02)));
	vec3 gr3 = normalize(vec3(noise3D(ijk3),noise3D(ijk3*2.01),noise3D(ijk3*2.02)));

	float n0 = 0.0;
	float n1 = 0.0;
	float n2 = 0.0;
	float n3 = 0.0;

	float t0 = 0.5 - x0*x0 - y0*y0 - z0*z0;
	if(t0>=0.0)
	{
		t0*=t0;
		n0 = t0 * t0 * dot(gr0, vec3(x0, y0, z0));
	}
	float t1 = 0.5 - x1*x1 - y1*y1 - z1*z1;
	if(t1>=0.0)
	{
		t1*=t1;
		n1 = t1 * t1 * dot(gr1, vec3(x1, y1, z1));
	}
	float t2 = 0.5 - x2*x2 - y2*y2 - z2*z2;
	if(t2>=0.0)
	{
		t2 *= t2;
		n2 = t2 * t2 * dot(gr2, vec3(x2, y2, z2));
	}
	float t3 = 0.5 - x3*x3 - y3*y3 - z3*z3;
	if(t3>=0.0)
	{
		t3 *= t3;
		n3 = t3 * t3 * dot(gr3, vec3(x3, y3, z3));
	}
	return 96.0*(n0+n1+n2+n3);
	
}

float fbm(vec3 p)
{
	float f;
    f  = 0.50000*simplex3D( p ); p = p*2.01;
    f += 0.25000*simplex3D( p ); p = p*2.02;
    f += 0.12500*simplex3D( p ); p = p*2.03;
    f += 0.06250*simplex3D( p ); p = p*2.04;
    f += 0.03125*simplex3D( p );
	return f*0.5+0.5;
}

// Noise2 ------------------------------------
float hash(float n) { return fract(sin(n) * 1e4); }
float hash(vec2 p) { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }

float noise2(vec3 x) {
	const vec3 step = vec3(110, 241, 171);

	vec3 i = floor(x);
	vec3 f = fract(x);
 
    float n = dot(i, step);

	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}

// Noise3 ------------------------------------
float noise3(float x) {
	float i = floor(x);
	float f = fract(x);
	float u = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), u);
}

// Perlin Noise ------------------------------------
float map(float value, float old_lo, float old_hi, float new_lo, float new_hi)
{
	float old_range = old_hi - old_lo;
    if (old_range == 0.0) {
	    return new_lo; 
	} else {
	    float new_range = new_hi - new_lo;  
	    return (((value - old_lo) * new_range) / old_range) + new_lo;
	}
}

/**
 * The canonical GLSL hash function
 */
float hash1(float x)
{
	return fract(sin(x) * 43758.5453123);
}

/** 
 * Nothing is mathematically sound about anything below: 
 * I just chose values based on experimentation and some 
 * intuitions I have about what makes a good hash function
 */
vec3 gradient(vec3 cell)
{
	float h_i = hash1(cell.x);
	float h_j = hash1(cell.y + pow(h_i, 3.0));
	float h_k = hash1(cell.z + pow(h_j, 5.0));
    float ii = map(fract(h_i + h_j + h_k), 0.0, 1.0, -1.0, 1.0);
    float jj = map(fract(h_j + h_k), 0.0, 1.0, -1.0, 1.0);
	float kk = map(h_k, 0.0, 1.0, -1.0, 1.0);
    return normalize(vec3(ii, jj, kk));
}

/**
 * Perlin's "ease-curve" fade function
 */
float fade(float t)
{
   	float t3 = t * t * t;
    float t4 = t3 * t;
    float t5 = t4 * t;
    return (6.0 * t5) - (15.0 * t4) + (10.0 * t3);        
}    

float pnoise(in vec3 coord)
{
    vec3 cell = floor(coord);
    vec3 unit = fract(coord);
   
    vec3 unit_000 = unit;
    vec3 unit_100 = unit - vec3(1.0, 0.0, 0.0);
    vec3 unit_001 = unit - vec3(0.0, 0.0, 1.0);
    vec3 unit_101 = unit - vec3(1.0, 0.0, 1.0);
    vec3 unit_010 = unit - vec3(0.0, 1.0, 0.0);
    vec3 unit_110 = unit - vec3(1.0, 1.0, 0.0);
    vec3 unit_011 = unit - vec3(0.0, 1.0, 1.0);
    vec3 unit_111 = unit - 1.0;

    vec3 c_000 = cell;
    vec3 c_100 = cell + vec3(1.0, 0.0, 0.0);
    vec3 c_001 = cell + vec3(0.0, 0.0, 1.0);
    vec3 c_101 = cell + vec3(1.0, 0.0, 1.0);
    vec3 c_010 = cell + vec3(0.0, 1.0, 0.0);
    vec3 c_110 = cell + vec3(1.0, 1.0, 0.0);
    vec3 c_011 = cell + vec3(0.0, 1.0, 1.0);
    vec3 c_111 = cell + 1.0;

    float wx = fade(unit.x);
    float wy = fade(unit.y);
    float wz = fade(unit.z);
 
    float x000 = dot(gradient(c_000), unit_000);
	float x100 = dot(gradient(c_100), unit_100);
	float x001 = dot(gradient(c_001), unit_001);
	float x101 = dot(gradient(c_101), unit_101);
	float x010 = dot(gradient(c_010), unit_010);
	float x110 = dot(gradient(c_110), unit_110);
	float x011 = dot(gradient(c_011), unit_011);
	float x111 = dot(gradient(c_111), unit_111);
   
    float y0 = mix(x000, x100, wx);
    float y1 = mix(x001, x101, wx);
    float y2 = mix(x010, x110, wx);
    float y3 = mix(x011, x111, wx);
    
	float z0 = mix(y0, y2, wy);
    float z1 = mix(y1, y3, wy);
    
    return mix(z0, z1, wz);
}	

// Forest noise function
float forestNoise(vec3 noiseInput) {
    float smallForestFreq = 30.0 * forestScale;
    float largeForestFreq = 25.0 * forestScale;
    float smallForestNoise = fbm(smallForestFreq * noiseInput + 20.0);
    float largeForestNoise = 1.0 - pnoise(largeForestFreq * noiseInput);
    float sizeNoise = fbm(smallForestFreq - largeForestFreq * noiseInput + 20.0);
    return mix(smallForestNoise, largeForestNoise, sizeNoise);
}

float GetBias(float time, float bias) {
    return (time / ((((1.0/bias) - 2.0) * (1.0 - time)) + 1.0));
}

float GetGain(float time, float gain) {
    if (time < 0.5) {
        return GetBias(time * 2.0, gain) / 2.0;
    } else {
        return GetBias(time * 2.0 - 1.0, 1.0 - gain) / 2.0 + 0.5;
    }
}

vec3 rgb(float r, float g, float b) {
    return vec3(r / 255.0, g / 255.0, b / 255.0);
}

mat4 rotationX( in float angle ) {
	return mat4(	1.0,		0,			0,			0,
			 		0, 	cos(angle),	-sin(angle),		0,
					0, 	sin(angle),	 cos(angle),		0,
					0, 			0,			  0, 		1);
}

mat4 rotationY( in float angle ) {
	return mat4(	cos(angle),		0,		sin(angle),	0,
			 				0,		1.0,			 0,	0,
					-sin(angle),	0,		cos(angle),	0,
							0, 		0,				0,	1);
}

mat4 rotationZ( in float angle ) {
	return mat4(	cos(angle),		-sin(angle),	0,	0,
			 		sin(angle),		cos(angle),		0,	0,
							0,				0,		1,	0,
							0,				0,		0,	1);
}

// Calculates the elevation of a given point based on its noise value
float getElevation(vec3 noiseInput) {

    float noise = fbm(noiseInput);

    float waterElevation = 0.9;
    float beachElevation = 0.93;
    float landElevation = 1.0;
    float mountElevation1 = 1.05;
    float mountElevation2 = 1.7;
    float mountElevation3 = 1.7;
    
    float waveNoise= noise2(10.0 * noise2((0.0006 * u_Time) + 3.0 * vec3(noiseInput) + noiseInput) + noiseInput);
    float elevation = mix(waterElevation, waterElevation + 0.05, waveNoise);

    //float elevation = waterElevation;
    
    // Creates beach level
    if (noise > 0.4 && noise < 0.52) {
        elevation = beachElevation;
    } else if (noise > 0.52 && noise < 0.53) {
        float x = GetBias((noise - 0.52) / 0.01, 0.3);
        elevation = mix(beachElevation, waterElevation, x);
    }

    // Creates land level
    float forestNoise = forestNoise(noiseInput);
    if (noise > 0.48 && noise < 0.5) {
        float x = GetBias((noise - 0.48) / 0.02, 0.7);
        elevation = mix(landElevation, beachElevation, x);
    } else if (noise > 0.4 && noise < 0.48) {
        float x = GetGain((noise - 0.4) / 0.08, 0.9);
        elevation = mix(landElevation * ((forestNoise * 0.08) + landElevation), landElevation, x);
    }

    // Creates mountain level
    float mountainNoise = fbm(10.0 * noiseInput + 20.0);
    if (noise > 0.37 && noise < 0.4) {
        float x = GetBias((noise - 0.37) / 0.03, 0.5);
        elevation =  mix(landElevation * ((forestNoise * 0.08) + landElevation), mountElevation1, x);
    } else if (noise < 0.37) {
        float x = GetGain(noise / 0.37, mountainNoise);
        elevation =  mix(mountElevation2, mountElevation1, x);
    }

    return elevation;

}

void main()
{
    // Material base color (before shading)
    vec4 diffuseColor = u_Color;
    vec3 noiseInput = fs_Pos.xyz * terrainFreq;

    float noise = fbm(noiseInput);

    // Calculate new normal based on elevated neighbors passed in from vertex shader
    // Get tangent and bitangent vectors
    vec3 tangent = cross(vec3(0.0, 1.0, 0.0), fs_Nor.xyz);
    vec3 bitangent = cross(fs_Nor.xyz, tangent);

    // Get offset amount for epsilon distance away
    float e = 0.00001;

    // Get neighbors
    vec3 p1 = noiseInput + vec3(e) * tangent;
    vec3 p2 = noiseInput + vec3(e) * bitangent;
    vec3 p3 = noiseInput - vec3(e) * tangent;
    vec3 p4 = noiseInput - vec3(e) * bitangent;

    float p1_e =  getElevation(p1);
    float p2_e =  getElevation(p2);
    float p3_e =  getElevation(p3);
    float p4_e =  getElevation(p4);

    vec3 p1_deformed = p1 + fs_Nor.xyz * p1_e;
    vec3 p2_deformed = p2 + fs_Nor.xyz * p2_e;
    vec3 p3_deformed = p3 + fs_Nor.xyz * p3_e;
    vec3 p4_deformed = p4 + fs_Nor.xyz * p4_e;

    vec4 norm_deformed = vec4(cross(normalize(p1_deformed - p3_deformed), normalize(p2_deformed - p4_deformed)), 1.0);
    // out_Col = norm_deformed * 0.5 + 0.5;
    // return;

    // Calculate the diffuse term for Lambert shading
    vec4 rotated_lightVec = fs_LightVec * rotationY(0.008 * u_Time);
    float diffuseTerm = dot(normalize(norm_deformed), normalize(rotated_lightVec)) * 10.0;
    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

    // Initialize specular value so it can be conditionally changed for mountains
    vec3 view = normalize(u_Camera.xyz - fs_Pos.xyz);
    vec3 light_distance = normalize(fs_LightVec.xyz - fs_Pos.xyz);
    vec3 h = (light_distance + view) / 2.0;
    float spec = 0.0;
    float distance = length(fs_LightVec);

    vec3 surfaceColor = vec3(noise);

    // Earth color palette
    vec3 waterCol_e = rgb(10.0, 145.0, 175.0);
    vec3 deepWaterCol_e = rgb(0.0, 36.0, 118.0) * waterCol_e;
    vec3 landCol_e = rgb(12.0, 145.0, 82.0);
    vec3 deepLandCol_e = rgb(33.0, 125.0, 1.0) * landCol_e;
    vec3 beachCol_e = rgb(255.0, 234.0, 200.0);
    vec3 dirtCol_e = rgb(38.0, 11.0, 11.0);
    vec3 mountainCol_e = rgb(53.0, 43.0, 53.0);
    vec3 deepMountainCol_e = rgb(125.0, 97.0, 118.0) * mountainCol_e;

    // Alien color palette
    vec3 waterCol_a = rgb(84.0, 195.0, 195.0);
    vec3 deepWaterCol_a = rgb(42.0, 162.0, 147.0) * waterCol_a;
    vec3 landCol_a = rgb(122.0, 93.0, 122.0);
    vec3 deepLandCol_a = rgb(205.0, 16.0, 139.0) * landCol_a;
    vec3 beachCol_a = rgb(236.0, 148.0, 111.0);
    vec3 dirtCol_a = rgb(163.0, 8.0, 0.0);
    vec3 mountainCol_a = rgb(68.0, 39.0, 122.0);
    vec3 deepMountainCol_a = rgb(61.0, 61.0, 93.0) * mountainCol_a;

    // Earth To Alien color palette
    vec3 waterCol = mix(waterCol_e, waterCol_a, earthToAlien);
    vec3 deepWaterCol = mix(deepWaterCol_e, deepWaterCol_a, earthToAlien) * waterCol;
    vec3 landCol = mix(landCol_e, landCol_a, earthToAlien);
    vec3 deepLandCol = mix(deepLandCol_e, deepLandCol_a, earthToAlien) * landCol;
    vec3 beachCol = mix(beachCol_e, beachCol_a, earthToAlien);
    vec3 dirtCol = mix(dirtCol_e, dirtCol_a, earthToAlien);
    vec3 mountainCol = mix(mountainCol_e, mountainCol_a, earthToAlien);
    vec3 deepMountainCol = mix(deepMountainCol_a, deepMountainCol_e, earthToAlien) * mountainCol;

    vec3 black = rgb(0.0, 0.0, 0.0);
    vec3 white = rgb(255.0, 255.0, 255.0);

    // Creates water level
    float x = noise2(5.0 * noise2((0.0006 * u_Time) + vec3(noiseInput) + noiseInput) + noiseInput);
    vec3 waterFinalCol = mix(deepWaterCol, waterCol, x);
    surfaceColor = waterFinalCol;

    // Creates beach level
    if (noise > 0.48 && noise < 0.52) {
        surfaceColor = beachCol;
    } else if (noise > 0.52 && noise < 0.53) {
        float x = GetBias((noise - 0.52) / 0.01, 0.3);
        surfaceColor = mix(beachCol, waterFinalCol, x);
    }

    // Creates land level
    float forestNoise = forestNoise(noiseInput);
    if (noise > 0.48 && noise < 0.5) {
        float x = GetBias((noise - 0.48) / 0.02, 0.3);
        surfaceColor = mix(dirtCol, beachCol, x);
    } else if (noise > 0.4 && noise < 0.48) {
        float x = GetGain((noise - 0.4) / 0.08, 0.4);
        surfaceColor = mix(landCol * forestNoise, deepLandCol, x);
    }

    // Creates mountain level
    float mountainNoise = fbm(10.0 * noiseInput + 20.0);
    if (noise > 0.37 && noise < 0.4) {
        float x = GetGain((noise - 0.37) / 0.03, mountainNoise);
        surfaceColor = mix(deepMountainCol, landCol * forestNoise, x);
    } else if (noise > 0.32 && noise < 0.37) {
        float x = GetGain((noise - 0.32) / 0.05, mountainNoise);
        float shininess = 3.0;
        float specVal = clamp((pow(dot(h, norm_deformed.xyz), shininess)), 0.0, 1.0);
        spec = mix(specVal, 0.0, x);
        surfaceColor = mix(mountainCol, deepMountainCol, x);
    } else if (noise < 0.4) {
        float shininess = 3.0;
        spec = clamp((pow(dot(h, norm_deformed.xyz), shininess)), 0.0, 1.0);
        float x = GetGain(noise / 0.32, mountainNoise);
        surfaceColor = mix(white, mountainCol, x);
    }

    float ambientTerm = 0.3;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.

                                                    
    // Compute final shaded color
    out_Col = vec4(surfaceColor.rgb * lightIntensity + spec, diffuseColor.a);
    //out_Col = vec4(surfaceColor.rgb, diffuseColor.a);
}
