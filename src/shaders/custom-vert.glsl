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

uniform float u_Time;
uniform float u_heightScale;
uniform float u_timeScale;
uniform float u_sandHeight;
uniform float u_grassHeight;
uniform float u_stoneHeight;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 random(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

// Refer to a simple noise function online
float noise(vec3 pos){
    vec3 i = floor(pos);
    vec3 f = fract(pos);
    f = f * f * (3.0 - 2.0 * f);

    vec4 a = i.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = random(a.xyxy);
    vec4 k2 = random(k1.xyxy + a.zzww);
    vec4 b = k2 + i.zzzz;
    vec4 k3 = random(b);
    vec4 k4 = random(b + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));
    vec4 o3 = o2 * f.z + o1 * (1.0 - f.z);
    vec2 o4 = o3.yw * f.x + o3.xz * (1.0 - f.x);

    return o4.y * f.y + o4.x * (1.0 - f.y);
}

float fbm(vec3 pos) {
	float noiseOutput = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 6; i++) {
		noiseOutput += amplitude * noise(pos);
		pos = 2.0 * pos + vec3(100);
		amplitude *= 0.5;
	}
	return noiseOutput;
}

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

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    vec4 temp_vPos = vs_Pos;
    float temp_time = u_timeScale * u_Time;

    float noiseOutput = clamp((2.0 * fbm(temp_vPos.xyz) - 1.0), 0.0, 1.0) * u_heightScale;
    temp_vPos.xyz += vs_Nor.xyz * noiseOutput;

    // biomes height assign
    float oceanHeight_low = 0.1;
    float oceanHeight_high = 0.15;
    float oceanHeight = mix(oceanHeight_low, oceanHeight_high, sin(temp_time));

    vec4 oceanColor = vec4(0.0, 0.41, 0.58, clamp(bias(0.4, ((sin(temp_time)+1.0)/4.0)+0.5), 0.8, 1.0));
    vec4 sandColor = vec4(1.0, 0.93, 0.678, 1.0);
    vec4 grassColor = vec4(0.494, 0.784, 0.314, 1.0);
    vec4 stoneColor = vec4(0.533, 0.549, 0.553, 1.0);
    vec4 snowColor = vec4(1.0, 0.98, 0.98, 1.0);

    if (noiseOutput <= oceanHeight){
        float oceanToSand = smoothstep(0.0, oceanHeight, noiseOutput);
        fs_Col = mix(oceanColor, sandColor, oceanToSand);
    }
    else if (noiseOutput <= u_sandHeight){
        float sandToGrass = smoothstep(oceanHeight, u_sandHeight, noiseOutput);
        fs_Col = mix(sandColor, grassColor, sandToGrass);
    }
    else if (noiseOutput <= u_grassHeight){
        float grassToStone = smoothstep(u_sandHeight, u_grassHeight, noiseOutput);
        fs_Col = mix(grassColor, stoneColor, grassToStone);
    }
    else if (noiseOutput <= u_stoneHeight){
        float stoneToSnow = smoothstep(u_grassHeight, u_stoneHeight, noiseOutput);
        fs_Col = mix(stoneColor, snowColor, stoneToSnow);
    }
    else {
        fs_Col = snowColor;
    }

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.
    vec4 modelposition = u_Model * temp_vPos;
    fs_Pos = modelposition;

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
