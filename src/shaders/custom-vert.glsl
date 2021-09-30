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

out vec4 fs_Pos;
out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

vec2 rotatePoint2d(vec2 uv, vec2 center, float angle)
{
    vec2 rotatedPoint = vec2(uv.x - center.x, uv.y - center.y);
    float newX = cos(angle) * rotatedPoint.x - sin(angle) * rotatedPoint.y;
    rotatedPoint.y = sin(angle) * rotatedPoint.x + cos(angle) * rotatedPoint.y;
    rotatedPoint.x = newX;
    return rotatedPoint;
}

void main()
{
    fs_Pos = vs_Pos;
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    vec4 morph = sin(u_Time * 0.05) * vs_Pos - sin(u_Time * 0.05)
            * ((cos(u_Time * 0.075) * normalize(vs_Pos)
                + sin(u_Time * 0.075) * normalize(vs_Pos)));
    morph.w = 1.0;

    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    //mat4 rotX = mat4(cos(u_Time), -sin(u_Time), 0., 0.,
    //                sin(u_Time), cos(u_Time, 0., 0.,
    //                0., 0., 1., 0.
    //                0., 0., 0., 1.));
    float r = length(vs_Pos);
    vec2 rot = rotatePoint2d(vs_Pos.xy, vec2(0.f, 0.f), r * sin(r * cos(r + 10.0f) + u_Time) + u_Time);

    //modelposition.x = modelposition.x * (sin(u_Time * 0.05) + 2.0) * 0.5;
    //modelposition.y = modelposition.y * (cos(u_Time * 0.05) + 2.0) * 0.5;
    //modelposition.z = modelposition.z * (sin(u_Time * 0.05) + 2.0) * 0.5;
    //modelposition = modelposition * rotX;
    //modelposition = u_Model * morph;
    modelposition = vec4(rot, modelposition.z, modelposition.w);
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
    //modelposition = u_Model * vs_Pos * u_Time;
    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
