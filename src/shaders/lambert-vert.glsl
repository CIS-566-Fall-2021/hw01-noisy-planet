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
uniform int u_AnimOn;     // whether to animate verts
uniform vec3 u_LightPos;

vec3 biomeSeed2 = vec3(1.0, 0.0, 0.0);
vec3 biomeSeed3 = vec3(0.0, 1.0, 0.0);
vec3 biomeSeed4 = vec3(-1.0, 0.0, 0.0);

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;
out vec4 sphere_Nor;

/* --------------------------- Random funcs --------------------------------- */

vec3 random3( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1, 311.7, 191.999)),
                          dot(p,vec3(269.5, 183.3, 765.54)),
                          dot(p, vec3(420.69, 631.2,109.21))))
                 *43758.5453);
}

/* --------------------------- Ease funcs ----------------------------------- */

float easeOutQuad(float x){
    return 1.0 - (1.0 - x) * (1.0 - x);
}

/* --------------------------- Noise funcs ---------------------------------- */

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

/* --------------------------- Create biomes -------------------------------- */

float createBiomes(vec3 pos, vec3 nor){
    float perlinScale = 1.8;
    float t = perlinNoise3D(perlinScale*pos.xyz) + 0.5*perlinNoise3D(perlinScale*2.0 * pos.xyz);

    float hill_t = 0.28*t;
    float mountain_t = 0.25*mountainWorley(8.0*pos);
    mountain_t = mix(0.0, mountain_t, t / (0.37 - 0.04));
    float mount_hill_t = mix(hill_t, mountain_t, sin((t * 3.14159) / 2.0));

    float biome_t = (nor.z + 1.0) / 2.0;
    float res = mix(hill_t, mountain_t, biome_t*biome_t);
    float x = clamp(t + 0.18, 0.0, 6.0);
    float height = mix(0.0, res, easeOutQuad(x));
    if (height < 0.0001){
        float heightOcean = 0.0;
        /*if (height + 0.001 < 0.0001){
            return 0.007*mountainWorley(50.0*pos);
        }*/
        return heightOcean;
    }
    return height;
}

vec4 shiftNormal(vec3 p, vec3 glob_nor){
    // find tangent and bitangent
    vec3 tangent = cross(vec3(0.0, 1.0, 0.0), glob_nor);
    vec3 bit = cross(glob_nor, tangent);

    vec3 deformed_p = p + glob_nor * createBiomes(p, glob_nor);

    // offset p along tangent and bitangent
    vec3 tangent_offset = p + 0.1*tangent;
    vec3 bit_offset = p + 0.1 * bit;
    vec3 neighbor1 = tangent_offset + glob_nor * createBiomes(tangent_offset, glob_nor);
    vec3 neighbor2 = bit_offset + glob_nor * createBiomes(bit_offset, glob_nor);

    vec3 newNor = cross(normalize(deformed_p - neighbor1), normalize(deformed_p - neighbor2));
    return vec4(newNor, 0.0);
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


    float time = abs(sin(u_Time * 0.01));
    sphere_Nor = vs_Nor;
    vec4 newPos = vs_Pos;

    newPos = vs_Pos + vs_Nor * createBiomes(vs_Pos.xyz, vs_Nor.xyz);
    fs_Nor = shiftNormal(vs_Pos.xyz, vs_Nor.xyz);

    vec4 modelposition = u_Model * newPos;   // Temporarily store the transformed vertex positions for use below
    fs_Pos = modelposition;

    fs_LightVec = vec4(u_LightPos, 1.0) - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
