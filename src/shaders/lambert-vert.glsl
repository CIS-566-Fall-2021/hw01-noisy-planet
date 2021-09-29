#version 300 es
// ************************** 3D Simplex Noise*****************************
// Usage: float snoise(vec3 v) returning (-1,1)
// Description : Array and textureless GLSL 2D/3D/4D simplex 
//               noise functions.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20201014 (stegu)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
// 

    vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
    }

    vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
    }

    vec4 permute(vec4 x) {
        return mod289(((x*34.0)+10.0)*x);
    }

    vec4 taylorInvSqrt(vec4 r)
    {
    return 1.79284291400159 - 0.85373472095314 * r;
    }

    float snoise(vec3 v)
    { 
    const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
    const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

    // First corner
    vec3 i  = floor(v + dot(v, C.yyy) );
    vec3 x0 =   v - i + dot(i, C.xxx) ;

    // Other corners
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min( g.xyz, l.zxy );
    vec3 i2 = max( g.xyz, l.zxy );

    //   x0 = x0 - 0.0 + 0.0 * C.xxx;
    //   x1 = x0 - i1  + 1.0 * C.xxx;
    //   x2 = x0 - i2  + 2.0 * C.xxx;
    //   x3 = x0 - 1.0 + 3.0 * C.xxx;
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
    vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

    // Permutations
    i = mod289(i); 
    vec4 p = permute( permute( permute( 
                i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
            + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
            + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

    // Gradients: 7x7 points over a square, mapped onto an octahedron.
    // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
    float n_ = 0.142857142857; // 1.0/7.0
    vec3  ns = n_ * D.wyz - D.xzx;

    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

    vec4 x = x_ *ns.x + ns.yyyy;
    vec4 y = y_ *ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4( x.xy, y.xy );
    vec4 b1 = vec4( x.zw, y.zw );

    //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
    //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
    vec4 s0 = floor(b0)*2.0 + 1.0;
    vec4 s1 = floor(b1)*2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
    vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

    vec3 p0 = vec3(a0.xy,h.x);
    vec3 p1 = vec3(a0.zw,h.y);
    vec3 p2 = vec3(a1.xy,h.z);
    vec3 p3 = vec3(a1.zw,h.w);

    //Normalise gradients
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    vec4 m = max(0.5 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    return 105.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                    dot(p2,x2), dot(p3,x3) ) );
    }

// ******************************** noise end **********************************

// ******************************** Math **********************************
    // Smooth minimum of two values, controlled by smoothing factor k
    // When k = 0, this behaves identically to min(a, b)
    float smoothMin(float a, float b, float k) {
        k = max(0.0, k);
        // https://www.iquilezles.org/www/articles/smin/smin.htm
        float h = max(0.0, min(1.0, (b - a + k) / (2.0 * k)));
        return a * h + b * (1.0 - h) - k * h * (1.0 - h);
    }

    // Smooth maximum of two values, controlled by smoothing factor k
    // When k = 0, this behaves identically to max(a, b)
    float smoothMax(float a, float b, float k) {
        k = min(0.0, -k);
        float h = max(0.0, min(1.0, (b - a + k) / (2.0 * k)));
        return a * h + b * (1.0 - h) - k * h * (1.0 - h);
    }

    float Blend(float startHeight, float blendDst, float height) {
        return smoothstep(startHeight - blendDst / 2.0, startHeight + blendDst / 2.0, height);
    }
// ******************************** Math **********************************

// *************** Uniform & input output
    /** [0] octaves [1] persistance [2] lacunarity 
        [3] scale [4] multiplier [5] vertical shift [6] amplitude **/
    uniform float noise_params_continent[7]; 
    uniform float noise_params_ridge[9]; 
    uniform float noise_params_mask[7]; 


    // ocean
    uniform float oceanDepthMultiplier;
    uniform float oceanFloorDepth;
    uniform float oceanFloorSmoothing;
    uniform float mountainBlend;

    // crater deformation stuff
    #define MAX_CRATERS 10
    uniform int crater_amount;
    uniform vec3 crater[MAX_CRATERS]; // crater value


    // custom uniform value
    uniform float u_Time;       // Current time
    uniform vec4 u_Light_pos;

    // shader stuff
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

    out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
    out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
    out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
    out vec4 fs_Pos;
    out float fs_elevation;
    const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                            //the geometry in the fragment shader.



/****************** terrain stuff *************/
    /** rigid noise_params[9] 
        [0] octaves [1] persistance [2] lacunarity 
        [3] scale [4] multiplier [5] power [6] gain [8] vertical shift [9] amplitude **/
    float ridgidNoise(vec3 pos, float noise_params[9]) {
        // Extract parameters for readability
        
        vec3 offset = vec3(cos(u_Time*0.001));
        float octaves = noise_params[0];
        float persistence = noise_params[1];
        float lacunarity = noise_params[2];
        float scale = noise_params[3];
        float multiplier = noise_params[4];
        float power = noise_params[5];
        float gain = noise_params[6];
        float verticalShift = noise_params[7];
        float amplitude = noise_params[8];

        // Sum up noise layers
        float noiseSum = 0.0;
        float frequency = scale;
        float ridgeWeight = 1.0;

        for (float i = 0.0; i < octaves; i ++) {
            float noiseVal = 1.0 - abs(snoise(pos * frequency + offset));
            noiseVal = pow(abs(noiseVal), power);
            noiseVal *= ridgeWeight;
            ridgeWeight = clamp(noiseVal * gain,0.0,1.0);
            noiseSum += noiseVal * amplitude;
            amplitude *= persistence;
            frequency *= lacunarity;
        }
        return noiseSum * multiplier + verticalShift;
    }

    /** rigid noise_params[9] 
        [0] octaves [1] persistance [2] lacunarity 
        [3] scale [4] multiplier [5] power [6] gain [8] vertical shift [9] amplitude **/
    float smoothedRidgidNoise(vec3 pos, float noise_params[9]) {
        vec3 sphereNormal = normalize(pos);
        vec3 axisA = cross(sphereNormal, vec3(0.0,1.0,0.0));
        vec3 axisB = cross(sphereNormal, axisA);

        float offsetDst = 8.0*0.05;
        float sample0 = ridgidNoise(pos, noise_params);
        float sample1 = ridgidNoise(pos - axisA * offsetDst, noise_params);
        float sample2 = ridgidNoise(pos + axisA * offsetDst, noise_params);
        float sample3 = ridgidNoise(pos - axisB * offsetDst, noise_params);
        float sample4 = ridgidNoise(pos + axisB * offsetDst, noise_params);
        return (sample0 + sample1 + sample2 + sample3 + sample4) / 5.0;
    }

    /** fbm use noise_params[7] 
        [0] octaves [1] persistance [2] lacunarity 
        [3] scale [4] multiplier [5] vertical shift [6] amplitude **/
    float simplexNoise_FBM(vec3 p, float noise_params[7]){

        //vec3 offset = vec3(sin(u_Time*0.001));
        vec3 offset = vec3(sin(u_Time*0.001));
        float octaves = floor(noise_params[0]);
        float persistence = noise_params[1];
        float lacunarity = noise_params[2];
        float scale = noise_params[3];
        float multiplier = noise_params[4];
        float verticalShift = noise_params[5];
        float amplitude = noise_params[6];

        float noise = 0.0;
        float frequency = scale;
        for (float i = 0.0; i < octaves; i ++) {
            noise += snoise(p * frequency + offset) * amplitude;
            amplitude *= persistence;
            frequency *= lacunarity;
        }
        return noise*multiplier + verticalShift;
    }

    float terrain_generate(vec3 p){

        float continent_noise = simplexNoise_FBM(p,noise_params_continent);
        continent_noise = smoothMax(continent_noise,-oceanFloorDepth,oceanFloorSmoothing);
        if(continent_noise < 0.0){ // ocean type
            continent_noise *= oceanDepthMultiplier;
        }
        float mask = Blend(0.0,mountainBlend,simplexNoise_FBM(p,noise_params_mask));
        float ridgeNoise = smoothedRidgidNoise(p,noise_params_ridge);
        return continent_noise * 0.01 + ridgeNoise  * 0.01 * mask;
    }
/****************** terrain stuff end*************/
/****************** re-cal normal*************/
    vec3 to_polar(vec4 p) {
    return vec3(sqrt(p.x * p.x + p.y * p.y + p.z * p.z), 
    atan(p.y / p.x), 
    acos(p.z / sqrt(p.x * p.x + p.y * p.y + p.z * p.z)));
    }

    vec4 toWorld(vec4 nor) {
    vec3 normal = normalize(vec3(vs_Nor));
    vec3 tangent = normalize(cross(vec3(0.0, 1.0, 0.0), normal));
    vec3 bitangent = normalize(cross(normal, tangent));
    mat4 transform;
    transform[0] = vec4(tangent, 0.0);
    transform[1] = vec4(bitangent, 0.0);
    transform[2] = vec4(normal, 0.0);
    transform[3] = vec4(0.0, 0.0, 0.0, 1.0);
    return vec4(normalize(vec3(transform * nor)), 0.0); 
    } 

    vec4 to_cart(float r, float theta, float phi) {
    return vec4(r * sin(phi) * cos(theta), 
                r * sin(phi) * sin(theta),
                r * cos(phi), 1.);
    }

    vec4 cal_normal(vec4 p) {
    vec3 pp = to_polar(p);
    float alpha = .0001;
    float n1 = terrain_generate(vec3(to_cart(pp.x, pp.y + alpha, pp.z)));
    float n2 = terrain_generate(vec3(to_cart(pp.x, pp.y - alpha, pp.z)));
    float n3 = terrain_generate(vec3(to_cart(pp.x, pp.y, pp.z + alpha)));
    float n4 = terrain_generate(vec3(to_cart(pp.x, pp.y, pp.z + alpha)));
    float multiplier = 800.0;
    float xDiff = multiplier * (n1 - n2) ;
    float yDiff = multiplier * (n3 - n4) ;
    p.z = sqrt(1. - xDiff * xDiff - yDiff * yDiff);
    
    return toWorld(normalize(vec4(vec3(xDiff, yDiff, p.z), 0.0)));
    }




// calculate crater influence 
float crater_height(vec3 p){

    float height = 0.0;
    for(int i = 0;i < crater_amount;i++){
        
    }
    return height;
}


void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0.0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    // offset the vertices to form biomes
    vec3 noise_input = vec3(vs_Pos);
    vec4 pos = vs_Pos;
    // generate terrain
    float noise = terrain_generate(noise_input);
    fs_elevation = noise;
    pos = pos + noise * fs_Nor;

           
    vec4 modelposition = u_Model * pos;   // Temporarily store the transformed vertex positions for use below

    
    fs_LightVec = u_Light_pos - modelposition;  // Compute the direction in which the light source lies
    fs_Pos = modelposition;
    

    // calculate normal
    fs_Nor = cal_normal(vs_Pos);
    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
