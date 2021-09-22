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

uniform int u_Time;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;
out float fs_Noise;
out vec4 modelposition;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

vec3 random3 ( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1, 311.7, 288.99)),
                          dot(p,vec3(303.1, 183.3, 800.2)),
                          dot(p, vec3(420.69, 655.0,109.21))))
                 *43758.5453);
}

float surflet(vec3  p, vec3 gridPoint) {
    vec3 t2 = abs(p - gridPoint);
    vec3 t;
    t.x = 1.f - 6.f * pow(t2.x, 5.f) + 15.f * pow(t2.x, 4.f) - 10.f * pow(t2.x, 3.f);
    t.y = 1.f - 6.f * pow(t2.y, 5.f) + 15.f * pow(t2.y, 4.f) - 10.f * pow(t2.y, 3.f);
    t.z = 1.f - 6.f * pow(t2.z, 5.f) + 15.f * pow(t2.z, 4.f) - 10.f * pow(t2.z, 3.f);

    vec3 gradient = random3(gridPoint) * 2. - vec3(1.);

    vec3 diff = p - gridPoint;
    float height = dot(diff, gradient);
    return height * t.x * t.y * t.z;
}


float summedPerlin(vec4 p)
{
    float sum = 0.0;
    for(int dx = 0; dx <= 1; ++dx) {
        for (int dy = 0; dy <= 1; ++dy) {
           for (int dz = 0; dz <= 1; ++dz) {
               sum += surflet(vec3(p), floor(vec3(p)) + vec3(dx, dy, dz));
           } 
        }
    }
    
    return sum;
}

float noise (vec3 n) 
{ 
	return fract(sin(dot(n, vec3(95.43583, 93.323197, 94.993431))) * 65536.32);
}

float perlin_a (vec3 n)
{
    vec3 x = floor(n * 64.0) * 0.015625;
    vec3 k = vec3(0.015625, 0.0, 0.0);
    float a = noise(x);
    float b = noise(x + k.xyy);
    float c = noise(x + k.yxy);
    float d = noise(x + k.xxy);
    vec3 p = (n - x) * 64.0;
    float u = mix(a, b, p.x);
    float v = mix(c, d, p.x);
    return mix(u,v,p.y);
}

float perlin_b (vec3 n)
{
    vec3 base = vec3(n.x, n.y, floor(n.z * 64.0) * 0.015625);
    vec3 dd = vec3(0.015625, 0.0, 0.0);
    vec3 p = (n - base) *  64.0;
    float front = perlin_a(base + dd.yyy);
    float back = perlin_a(base + dd.yyx);
    return mix(front, back, p.z);
}

float fbm(vec3 n)
{
    float t = 0.0;
    float a = 1.0;
    float b = 0.1;
    for (int i = 0; i < 5; i++)
    {
        t += perlin_b(n * a) * b;
        a *= 0.5;
        b *= 2.0;
    }
    return t;
}


void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
    vec3 normPos = normalize(vs_Pos.xyz);
    modelposition = u_Model * vec4(normPos, 1);
    vec4 modPos = vs_Pos;

    vec4 modelOriginal = u_Model * modPos;
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
    // fs_Pos = mix(modelposition, modelOriginal, sin(float(u_Time)  * 0.01));

    float hawaiianRanges = clamp(pow(summedPerlin(vs_Pos * 4.), 3.0), 0.0, 0.1);
    float volcano = clamp(pow(fbm(vs_Pos.xyz * 0.06), 1.0), 0.0, 0.1);
    // float m = glm::max(129.f, terrain->mountainY(x, z));
    // float i = glm::max(129.f, terrain->islandY(x, z));
    // float d = glm::max(129.f, terrain->desertY(x, z));
    // float b = bilinearInterp(g, i, m, d, 0.25f, 0.75f, 0.25f, 0.75f, s1, s2);

    float biomeMap = summedPerlin(modelposition);
    float interp = hawaiianRanges  + (1.0 - (biomeMap * 1.2)) * volcano;
    fs_Noise = interp;
    fs_Pos = vs_Pos + vs_Nor * interp ;
    // if (biomeMap > 0.1) {
    //     fs_Pos = vs_Pos + hawaiianRanges;
    // } else {
    //     fs_Pos = vs_Pos + volcano;
    // }

    gl_Position = u_ViewProj * fs_Pos;
}
