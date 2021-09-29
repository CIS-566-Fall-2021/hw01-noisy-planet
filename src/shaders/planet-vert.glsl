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

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

uniform float u_Time;
uniform float u_Speed;
uniform float u_Warming;


out vec4 fs_Pos;
out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

vec3 random3( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1,311.7,457.3)),dot(p,vec3(269.5,183.3,271.5)), dot(p, vec3(119.3, 257.1, 361.7))))*43758.5453);
}

float WorleyNoise(vec3 uv)
{
    // Tile the space
    vec3 uvInt = floor(uv);
    vec3 uvFract = fract(uv);

    float minDist = 1.0; // Minimum distance initialized to max.

    // Search all neighboring cells and this cell for their point
    for(int z=-1; z <=1; z++) {
    for(int y = -1; y <= 1; y++)
    {
        for(int x = -1; x <= 1; x++)
        {
            vec3 neighbor = vec3(float(x), float(y),float(z));

            // Random point inside current neighboring cell
            vec3 point = random3(uvInt + neighbor);

            // Animate the point
            //point = 0.5 + 0.5 * sin(iTime + 6.2831 * point); // 0 to 1 range

            // Compute the distance b/t the point and the fragment
            // Store the min dist thus far
            vec3 diff = neighbor + point - uvFract;
            float dist = length(diff);
            minDist = min(minDist, dist);
        }
    }
    }
    return minDist;
}


vec3 fbm(vec3 uv) {
    float amp = 0.5;
    float freq = 1.0;
    vec3 sum = vec3(0.0);
    float maxSum = 0.0;
    for(int i = 0; i < 4; i++) {
        sum += WorleyNoise(uv * freq) * amp;
        maxSum += amp;
        amp *= 0.5;
        freq *= 2.0;
    }
    return sum / maxSum;
}


// from https://www.iquilezles.org/www/articles/functions/functions.htm
float expImpulse( float x, float k )
{
    float h = k*x;
    return h*exp(1.0-h);
}

float h(vec3 noiseinput) {
    noiseinput *= 1.75;

    // animate the noise
    noiseinput += .0025 * u_Time * u_Speed;
    vec3 offset = fbm(noiseinput);
    noiseinput = noiseinput + offset * 0.5;

    // Worley cells, invert for higher land masses
    float noiseScale = 1.0 - WorleyNoise(noiseinput);
    noiseScale += offset.r - 0.65f;
    
    // animate heights
    noiseScale *= expImpulse(sin(u_Time * .005 * u_Warming) + 1.0, 1.0);
    return noiseScale;

}

vec3 deform(vec3 p) {
    float noiseScale = h(p);
    // to make oceans not bumpy
    if (noiseScale < 0.5) {
        noiseScale = 0.5;
    }

    return (1.f + noiseScale) * p;
}

vec3 normalizeNZ(vec3 p) {
    float l = length(p);
    if (l < 0.01f) {
        return p;
    } else {
        return p / l;
    }
}

void main()
{
    fs_Pos = vs_Pos;
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);  


    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = normalize(lightPos - modelposition);  // Compute the direction in which the light source lies

    // START TINKERING -------------------------------------------------------------------------------------------

    // to align color and displacement, use same noise function for frag and vert shader 
    vec3 noiseinput = modelposition.xyz;
    vec3 dp = deform(noiseinput);

    vec3 noisymodelposition = dp;
    gl_Position = u_ViewProj * vec4(noisymodelposition, 1.0);

    
}
