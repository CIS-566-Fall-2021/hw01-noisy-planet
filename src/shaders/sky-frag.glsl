#version 300 es

uniform mat4 u_ViewProj;    // We're actually passing the inverse of the viewproj
// from our CPU, but it's named u_ViewProj so we don't
// have to bother rewriting our ShaderProgram class

// uniform ivec2 u_Dimensions; // Screen dimensions

ivec2 u_Dimensions = ivec3(800,1280);

uniform vec3 u_CameraPos; // Camera pos

uniform int u_Time;
in vec4 fs_Pos;
vec3 outColor;
out vec4 out_Col;

const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;

// Sunset palette: red/yellow color
vec3 sunset[5] = vec3[](vec3(255, 229, 119) / 255.0,
vec3(254, 192, 81) / 255.0,
vec3(255, 137, 103) / 255.0,
vec3(253, 96, 81) / 255.0,
vec3(57, 32, 51) / 255.0);

// Dusk palette: blue/purple color
const vec3 dusk[5] = vec3[](vec3(144, 96, 144) / 255.0,
vec3(96, 72, 120) / 255.0,
vec3(72, 48, 120) / 255.0,
vec3(48, 24, 96) / 255.0,
vec3(0, 24, 72) / 255.0);

//yellowish white
const vec3 sunColor = vec3(255, 255, 190) / 255.0;
vec3 cloudColor = sunset[3];

//get the uv value from a point representing the sphere
vec2 sphereToUV(vec3 p) {
    //using polr coordinate
    float phi = atan(p.z, p.x);
    //make negative phi positive
    if(phi < 0) {
        phi += TWO_PI;
    }
    float theta = acos(p.y);
    return vec2(1 - phi / TWO_PI, 1 - theta / PI);
}

//get the sunset color given the uv
//create a gradient effect by changing color with mix value correspond to uv.y
vec3 uvToSunset(vec2 uv) {
    if(uv.y < 0.5) {
        return sunset[0];
    }
    else if(uv.y < 0.55) {
        return mix(sunset[0], sunset[1], (uv.y - 0.5) / 0.05);
    }
    else if(uv.y < 0.6) {
        return mix(sunset[1], sunset[2], (uv.y - 0.55) / 0.05);
    }
    else if(uv.y < 0.65) {
        return mix(sunset[2], sunset[3], (uv.y - 0.6) / 0.05);
    }
    else if(uv.y < 0.75) {
        return mix(sunset[3], sunset[4], (uv.y - 0.65) / 0.1);
    }
    return sunset[4];
}

//get the dusk color given the uv
vec3 uvToDusk(vec2 uv) {
    if(uv.y < 0.5) {
        return dusk[0];
    }
    else if(uv.y < 0.55) {
        return mix(dusk[0], dusk[1], (uv.y - 0.5) / 0.05);
    }
    else if(uv.y < 0.6) {
        return mix(dusk[1], dusk[2], (uv.y - 0.55) / 0.05);
    }
    else if(uv.y < 0.65) {
        return mix(dusk[2], dusk[3], (uv.y - 0.6) / 0.05);
    }
    else if(uv.y < 0.75) {
        return mix(dusk[3], dusk[4], (uv.y - 0.65) / 0.1);
    }
    return dusk[4];
}


//output a random vec2 from a givin vec2
vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

//output a random vec3 from a givin vec3
vec3 random3( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1, 311.7, 191.999)),
                          dot(p,vec3(269.5, 183.3, 765.54)),
                          dot(p, vec3(420.69, 631.2,109.21))))
                 *43758.5453);
}

float WorleyNoise(vec2 uv)
{
    // Tile the space
    vec2 uvInt = floor(uv);
    vec2 uvFract = fract(uv);

    float minDist = 1.0; // Minimum distance initialized to max.

    // Search all neighboring cells and this cell for their point
    for(int y = -1; y <= 1; y++)
    {
        for(int x = -1; x <= 1; x++)
        {
            vec2 neighbor = vec2(float(x), float(y));

            // Random point inside current neighboring cell
            vec2 point = random2(uvInt + neighbor);

            // Animate the point
            //point = 0.5 + 0.5 * sin(u_Time * 0.01 + 6.2831 * point); // 0 to 1 range

            // Compute the distance b/t the point and the fragment
            // Store the min dist thus far
            vec2 diff = neighbor + point - uvFract;
            float dist = length(diff);
            minDist = min(minDist, dist);
        }
    }
    return minDist;
}

//#define RAY_AS_COLOR
//#define SPHERE_UV_AS_COLOR

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

void main()
{
    //convert fragment coordinate into normalize device coordinate,
    vec2 ndc = (gl_FragCoord.xy / vec2(u_Dimensions)) * 2.0 - 1.0; // -1 to 1 NDC

    //outColor = vec3(ndc * 0.5 + 0.5, 1);

    vec4 p = vec4(ndc.xy, 1, 1); // Pixel at the far clip plane
    p *= 1000.0; // Times far clip plane value
    p = /*Inverse of*/ u_ViewProj * p; // Convert from unhomogenized screen to world

    //ray direction: pixel at the far clip plane minus the eye direction
    vec3 rayDir = normalize(p.xyz - u_Eye);



#ifdef RAY_AS_COLOR
    outColor = 0.5 * (rayDir + vec3(1,1,1));
    return;
#endif
    //get the uv from ray direction
    vec2 uv = sphereToUV(rayDir);

    //testing uv, will output a gradient around the sphere
#ifdef SPHERE_UV_AS_COLOR
    outColor = vec3(uv, 0);
    return;
#endif


    vec2 offset = vec2(0.0);

    // Compute a gradient from the bottom of the sky-sphere to the top
    vec3 sunsetColor = uvToSunset(uv + offset * 0.1);
    vec3 duskColor = uvToDusk(uv + offset * 0.1);

    outColor = sunsetColor;
    //frequency of one day and night cycle
    float freq = 2000.0;
    // Add a glowing sun in the sky
    float wt = abs(sin(u_Time/(freq)));
    //sun directions
    vec3 sunDir;
    vec3 rise = normalize(vec3(0.5,0.1,0.1));
    vec3 noon = normalize(vec3(-0.1,0.12,0.1));
    vec3 fall = normalize(vec3(-0.6,0.1,-0.1));

    vec3 night = normalize(vec3(-0.1,-0.2,0.1));

    //    vec4 dir = normalize(vec4(0, 0, 1.0, 1.0));
    float sunSize = 30;
    //    mat4 rotationMatrix = rotationMatrix(vec3(0.f,0.f,1.f),wt);
    //    dir = dir * rotationMatrix;
    //    sunDir = vec3(dir);

    if(wt < 0.5){
        sunDir = normalize(vec3(0.9 - wt*2, 0.1+(wt*0.04), 0.1));
    } else {
        sunDir = normalize(vec3(0.9 - wt*2, 0.12-((wt-0.5)*0.04), 0.1 - (wt-0.5)*0.2));
    }
    //sunDir = night;

    //sunSize = 5;
    float angle = acos(dot(rayDir, sunDir)) * 360.0 / PI;
    // If the angle between our ray dir and vector to center of sun
    // is less than the threshold, then we're looking at the sun
    if(angle < sunSize) {
        // Full center of sun
        if(angle < 7.5) {
            outColor = sunColor;
        }
        // Corona of sun, mix with sky color
        else {
            outColor = mix(sunColor, sunsetColor, (angle - 7.5) / 22.5);
        }
    }
    // Otherwise our ray is looking into just the sky
    else {
        float raySunDot = dot(rayDir, sunDir);
#define SUNSET_THRESHOLD 0.75
#define DUSK_THRESHOLD -0.1
        if(raySunDot > SUNSET_THRESHOLD) {
            // Do nothing, sky is already correct color
        }
        // Any dot product between 0.75 and -0.1 is a LERP b/t sunset and dusk color
        else if(raySunDot > DUSK_THRESHOLD) {
            float t = (raySunDot - SUNSET_THRESHOLD) / (DUSK_THRESHOLD - SUNSET_THRESHOLD);
            outColor = mix(outColor, duskColor, t);
        }
        // Any dot product <= -0.1 are pure dusk color
        else {
            outColor = duskColor;
        }
    }
    //night color;
    float weight = abs(sin(u_Time/freq));
    vec3 nightColor = mix(duskColor, vec3(0,0,0),weight);

    float threshold = random2(uv).x;
    if(uv.y > 0.3 && threshold > 0.996) {
        //make the stars shiney
        float uvi = random2(uv).y;
        if(uvi > 0.25){
            nightColor = mix(vec3(uv,1),nightColor,sin(u_Time/10.0));
        } else if (uvi > 0.75){
            nightColor = mix(nightColor,vec3(uv,uv.x),sin(u_Time/10.0));
        }
    } else if(uv.y > 0.65 && threshold > 0.993) {
        nightColor = vec3(uv,1);
    } else if(uv.y > 0.8 && (threshold > 0.99)) {
        nightColor = vec3(uv,0.93);
    } else if (threshold > 0.97 && random2(uv).y > 0.97){
        nightColor = vec3(uv,0.95);
    }

    float dayTime = sin(u_Time/freq*2);
    weight = abs(sin(u_Time/freq*2));
    if(dayTime < 0 ){
        outColor = mix(outColor,duskColor,weight);
        outColor = mix(outColor,nightColor, weight);
    }
    out_Col = vec4(outColor,1);

}

