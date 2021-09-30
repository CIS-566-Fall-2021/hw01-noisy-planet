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
precision highp float;
uniform highp int u_Time;
uniform highp int u_Height;
uniform highp int u_Shift;

uniform lowp int u_ShadingModel; //incorporate mode too

uniform vec3 u_CameraPos;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

out float fs_noise; // newly added - output noise value


const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

//toolbox functions
float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

// float cubicPulse(float c, float w, float x){
//     x = fabsf(x-c);
//     if(x>w) return 0.0f;
//     x/=w;
//     return 1.0f - x*x*(3.0f-2.0f*x);
// }

#define NUM_OCTAVES u_Shift

float fbm(vec3 x) {
    float time = float(u_Time);
	float v = 0.0;
	float a = 0.9; //0.5
	vec3 shift = vec3(100) + cos(time*0.001);
    int o = NUM_OCTAVES;
    if (u_ShadingModel == 6){
       o+=5;
    }
	for (int i = 0; i < o; ++i) {
		v += a * noise(x);
		x = x * 2.25 + shift; //2.0
		a *= 0.55; //0.5
	}
	return v;
}

//toolbox functions
float bias(float b, float t) {
    return pow(t,log(b)/log(0.5f));
}

float gain(float g, float t) {
    if (t < 0.5f) 
        return bias(1.0-g, 2.0*t) / 2.0;
     else 
        return 1.0 - bias(1.0-g, 2.0-2.0*t) / 2.0;
}


void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    vec4 pos = vs_Pos;  
    
    float time = float(u_Time);
    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.

    //new code                        
    float fbm_noise = fbm(pos.xyz);  
    float warp_noise = fbm(pos.xyz + fbm( pos.xyz + fbm( pos.xyz )));
    float threshold = 0.75;
    float mult = float(u_Height) * 0.1;

    if(u_ShadingModel == 4){
        threshold = 0.75 + gain(0.75, abs(sin(time*0.03))-0.05);
    } else if (u_ShadingModel == 5){
        // threshold = 0.9;
        mult *= 0.1;
    }
 
    if(warp_noise > threshold){
    pos += fs_Nor * warp_noise * mult;  
    } else {
    pos += fs_Nor * threshold * mult;      
    }

    fs_noise = warp_noise;   

    //plug into model position                                            
    vec4 modelposition = u_Model * pos;  // Temporarily store the transformed vertex positions for use below
    fs_LightVec = lightPos - modelposition ;  // Compute the direction in which the light source lies
    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is used to render the final positions of the geometry's vertices
    fs_Pos = pos;
}
