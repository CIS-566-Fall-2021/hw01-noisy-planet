#version 300 es

// Written by Nathan Devlin, based on reference by Adam Mally

// 3D Fractal Brownian Motion Fragment Shader

precision highp float;

uniform vec4 u_Color; // User input color

// Interpolated values out of the rasterizer
in vec4 fs_Pos;

in vec4 fs_UnalteredPos;

in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

out vec4 out_Col; 


vec3 returnLatitudeAsColor(vec3 p)
{
    float red = 0.0f;
    red += abs(p.y) * 1.0f - 0.2f;

    float green = 1.0;

    float blue = 1.0f;

    return vec3(red, green, blue);
}


// Takes in a position vec3, returns a vec3, to be used below as a color
vec3 noise3D( vec3 p ) 
{
    float val1 = fract(sin((dot(p, vec3(127.1, 311.7, 191.999)))) * 4.5453);

    float val2 = fract(sin((dot(p, vec3(191.999, 127.1, 311.7)))) * 3.5453);

    float val3 = fract(sin((dot(p, vec3(311.7, 191.999, 127.1)))) * 7.5453);

    return vec3(val1, val2, val3);
}


// Interpolate in 3 dimensions
vec3 interpNoise3D(float x, float y, float z) 
{
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


// 3D Fractal Brownian Motion
vec3 fbm(float x, float y, float z, int octaves) 
{
    vec3 total = vec3(0.f, 0.f, 0.f);

    float persistence = 0.5f;

    for(int i = 1; i <= octaves; i++) 
    {
        float freq = pow(3.f, float(i));
        float amp = pow(persistence, float(i));

        total += interpNoise3D(x * freq, y * freq, z * freq) * amp;
    }
    
    return total;
}


void main()
{
        // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));

        diffuseTerm = clamp(diffuseTerm, 0.0f, 1.0f);

        float ambientTerm = 0.05;

        float lightIntensity = diffuseTerm + ambientTerm;   

        vec3 latitudeCol = returnLatitudeAsColor(vec3(fs_Pos[0], fs_Pos[1], fs_Pos[2]));

        
        float surfaceDifference = (length(fs_Pos) - length(fs_UnalteredPos));



        if(surfaceDifference > 0.1f)
        {
            diffuseColor = vec4(0.0f, 1.0f, 0.0f, 1.0f);

            if(surfaceDifference < 0.11f)
            {
                diffuseColor = vec4(0.8941, 0.8, 0.2706, 1.0);
            }
            else if(surfaceDifference > 0.15f)
            {
                diffuseColor = vec4(1.0, 1.0, 1.0, 1.0);
            }
        }

        if(fs_Pos[1] > 0.85 || fs_Pos[1] < -0.85)
        {
            diffuseColor = vec4(latitudeCol, 1.0f);        
        }


        // Lambert shading
        out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);


        if(diffuseColor == vec4(0.0f, 1.0f, 0.0f, 1.0f) && lightIntensity <= 0.1f)
        {            
            vec3 val = fbm(fs_Pos[0], fs_Pos[1], fs_Pos[2], 8);

            float avg = (val[0] + val[1] + val[2]) / 2.0f;

            avg = avg * avg * avg * avg * avg * avg * avg * avg * avg * avg;

            //out_Col = vec4(avg, avg, avg, 1.0f);

            if(avg > 0.2f)
            {
                avg *= 2.0f;
                out_Col = vec4(avg, avg, 0.0f, 1.0f);
            }
        }


        //out_Col = vec4(vec3(surfaceDifference), 1.0f);


        /*
        vec3 latitudeCol = returnLatitudeAsColor(vec3(fs_Pos[0], fs_Pos[1], fs_Pos[2]));

        // Add fbm noise
        vec3 fbmVal = fbm(fs_Pos[0], fs_Pos[1], fs_Pos[2]);

        fbmVal = clamp(fbmVal, 0.0f, 1.0f);

        vec3 greenVal = vec3(0.0f, fbmVal[1], 0.0f);

        float r = latitudeCol.r;
        float g = latitudeCol.g;
        float b = latitudeCol.b;

        if(greenVal.g > 0.5f)
        {
            b = 0.0f;
            g = greenVal.g;
        }
        else
        {
            g = latitudeCol.g;
        }

        if(abs(fs_Pos[1]) >= 0.82f)
        {
            r = latitudeCol.r;
            g = latitudeCol.g;
            b = latitudeCol.b;
        }

        out_Col = vec4(r, g, b, 1.0);

        //out_Col = vec4(latitudeCol, 1.0f);

        */


}

