#version 300 es
// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;
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
float remap01(float v, float minOld, float maxOld) {
    return clamp((v-minOld) / (maxOld-minOld),0.0,1.0);
}
// ************************** 
// camera 

uniform float u_TextBool;
uniform vec4 u_CamPos;
uniform sampler2D u_Text;
uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;
uniform mat4 u_Model; 
// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;
in float fs_elevation;
out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float bias(float x,float bias){
    float k = pow(1.0-bias,3.0);
    return(x*k)/(x*k-x+1.0);
}
// ***************Raycast sphere *******
    // Returns dstToSphere, dstThroughSphere
    // If inside sphere, dstToSphere will be 0
    // If ray misses sphere, dstToSphere = max float value, dstThroughSphere = 0
    // Given rayDir must be normalized
    vec2 raySphere(vec3 centre, float radius, vec3 rayOrigin, vec3 rayDir) {
        vec3 offset = rayOrigin - centre;
        const float a = 1.0; // set to dot(rayDir, rayDir) instead if rayDir may not be normalized
        float b = 2.0 * dot(offset, rayDir);
        float c = dot (offset, offset) - radius * radius;

        float discriminant = b*b-4.0*a*c;
        // No intersections: discriminant < 0
        // 1 intersection: discriminant == 0
        // 2 intersections: discriminant > 0
        if (discriminant > 0.0) {
            float s = sqrt(discriminant);
            float dstToSphereNear = max(0.0, (-b - s) / (2.0 * a));
            float dstToSphereFar = (-b + s) / (2.0 * a);

            if (dstToSphereFar >= 0.0) {
                return vec2(dstToSphereNear, dstToSphereFar - dstToSphereNear);
            }
        }
        // Ray did not intersect sphere
        return vec2(-1.0, 0.0);
    }

    float ocean_cal(vec3 p){
        mat3 invModel = mat3(inverse(u_Model));
        vec3 view = fs_Pos.xyz-u_CamPos.xyz;
        view = normalize(view);
        vec2 r = raySphere(vec3(0.0),1.0,vec3(u_CamPos),normalize(view));
        float l = length(fs_Pos.xyz-u_CamPos.xyz);
        if(r.x >0.0){
            if(l>r.x){
                return (l-r.x)*2.0;
            }
        }
        else{
            return -1.0;
        }
        
    }

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

void main()
{
        vec4 mountain_color = vec4(0.2549, 0.251, 0.251, 1.0);
        vec4 grass_color = vec4(0.1804, 0.1922, 0.1804, 1.0);
        vec3 a = vec3(0.5, 0.5, 0.5);		
        vec3 b = vec3(0.5, 0.5, 0.5);	
        vec3 c = vec3(1.0, 1.0, 0.5);	
        vec3 d = vec3(0.80, 0.90, 0.30);
        vec4 snow_color = vec4(palette(sin(u_Time*0.002),a,b,c,d),1.0);

        vec4 shore_color = vec4(0.3922, 0.3451, 0.2745, 1.0);
        vec4 ocean_color = vec4(0.5451, 0.8549, 1.0, 1.0);
        a=vec3(0.5, 0.5, 0.5);b=vec3(0.5, 0.5, 0.5);c=vec3(2.0, 1.0, 0.0);d=vec3(0.50, 0.20, 0.25);
        vec3 SpecularColor = palette(sin(u_Time*0.001),a,b,c,d)*0.5;
        vec4 diffuseColor = grass_color*0.5;
        vec3 specularTerm = vec3(0.0);
        float shininess = 0.2;
    // ************* blend color ***************** //
    
        // calculate steepness
        vec3 localNormal = normalize(fs_Pos.xyz);
        float steepness = 1.0 - dot(localNormal, vec3(fs_Nor));
        steepness = remap01(steepness, 0.0, 0.05);

        // blend some ocean color based on ray-tracing result
        float steepThreshold=0.7;
        float elevationThreshold=0.3;

        // steep weight calculation & weight
        vec3 steepCol = vec3(mountain_color);
        float noise = snoise(vec3(fs_Pos))*0.05;
        // flat col 
        vec3 flatCol = vec3(grass_color);
        float flatStrength = 1.0 - bias(steepness,0.8)*0.5;

        vec3 compositeCol = mix(steepCol, flatCol, flatStrength);
        // shore
        if(fs_elevation<=(0.1+noise+sin(u_Time*0.01)*0.01)){
            float shoreStrength = 1.0 - bias(fs_elevation*10.0,0.3);
            compositeCol = mix(compositeCol,vec3(shore_color),shoreStrength);
        }
        
        // threshold
        if(fs_elevation>=(0.18+noise*sin(u_Time)*0.01)){
            float le = 0.18+noise*sin(u_Time)*0.01;
            float snowStrength =  bias((fs_elevation-le)/(0.3-le),0.2);
            snowStrength = clamp(snowStrength,0.0,1.0);
            compositeCol = mix(compositeCol,vec3(snow_color),snowStrength);
            shininess += clamp(snowStrength,0.0,0.5);
        }

        diffuseColor += vec4(compositeCol,1.0);

        vec3 view = -normalize(fs_Pos.xyz - u_CamPos.xyz);
        vec3 light = normalize(fs_LightVec.xyz);
        vec3 halfVec = view.xyz + light.xyz;
        halfVec = normalize(halfVec);        
        float NoH = clamp(dot( fs_Nor.xyz, halfVec ), 0.0, 1.0);
        specularTerm = vec3(pow(clamp(NoH, 0.0, 1.0), pow(200.0, shininess))) * SpecularColor * shininess;
    
        if(u_TextBool==1.0){
            vec3 n = normalize(fs_Pos.xyz - vec3(0.0));
            float u = atan(n.x, n.z) / (2.0*3.14159) + 0.5;
            float v = n.y*0.5+0.5;
            vec4 t = texture(u_Text,vec2(u,v));
            if(length(t.xyz)<=0.2){
                float textStrength =  1.0 - bias(length(t.xyz)/1.8,0.5);
                diffuseColor = mix(diffuseColor,t,textStrength);
            }
        }
        float ocean_blend= ocean_cal(vec3(fs_Pos));
        if(ocean_blend>0.0){
          diffuseColor = vec4(ocean_blend * ocean_color.xyz + vec3(noise), ocean_color.w);
        }
        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

        float ambientTerm = 0.8;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.


        out_Col = vec4((diffuseColor.rgb+ specularTerm) * lightIntensity, diffuseColor.a);
}
