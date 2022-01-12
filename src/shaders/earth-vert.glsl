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

uniform highp int u_Time;
uniform highp float u_NoiseInput;
uniform highp float u_AnimationSpeed;
uniform highp float u_RotationAngleX;
uniform highp float u_RotationAngleY;
uniform highp float u_RotationAngleZ;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

// NOISE FUNCTIONS //
vec3 noise3D(vec3 p) {
    float val1 = fract(sin((dot(p, vec3(127.1, 311.7, 191.999)))) * 43758.5453);

    float val2 = fract(sin((dot(p, vec3(191.999, 127.1, 311.7)))) * 3758.5453);

    float val3 = fract(sin((dot(p, vec3(311.7, 191.999, 127.1)))) * 758.5453);

    return vec3(val1, val2, val3);
}

vec3 interpNoise3D(float x, float y, float z) {
    int intX = int(floor(x));
    float fractX = fract(x);
    int intY = int(floor(y));
    float fractY = fract(y);
    int intZ = int(floor(z));
    float fractZ = fract(z);

    vec3 v1 = noise3D(vec3(intX, intY, intZ));
    vec3 v2 = noise3D(vec3(intX + 1, intY, intZ));
    vec3 v3 = noise3D(vec3(intX, intY + 1, intZ));
    vec3 v4 = noise3D(vec3(intX + 1, intY + 1, intZ));

    vec3 v5 = noise3D(vec3(intX, intY, intZ + 1));
    vec3 v6 = noise3D(vec3(intX + 1, intY, intZ + 1));
    vec3 v7 = noise3D(vec3(intX, intY + 1, intZ + 1));
    vec3 v8 = noise3D(vec3(intX + 1, intY + 1, intZ + 1));

    vec3 i1 = mix(v1, v2, fractX);
    vec3 i2 = mix(v3, v4, fractX);

    vec3 i3 = mix(i1, i2, fractY);

    vec3 i4 = mix(v5, v6, fractX);
    vec3 i5 = mix(v7, v8, fractX);

    vec3 i6 = mix(i4, i5, fractY);

    vec3 i7 = mix(i3, i6, fractZ);

    return i7;
}

vec3 fbm(float x, float y, float z) {
    vec3 total = vec3(0.f, 0.f, 0.f);

    float persistence = 0.5f;
    int octaves = 6;

    for(int i = 1; i <= octaves; i++)
    {
        float freq = pow(2.f, float(i));
        float amp = pow(persistence, float(i));

        total += interpNoise3D(x * freq, y * freq, z * freq) * amp;
    }

    return total;
}

vec3 random3( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1, 311.7, 147.6)),
                          dot(p,vec3(269.5, 183.3, 221.7)),
                          dot(p, vec3(420.6, 631.2, 344.2))
                    )) * 43758.5453);
}

float surflet(vec3 p, vec3 gridPoint) {
    // Compute the distance between p and the grid point along each axis, and warp it with a
    // quintic function so we can smooth our cells
    vec3 t2 = abs(p - gridPoint);
    vec3 t = vec3(1.f) - 6.f * pow(t2, vec3(5.f)) + 15.f * pow(t2, vec3(4.f)) - 10.f * pow(t2, vec3(3.f));
    // Get the random vector for the grid point (assume we wrote a function random2
    // that returns a vec2 in the range [0, 1])
    vec3 gradient = random3(gridPoint) * 2. - vec3(1., 1., 1.);
    // Get the vector from the grid point to P
    vec3 diff = p - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * t.x * t.y * t.z;
}

float perlin(vec3 p) {
	float surfletSum = 0.f;
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

// WORLEY NOISE
// https://www.shadertoy.com/view/fscSzr
float rand3dTo1d(vec3 value, vec3 dotDir){
    vec3 smallValue = sin(value);
    float random = dot(smallValue, dotDir);
    random = fract(sin(random) * 143758.5453);
    return random;
}

vec3 rand3dTo3d(vec3 value){
    return vec3(
        rand3dTo1d(value, vec3(12.989, 78.233, 37.719)),
        rand3dTo1d(value, vec3(39.346, 11.135, 83.155)),
        rand3dTo1d(value, vec3(73.156, 52.235, 09.151))
    );
}

float worley(vec3 pos, vec3 scale, vec3 offset){
    //APPLY SCALE
    pos *= scale;
    
    //APPLY OFFSET
    pos += offset;

    //TILE THE SPACE INTO CELLS
    vec3 floor_pos = floor(pos);
    vec3 fract_pos = fract(pos);

    //INITIAL DISTANCE
    float m_dist = 1.0;

    //LOOP THROUGH ALL THE NEIGHBOUR CELLS
    for (int z = -1; z <= 1; z++) {
        for (int y= -1; y <= 1; y++) {
            for (int x= -1; x <= 1; x++) {
                //GET THE NEIGHBOUR CELL IN THE GRID
                vec3 neighbor = vec3(x, y, z);

                //GET THE POSITION OF THE CURRENT CELL AND THE NEIGHBOUR
                vec3 point = rand3dTo3d(floor_pos + neighbor);

                //GET THE VECTOR BETWEEN THE CELLS
                vec3 diff = neighbor + point - fract_pos;

                //CALCULATE THE DISTANCE BETWEEN THE NEIGHBOUR AND THE CURRENT POINT
                float dist = length(diff);

                //KEEP THE CLOSER DISTANCE
                m_dist = min(m_dist, dist);
            }
        }
    }
    //RETURN THE MINIMUM DISTANCE
    return 1.0 - m_dist;
}
// NOISE FUNCITONS END //

// ROTATION FUNCTIONS //
float degreesToRadians(float deg) {
    return deg * 3.14159265359f / 180.f;
}

mat4 rotateX(float angle) {
	return mat4(1, 0, 0, 0,
			 	0, cos(angle), -sin(angle), 0,
				0, sin(angle), cos(angle), 0,
				0, 0, 0, 1);
}

mat4 rotateY(float angle) {
	return mat4(cos(angle),	0, sin(angle), 0,
			 	0, 1, 0, 0,
				-sin(angle), 0, cos(angle), 0,
				0, 0, 0, 1);
}

mat4 rotateZ(float angle) {
	return mat4(cos(angle),	-sin(angle), 0, 0,
			 	sin(angle), cos(angle), 0, 0,
				0, 0, 1, 0,
				0, 0, 0, 1);
}
// ROTATION FUNCTIONS END //

// TOOLBOX FUNCTIONS //
float bias(float time, float bias) {
    return (time / ((((1.0 / bias) - 2.0) * (1.0 - time)) + 1.0));
}

float gain(float time, float gain) {
    if (time < 0.5) {
        return bias(time * 2.0, gain) / 2.0;
    } else {
        return bias(time * 2.0 - 1.0, 1.0 - gain) / 2.0 + 0.5;
    }
}

float impulse(float k, float x) {
    float h = k * x;
    return h * exp(1.f - h);
}
// TOOLBOX FUNCTIONS END //

// CONDITIONAL FUNCTIONS //
float when_lt(float x, float y) {
  return max(sign(y - x), 0.0);
}

float when_ge(float x, float y) {
  return 1.0 - when_lt(x, y);
}
// CONDITIONAL FNCTIONS END //

// Takes a point and transforms its position using noise functions
vec3 noisePosition(vec3 p) {
  // User modifies noise input
  vec3 noiseInput = p.xyz;
  noiseInput *= 1.0f * u_NoiseInput;

  // Animation!
  noiseInput += float(u_Time) * 0.0005 * u_AnimationSpeed;

  // Noise values
  vec3 noise = fbm(noiseInput.x, noiseInput.y, noiseInput.z);
  float perlinNoise = 0.5f * abs(perlin(noiseInput * vec3(10.f)));
  float worleyNoise = 0.1f * worley(noiseInput, vec3(4.f), vec3(0.f));

  float t = noise.r;
  float noiseScale = (t + perlinNoise) * when_ge(t, 0.65f) +
                     t * when_ge(t, 0.58f) * when_lt(t, 0.65f) +
                     (t + worleyNoise) * when_ge(t, 0.55f) * when_lt(t, 0.58f) +
                     t * when_ge(t, 0.5f) * when_lt(t, 0.55f) + 
                     0.46f * when_lt(t, 0.5f);
  vec3 offsetAmount = vec3(vs_Nor) * noiseScale;
  vec3 noisyModelPosition = p.xyz + offsetAmount;
  return noisyModelPosition;
}

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    fs_Pos = vs_Pos;

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
    // Rotate light along x, y, and z axes based on user input
    fs_LightVec = rotateX(degreesToRadians(u_RotationAngleX)) * 
                  rotateY(degreesToRadians(u_RotationAngleY)) * 
                  rotateZ(degreesToRadians(u_RotationAngleZ)) * fs_LightVec;

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices


    vec3 noisyModelPosition = noisePosition(modelposition.xyz);
    gl_Position = u_ViewProj * vec4(noisyModelPosition, 1.0);

    // NORMAL CALCULATIONS //
    // Get tangent and bitangent
    vec3 tangent = cross(vec3(0.f, 1.f, 0.f), vs_Nor.xyz);
    vec3 bitangent = cross(vs_Nor.xyz, tangent);

    // Get four points around our point along the tangent and bitangent
    float epsilon = 0.00001f;
    vec3 p1 = modelposition.xyz + vec3(epsilon) * tangent;
    vec3 p2 = modelposition.xyz - vec3(epsilon) * tangent;
    vec3 p3 = modelposition.xyz + vec3(epsilon) * bitangent;
    vec3 p4 = modelposition.xyz - vec3(epsilon) * bitangent;

    // Get the new positions of the points
    vec3 p5 = noisePosition(p1);
    vec3 p6 = noisePosition(p2);
    vec3 p7 = noisePosition(p3);
    vec3 p8 = noisePosition(p4);

    // Calculate the new normal and set fs_Nor
    vec3 newNorm = cross(normalize(p5 - p6), normalize(p7 - p8));
    fs_Nor = vec4(invTranspose * newNorm, 0);
    // NORMAL CALCULATIONS END //
}
