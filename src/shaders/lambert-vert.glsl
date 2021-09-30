#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform float u_Time;
uniform vec2 u_MousePos;
uniform vec4 u_CameraPos;

uniform mat4 u_Model;       // The matrix that defines the transformation of the
// object we're rendering. In this assignment,
// this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
// This allows us to transform the object's normals properly
// if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
// We've written a static matrix for you to use for HW2,
// but in HW3 you'll have to generate one yourself

uniform mat4 u_ViewProjInv;    // The matrix that defines the camera's transformation.
// We've written a static matrix for you to use for HW2,
// but in HW3 you'll have to generate one yourself

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_WorldPos;
out vec4 fs_Pos;

out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_LightPos;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.

out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

const vec4 lightPos = vec4(1, 2.0, 9.5, 1); //The position of our virtual light, which is used to compute the shading of
//the geometry in the fragment shader.

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    vec2 center_MousePos = 2.f * (u_MousePos - 0.5f);
    mat3 invTranspose = mat3(u_ModelInvTr);
    vec4 p = vec4(center_MousePos.xy, 1, 1) * abs(u_CameraPos.z);
    p = u_ViewProjInv * p;
    
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
    // Transform the geometry's normals by the inverse transpose of the
    // model matrix. This is necessary to ensure the normals remain
    // perpendicular to the surface after the surface is transformed by
    // the model matrix.
    
    
    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below
    
    float amp = 1.f - length(center_MousePos) + 1.f;
    amp =length(center_MousePos) + 1.f;
    vec2 dir = normalize(center_MousePos);
    vec3 camDir = normalize(u_CameraPos).xyz;
    vec3 perp_dir = cross(vec3(dir, 0), camDir);
    vec3 test = cross(vec3(0,0,1), vec3(0,1,0));
    float amt = dot(perp_dir.xy, modelposition.xy);
    vec2 center = center_MousePos;
    
    fs_Pos = modelposition;
    fs_LightPos = lightPos;
    modelposition.xy += amp * 0.3 * dir * sin(amt + u_Time * 0.1);
    fs_WorldPos = modelposition;
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
    
    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
    // used to render the final positions of the geometry's vertices
    
}
