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

uniform highp float u_Time;

uniform vec4 center;

// Procedural Controls
uniform highp float terrainFreq;    // Sets the frequency of noise that outputs terrain elevations
uniform highp float forestScale;    // Sets the density of the forest

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

out vec3 p1;                // Neighbors a tiny epsilon away from our point which we will use to calculate the deformed normal
out vec3 p2;
out vec3 p3; 
out vec3 p4;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

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

// Perlin Noise ------------------------------
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

float hash1(float x)
{
	return fract(sin(x) * 43758.5453123);
}

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

// Forest noise function
float forestNoise(vec3 noiseInput) {
    float smallForestFreq = 30.0 * forestScale;
    float largeForestFreq = 25.0 * forestScale;
    float smallForestNoise = fbm(smallForestFreq * noiseInput + 20.0);
    float largeForestNoise = 1.0 - pnoise(largeForestFreq * noiseInput);
    float sizeNoise = fbm(noiseInput + 20.0);
    return mix(smallForestNoise, largeForestNoise, sizeNoise);
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
        elevation =  mix(mountElevation1, landElevation * ((forestNoise * 0.08) + landElevation), x);
    } else if (noise < 0.37) {
        float x = GetGain(noise / 0.37, mountainNoise);
        elevation =  mix(mountElevation2, mountElevation1, x);
    }

    return elevation;

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

    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices

    vec3 noiseInput = modelposition.xyz * terrainFreq;
    float noise = fbm(noiseInput);

    float elevation = getElevation(noiseInput);                  

    vec3 offsetAmount = vec3(vs_Nor) * elevation;
    vec3 noisyModelPosition = modelposition.xyz + offsetAmount;
    gl_Position = u_ViewProj * vec4(noisyModelPosition, 1.0);
    
    fs_Pos = vs_Pos;
    
    }