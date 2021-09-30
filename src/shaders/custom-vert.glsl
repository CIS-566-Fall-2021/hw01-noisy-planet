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

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

//noise basis function
float noiseFBM2D(vec2 n)
{
    return (fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453));
}

//interpNoise2D
float interpNoise2D(float x, float y)
{
    float intX = floor(x);
    float fractX = fract(x);
    float intY = floor(y);
    float fractY = fract(y);

    float v1 = noiseFBM2D(vec2(intX, intY));
    float v2 = noiseFBM2D(vec2(intX + 1.0, intY));
    float v3 = noiseFBM2D(vec2(intX, intY + 1.0));
    float v4 = noiseFBM2D(vec2(intX + 1.0, intY + 1.0));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    return mix(i1, i2, fractY);
}

//fbm function
float fbm(float x, float y)
{
    float total = 0.0;
    float persistence = 0.5;
    float octaves = 4.0;
    total = (total + sin((u_Time + 71.22913)) * 0.5);
    for(float i = 1.0; i <= octaves; i++) {
        float freq = pow(2.0, i);
        float amp = pow(persistence, i);

        total += interpNoise2D(x * freq, y * freq) * amp;
    }
    return total;
}

vec3 newPosGenerate(vec3 pos, vec3 nor) {
    vec3 newPos = vec3(0, 0, 0);
    if (nor.x > 0.2) {     //right case
        newPos = vec3((fbm(pos.z, pos.y) * 2.0), pos.y, pos.z);
    } else if (nor.x < -0.2) {     //left case
        newPos = vec3(-(fbm(pos.z, pos.y) * 2.0), pos.y, pos.z);
    } else if (nor.y > 0.2) {      //up case
        newPos = vec3(pos.x, (fbm(pos.x, pos.z) * 2.0), pos.z);
    } else if (nor.y < -0.2) {      //up case
        newPos = vec3(pos.x, -(fbm(pos.x, pos.z) * 2.0), pos.z);
    } else if (nor.z > 0.2) {      //front case
        newPos = vec3(pos.x, pos.y, (fbm(pos.x, pos.y) * 2.0));
    } else {      //back case
        newPos = vec3(pos.x, pos.y, -(fbm(pos.x, pos.y) * 2.0));
    }
    return newPos;
}

vec3 newPosGenerate1(vec3 pos, vec3 nor) {
    float val = 0.0;
    if (nor.x > 0.1) {     //right case
        val = fbm(pos.y, pos.z);
    } else if (nor.x < -0.1) {     //left case
        val = fbm(pos.y, pos.z);
    } else if (nor.y > 0.1) {      //up case
        val = fbm(pos.x, pos.z);
    } else if (nor.y < -0.1) {      //up case
        val = fbm(pos.x, pos.z);
    } else if (nor.z > 0.1) {      //front case
        val = fbm(pos.x, pos.y);
    } else if (nor.z < -0.1) {      //back case
        val = fbm(pos.x, pos.y);
    }
    return (normalize(pos) * val * 0.8);
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

    vec4 modelposition = u_Model * 
        mix(
            (vs_Pos + (sin(vs_Pos * 10.0 + u_Time * 10.0) * 0.1 + cos(vs_Pos * 10.0 + u_Time * 10.0)) * 0.3),
            vec4(normalize(vec3(vs_Pos)), 1),
            0.2 +  0.15 * sin(u_Time * 0.2)
        );

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
    fs_Pos = modelposition;                         // Pass the vertex positions to the fragment shader

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
