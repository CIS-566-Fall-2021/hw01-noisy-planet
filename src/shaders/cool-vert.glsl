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
uniform float u_Time;                           // but in HW3 you'll have to generate one yourself

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.
out vec4 old;
out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col; 
out vec4 fs_Pos;           // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_CamPos;
const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    fs_Pos = vs_Pos;
    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
    float t = u_Time * 0.004;                                                   // Transform the geometry's normals by the inverse transpose of the
    t = sin(t);
    //cubic interpolation
    t = t * t * (3.0 - 2.0 * t);                                                      // model matrix. This is necessary to ensure the normals remain
    
    
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below
    vec4 camera = vec4(0.f, 0.f, 0.f, 1.f);
    vec4 modelposition2 = vec4(.5, 0, 0, 0);
  //  modelposition2.xyz = modelposition.xyz + (sin(modelposition.xyz) * 1.05) + (sin(modelposition.xyz) * .25);
    modelposition2.yz = modelposition.yz + (cos(modelposition.yz) * .35);
    //modelposition2
    modelposition2.y = modelposition2.y + (sin(modelposition2.y) * .20);
    modelposition.xyz = mix(modelposition.xyz,  modelposition2.xyz, t);
    gl_Position = u_ViewProj * modelposition;
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    //gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
